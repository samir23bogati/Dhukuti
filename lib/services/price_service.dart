import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PriceService {
  static const String _url = 'https://www.hamropatro.com/gold';
  static const String _cacheKeySilver = 'daily_silver_price_v3';
  static const String _cacheKeyGold = 'daily_gold_price_v3';
  static const String _cacheKeyTime = 'last_fetch_timestamp_v3';

  Future<Map<String, double>> getMetalPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final targetTime = DateTime(now.year, now.month, now.day, 11, 5);

    final lastFetchMs = prefs.getInt(_cacheKeyTime);
    final lastFetch = lastFetchMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastFetchMs)
        : null;

    if (lastFetch != null) {
      bool needsUpdate = false;
      if (now.isAfter(targetTime)) {
        if (lastFetch.isBefore(targetTime)) {
          needsUpdate = true;
        }
      }

      if (!needsUpdate) {
        final cachedSilver = prefs.getDouble(_cacheKeySilver);
        final cachedGold = prefs.getDouble(_cacheKeyGold);
        if (cachedSilver != null && cachedGold != null) {
          debugPrint("PriceService: Returning cached prices (S: $cachedSilver, G: $cachedGold)");
          return {'silver': cachedSilver, 'gold': cachedGold};
        }
      }
    }

    try {
      final prices = await _fetchFromHamroPatro();
      await prefs.setDouble(_cacheKeySilver, prices['silver']!);
      await prefs.setDouble(_cacheKeyGold, prices['gold']!);
      await prefs.setInt(_cacheKeyTime, now.millisecondsSinceEpoch);
      debugPrint("PriceService: Fetched and cached new prices: $prices");
      return prices;
    } catch (e) {
      debugPrint("PriceService: Fetch error, trying cache: $e");
      final cachedSilver = prefs.getDouble(_cacheKeySilver);
      final cachedGold = prefs.getDouble(_cacheKeyGold);
      if (cachedSilver != null && cachedGold != null) {
        return {'silver': cachedSilver, 'gold': cachedGold};
      }
      rethrow;
    }
  }

  Future<Map<String, double>> _fetchFromHamroPatro() async {
    debugPrint("PriceService: Scraping Hamro Patro...");
    final response = await http.get(
      Uri.parse(_url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
    );
    if (response.statusCode == 200) {
      final body = response.body;

      final listRegExp = RegExp(r'<ul[^>]*class="gold-silver"[^>]*>(.*?)</ul>', dotAll: true);
      final listMatch = listRegExp.firstMatch(body);
      
      if (listMatch != null) {
        final listContent = listMatch.group(1)!;

        // More specific regex to ensure we get the right <li> pairs
        final silverRegExp = RegExp(r'Silver - tola.*?</li>\s*<li[^>]*>\s*Nrs\.\s*([\d,.]+)', dotAll: true);
        final goldRegExp = RegExp(r'Gold Hallmark - tola.*?</li>\s*<li[^>]*>\s*Nrs\.\s*([\d,.]+)', dotAll: true);
        
        final silverMatch = silverRegExp.firstMatch(listContent);
        final goldMatch = goldRegExp.firstMatch(listContent);

        double? silverPrice;
        double? goldPrice;

        if (silverMatch != null) {
          silverPrice = double.tryParse(silverMatch.group(1)!.replaceAll(',', ''));
          debugPrint("PriceService: Scraped Silver: $silverPrice");
        }
        if (goldMatch != null) {
          goldPrice = double.tryParse(goldMatch.group(1)!.replaceAll(',', ''));
          debugPrint("PriceService: Scraped Gold: $goldPrice");
        }

        if (silverPrice != null && goldPrice != null) {
          return {'silver': silverPrice, 'gold': goldPrice};
        }
      } else {
        debugPrint("PriceService: Could not find <ul class='gold-silver'>");
      }
    }
    throw Exception('Failed to scrape prices from Hamro Patro');
  }
}
