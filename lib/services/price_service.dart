import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PriceService {
  static const String _url = 'https://www.hamropatro.com/gold';
  static const String _cacheKeyPrice = 'daily_silver_price';
  static const String _cacheKeyTime = 'last_fetch_timestamp';

  Future<double> getSilverPrice() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Target update time: Today at 11:05 AM
    final targetTime = DateTime(now.year, now.month, now.day, 11, 5);

    final lastFetchMs = prefs.getInt(_cacheKeyTime);
    final lastFetch = lastFetchMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastFetchMs)
        : null;

    // Check if we have valid cache
    if (lastFetch != null) {
      // If it's before 11:05 AM, simply return whatever we have (yesterday's or today's early fetch)
      // UNLESS we don't have a value at all.
      // If it's AFTER 11:05 AM, we need to ensure our fetch was also AFTER 11:05 AM today.
      
      bool needsUpdate = false;
      if (now.isAfter(targetTime)) {
        // It's past 11:05. Did we fetch after 11:05 today?
        if (lastFetch.isBefore(targetTime)) {
          needsUpdate = true;
        }
      } else {
        // It's before 11:05.
        // We can use yesterday's data or whatever is cached. 
        // Only fetch if data is excessively old? (e.g. > 24h). 
        // For simplicity, let's just use cache if available.
      }

      if (!needsUpdate) {
        final cachedPrice = prefs.getDouble(_cacheKeyPrice);
        if (cachedPrice != null) {
          return cachedPrice;
        }
      }
    }

    // Fetch from Network
    try {
      final price = await _fetchFromHamroPatro();
      // Save to cache
      await prefs.setDouble(_cacheKeyPrice, price);
      await prefs.setInt(_cacheKeyTime, now.millisecondsSinceEpoch);
      return price;
    } catch (e) {
      // If fetch fails, return cached if available, else rethrow
      final cachedPrice = prefs.getDouble(_cacheKeyPrice);
      if (cachedPrice != null) return cachedPrice;
      rethrow;
    }
  }

  Future<double> _fetchFromHamroPatro() async {
    final response = await http.get(Uri.parse(_url));
    if (response.statusCode == 200) {
      // Logic for HamroPatro:
      // Look for "<li ...>Silver - tola ...</li>" followed by "<li ...>Nrs. PRICE</li>"
      // This avoids matching description text.
      final RegExp regExp = RegExp(r'<li[^>]*>Silver - tola.*?</li>\s*<li[^>]*>\s*Nrs\.\s*([\d,.]+)', dotAll: true);
      final match = regExp.firstMatch(response.body);

      if (match != null) {
        final priceString = match.group(1)?.replaceAll(',', '') ?? '';
        final price = double.tryParse(priceString);
        if (price != null) return price;
      }
    }
    throw Exception('Failed to scrape price from Hamro Patro');
  }
}
