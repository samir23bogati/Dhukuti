import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PriceService {
  /// New Hamro Patro gold/silver page (legacy `/gold` redirects here).
  static const String _url = 'https://www.hamropatro.com/en/gold';
  static const String _cacheKeySilver = 'daily_silver_price_v4';
  static const String _cacheKeyGold = 'daily_gold_price_v4';
  static const String _cacheKeyTime = 'last_fetch_timestamp_v4';

  Future<Map<String, double>> getMetalPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final targetTime = DateTime(now.year, now.month, now.day, 11, 5);

    final lastFetchMs = prefs.getInt(_cacheKeyTime);
    final lastFetch = lastFetchMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastFetchMs)
        : null;

    if (lastFetch != null) {
      var needsUpdate = false;
      if (now.isAfter(targetTime) && lastFetch.isBefore(targetTime)) {
        needsUpdate = true;
      }

      if (!needsUpdate) {
        final cachedSilver = prefs.getDouble(_cacheKeySilver);
        final cachedGold = prefs.getDouble(_cacheKeyGold);
        if (cachedSilver != null && cachedGold != null) {
          debugPrint(
            'PriceService: Returning cached prices (S: $cachedSilver, G: $cachedGold)',
          );
          return {'silver': cachedSilver, 'gold': cachedGold};
        }
      }
    }

    try {
      final prices = await _fetchFromHamroPatro();
      await prefs.setDouble(_cacheKeySilver, prices['silver']!);
      await prefs.setDouble(_cacheKeyGold, prices['gold']!);
      await prefs.setInt(_cacheKeyTime, now.millisecondsSinceEpoch);
      debugPrint('PriceService: Fetched and cached new prices: $prices');
      return prices;
    } catch (e) {
      debugPrint('PriceService: Fetch error, trying cache: $e');
      final cachedSilver = prefs.getDouble(_cacheKeySilver);
      final cachedGold = prefs.getDouble(_cacheKeyGold);
      if (cachedSilver != null && cachedGold != null) {
        return {'silver': cachedSilver, 'gold': cachedGold};
      }
      rethrow;
    }
  }

  Future<Map<String, double>> _fetchFromHamroPatro() async {
    debugPrint('PriceService: Scraping Hamro Patro...');
    final response = await http.get(
      Uri.parse(_url),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'en-US,en;q=0.9',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Hamro Patro HTTP ${response.statusCode}');
    }

    final body = response.body;
    final fromJson = _parseFromEmbeddedJson(body);
    if (fromJson != null) {
      debugPrint('PriceService: Parsed from embedded JSON: $fromJson');
      return fromJson;
    }

    final fromHtml = _parseFromHtmlCards(body);
    if (fromHtml != null) {
      debugPrint('PriceService: Parsed from HTML cards: $fromHtml');
      return fromHtml;
    }

    throw Exception('Failed to scrape prices from Hamro Patro');
  }

  /// Embedded Next.js payload uses symbols SILVER / HALMARK (their spelling).
  Map<String, double>? _parseFromEmbeddedJson(String body) {
    final silver = _priceForSymbol(body, 'SILVER');
    // Site uses "HALMARK" (missing second L).
    final gold = _priceForSymbol(body, 'HALMARK') ??
        _priceForSymbol(body, 'HALLMARK');

    if (silver != null && gold != null) {
      return {'silver': silver, 'gold': gold};
    }
    return null;
  }

  double? _priceForSymbol(String body, String symbol) {
    final pattern = RegExp(
      '\\\\"symbol\\\\":\\\\"$symbol\\\\"[\\s\\S]*?'
      '\\\\"name\\\\":\\\\"1 tola\\\\",[\\s\\S]*?'
      '\\\\"price\\\\":(\\d+(?:\\.\\d+)?)',
    );
    final match = pattern.firstMatch(body);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  /// Visible card markup: "Gold (Hallmark)" / "Silver" + "Rs 3,04,900".
  Map<String, double>? _parseFromHtmlCards(String body) {
    final cardPattern = RegExp(
      r'text-title-sm[^>]*>([^<]+)</span>\s*'
      r'<span[^>]*>Per Tola</span>[\s\S]*?'
      r'tabular-nums[^>]*>Rs(?:<!-- -->)?\s*(?:<!-- -->)?\s*([\d,]+)',
    );

    double? silver;
    double? gold;

    for (final match in cardPattern.allMatches(body)) {
      final name = match.group(1)!.trim().toLowerCase();
      final price = _parseNepaliAmount(match.group(2)!);
      if (price == null) continue;

      if (name == 'silver') {
        silver = price;
      } else if (name.contains('hallmark')) {
        gold = price;
      }
    }

    if (silver != null && gold != null) {
      return {'silver': silver, 'gold': gold};
    }
    return null;
  }

  /// Handles both "4,725" and Indian grouping "3,04,900".
  double? _parseNepaliAmount(String raw) {
    return double.tryParse(raw.replaceAll(',', ''));
  }
}
