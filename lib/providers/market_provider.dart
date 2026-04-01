import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhukuti/models/user_model.dart';
import 'package:dhukuti/models/portfolio_model.dart';
import 'package:dhukuti/models/transaction_model.dart';
import 'package:dhukuti/services/price_service.dart';
import 'package:dhukuti/utils/app_utils.dart';
import 'package:flutter/foundation.dart';

enum MarketStatus { open, closed, holiday }

class MarketProvider extends ChangeNotifier {
  final PriceService _priceService = PriceService();
  
  double? _currentSilverPrice;
  double? get currentSilverPrice => _currentSilverPrice;
  double? _currentGoldPrice;
  double? get currentGoldPrice => _currentGoldPrice;

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
    try {
      _settingsSubscription = FirebaseFirestore.instance
          .collection('market_settings')
          .doc('config')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          _marketSettings = snapshot.data();
          notifyListeners();
        }
      }, onError: (error) {
        debugPrint("Market settings listener error (permissions?): $error");
      });
    } catch (e) {
      debugPrint("Error initializing market settings listener: $e");
    }
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

    if (now.weekday == DateTime.saturday) return false;

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
      final prices = await _priceService.getMetalPrices();
      _currentSilverPrice = prices['silver'];
      _currentGoldPrice = prices['gold'];
    } catch (e) {
      debugPrint("Error fetching prices: $e");
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
          userId: userId, 
          totalSilverTola: 0, 
          totalSilverInvestedAmount: 0,
          totalGoldTola: 0,
          totalGoldInvestedAmount: 0,
        );
      }
    } catch (e) {
      debugPrint("Error fetching portfolio: $e");
    } finally {
      _isLoadingPortfolio = false;
      notifyListeners();
    }
  }

  Future<void> executeTrade({
    required UserModel user,
    required TransactionType type,
    required String metalType,
    required double quantityTola,
  }) async {
    if (!isMarketOpen) throw Exception("Market is currently closed.");
    
    /* 
    if (user.verificationStatus != 'verified') {
      throw Exception("Your account is not verified for trading. Please complete KYC.");
    }
    */
    
    final price = metalType == 'gold' ? _currentGoldPrice : _currentSilverPrice;
    if (price == null) throw Exception("Price not available");
    
    double totalAmount = quantityTola * price;
    
    // 1% Service Charge on PURCHASE
    if (type == TransactionType.buy) {
      totalAmount = AppUtils.calculateTotalWithFee(totalAmount); 
    }
    
    // Keeping current 1% on SELL if it was there by design, 
    // but the requirement explicitly mentions purchase.
    // The previous implementation had: if (type == TransactionType.sell) { totalAmount = totalAmount * 0.99; }
    // I'll keep it for now as it makes sense for business (spread/fee).
    if (type == TransactionType.sell) {
      totalAmount = totalAmount * 0.99; 
    }

    final transactionId = FirebaseFirestore.instance.collection('transactions').doc().id;
    final transaction = TransactionModel(
      id: transactionId,
      userId: user.uid,
      type: type,
      metalType: metalType,
      quantityTola: quantityTola,
      ratePerTola: price,
      totalAmount: totalAmount,
      timestamp: DateTime.now(),
    );

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final portRef = FirebaseFirestore.instance.collection('portfolios').doc(user.uid);
      final portDoc = await tx.get(portRef);
      
      double silverQty = 0;
      double silverInv = 0;
      double goldQty = 0;
      double goldInv = 0;

      if (portDoc.exists) {
        final data = portDoc.data()!;
        silverQty = (data['totalSilverTola'] ?? 0).toDouble();
        silverInv = (data['totalSilverInvestedAmount'] ?? data['totalInvestedAmount'] ?? 0).toDouble();
        goldQty = (data['totalGoldTola'] ?? 0).toDouble();
        goldInv = (data['totalGoldInvestedAmount'] ?? 0).toDouble();
      }

      if (metalType == 'gold') {
        if (type == TransactionType.buy) {
          goldQty += quantityTola;
          goldInv += totalAmount;
        } else {
          if (goldQty < quantityTola) throw Exception("Insufficient gold holdings");
          double prevQty = goldQty;
          goldQty -= quantityTola;
          if (goldQty > 0) {
            goldInv = goldInv * (goldQty / prevQty);
          } else {
            goldInv = 0;
          }
        }
      } else {
        if (type == TransactionType.buy) {
          silverQty += quantityTola;
          silverInv += totalAmount;
        } else {
          if (silverQty < quantityTola) throw Exception("Insufficient silver holdings");
          double prevQty = silverQty;
          silverQty -= quantityTola;
          if (silverQty > 0) {
            silverInv = silverInv * (silverQty / prevQty);
          } else {
            silverInv = 0;
          }
        }
      }

      final newPortfolio = PortfolioModel(
        userId: user.uid,
        totalSilverTola: silverQty,
        totalSilverInvestedAmount: silverInv,
        totalGoldTola: goldQty,
        totalGoldInvestedAmount: goldInv,
      );
      
      tx.set(FirebaseFirestore.instance.collection('transactions').doc(transactionId), transaction.toMap()); 
      tx.set(portRef, newPortfolio.toMap()); 
    });

    await fetchPortfolio(user.uid);
  }
}
