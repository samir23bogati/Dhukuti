import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhukuti/models/portfolio_model.dart';
import 'package:dhukuti/models/transaction_model.dart';
import 'package:dhukuti/services/price_service.dart';
import 'package:flutter/foundation.dart';

enum MarketStatus { open, closed, holiday }

class MarketProvider extends ChangeNotifier {
  final PriceService _priceService = PriceService();
  
  double? _currentPrice;
  double? get currentPrice => _currentPrice;
  bool _isLoadingPrice = false;
  bool get isLoadingPrice => _isLoadingPrice;

  bool _isLoadingPortfolio = false;
  bool get isLoadingPortfolio => _isLoadingPortfolio;

  PortfolioModel? _portfolio;
  PortfolioModel? get portfolio => _portfolio;

  Map<String, dynamic>? _marketSettings;
  StreamSubscription<DocumentSnapshot>? _settingsSubscription;

  MarketProvider() {
    fetchPrice();
    _initMarketSettingsListener();
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }

  void _initMarketSettingsListener() {
    _settingsSubscription = FirebaseFirestore.instance
        .collection('market_settings')
        .doc('config')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _marketSettings = snapshot.data();
        notifyListeners();
      }
    });
  }

  bool get isMarketOpen {
    final now = DateTime.now();

    
    if (_marketSettings != null) {
      final overrideDateTimestamp = _marketSettings!['overrideDate'] as Timestamp?;
      final isClosed = _marketSettings!['isClosed'] as bool? ?? false;

      if (overrideDateTimestamp != null) {
        final overrideDate = overrideDateTimestamp.toDate();
        
        if (overrideDate.year == now.year &&
            overrideDate.month == now.month &&
            overrideDate.day == now.day) {
          if (isClosed) return false;
        }
      }
    }

    if (now.weekday == DateTime.saturday) {
      return false;
    }

    final startTime = DateTime(now.year, now.month, now.day, 11, 15);
    final endTime = DateTime(now.year, now.month, now.day, 17, 0); 

    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  String get marketStatusMessage {
    if (isMarketOpen) return "Market Open";
    
    final now = DateTime.now();
    if (now.weekday == DateTime.saturday) return "Market Closed (Saturday)";
    
    if (_marketSettings != null) {
       final overrideDateTimestamp = _marketSettings!['overrideDate'] as Timestamp?;
       final isClosed = _marketSettings!['isClosed'] as bool? ?? false;
        if (overrideDateTimestamp != null && isClosed) {
             final overrideDate = overrideDateTimestamp.toDate();
             if (overrideDate.year == now.year &&
                overrideDate.month == now.month &&
                overrideDate.day == now.day) {
               return "Market Closed by Admin";
             }
        }
    }

    return "Market Closed (11:15 AM - 5:00 PM)";
  }

  Future<void> setMarketOverride({required DateTime date, required bool isClosed}) async {
    await FirebaseFirestore.instance.collection('market_settings').doc('config').set({
      'overrideDate': Timestamp.fromDate(date),
      'isClosed': isClosed,
    }, SetOptions(merge: true));
  }
  
  Future<void> clearMarketOverride() async {
      await FirebaseFirestore.instance.collection('market_settings').doc('config').update({
      'overrideDate': FieldValue.delete(),
      'isClosed': FieldValue.delete(),
    });
  }

  Future<void> fetchPrice() async {
    _isLoadingPrice = true;
    notifyListeners();
    try {
      _currentPrice = await _priceService.getSilverPrice();
    } catch (e) {
      debugPrint("Error fetching price: $e");
    } finally {
      _isLoadingPrice = false;
      notifyListeners();
    }
  }

  Future<void> fetchPortfolio(String userId) async {
    _isLoadingPortfolio = true;
    notifyListeners();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('portfolios')
          .doc(userId)
          .get();

      if (doc.exists) {
        _portfolio = PortfolioModel.fromMap(doc.data()!, userId);
      } else {
        _portfolio = PortfolioModel(
            userId: userId, totalSilverTola: 0, totalInvestedAmount: 0);
      }
    } catch (e) {
      debugPrint("Error fetching portfolio: $e");
    } finally {
      _isLoadingPortfolio = false;
      notifyListeners();
    }
  }

  Future<void> executeTrade({
    required String userId,
    required TransactionType type,
    required double quantityTola,
  }) async {
    if (!isMarketOpen) throw Exception("Market is currently closed.");
    if (_currentPrice == null) throw Exception("Price not available");
    
    double totalAmount = quantityTola * _currentPrice!;
    
    // Apply 1% deduction on SELL
    if (type == TransactionType.sell) {
      totalAmount = totalAmount * 0.99; 
    }

    final transactionId = FirebaseFirestore.instance.collection('transactions').doc().id;

    final transaction = TransactionModel(
      id: transactionId,
      userId: userId,
      type: type,
      quantityTola: quantityTola,
      ratePerTola: _currentPrice!,
      totalAmount: totalAmount,
      timestamp: DateTime.now(),
    );

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final portRef = FirebaseFirestore.instance.collection('portfolios').doc(userId);
      final portDoc = await tx.get(portRef);
      
      double currentSilver = 0;
      double currentInvested = 0;

      if (portDoc.exists) {
        final data = portDoc.data()!;
        currentSilver = (data['totalSilverTola'] ?? 0).toDouble();
        currentInvested = (data['totalInvestedAmount'] ?? 0).toDouble();
      }

      if (type == TransactionType.buy) {
        currentSilver += quantityTola;
        currentInvested += totalAmount;
      } else {
        if (currentSilver < quantityTola) {
          throw Exception("Insufficient holdings to sell");
        }
        currentSilver -= quantityTola;
         if (currentSilver > 0) {
           double ratio = quantityTola / (currentSilver + quantityTola);
           currentInvested = currentInvested * (1 - ratio);
         } else {
           currentInvested = 0;
         }
      }

      final newPortfolio = PortfolioModel(
        userId: userId,
        totalSilverTola: currentSilver,
        totalInvestedAmount: currentInvested,
      );
      
      final txRef = FirebaseFirestore.instance.collection('transactions').doc(transactionId);
      tx.set(txRef, transaction.toMap()); 
      tx.set(portRef, newPortfolio.toMap()); 
    });

    await fetchPortfolio(userId);
  }
}
