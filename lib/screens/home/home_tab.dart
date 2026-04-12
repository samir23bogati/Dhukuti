import 'package:dhukuti/providers/market_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedMetal = 'silver';
  String _timeRange = '1W'; // 24h, 1W, 1M, 1Y

  @override
  Widget build(BuildContext context) {
    final marketProvider = context.watch<MarketProvider>();
    final silverPrice = marketProvider.currentSilverPrice;
    final goldPrice = marketProvider.currentGoldPrice;
    final isLoading = marketProvider.isLoadingPrice;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Live Metal Rates",
            style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: screenHeight * 0.015),

          _buildPriceCard("Silver", silverPrice, isLoading, screenWidth, Colors.blueGrey),
          SizedBox(height: screenHeight * 0.012),
          _buildPriceCard("Gold (Hallmark)", goldPrice, isLoading, screenWidth, Colors.orange),

          SizedBox(height: screenHeight * 0.035),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Price Trends",
                style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: _selectedMetal,
                underline: const SizedBox(),
                onChanged: (val) => setState(() => _selectedMetal = val!),
                items: const [
                  DropdownMenuItem(value: 'silver', child: Text("Silver")),
                  DropdownMenuItem(value: 'gold', child: Text("Gold")),
                ],
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.012),
          
          Container(
            height: screenHeight * 0.3,
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: LineChart(
                    _getChartData(_selectedMetal, _timeRange),
                  ),
                ),
                SizedBox(height: screenHeight * 0.012),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['24h', '1W', '1M', '1Y'].map((range) {
                    final isSelected = _timeRange == range;
                    return GestureDetector(
                      onTap: () => setState(() => _timeRange = range),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.015),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        ),
                        child: Text(
                          range,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          SizedBox(height: screenHeight * 0.035),

          Text(
            "Market Status",
            style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: screenHeight * 0.015),
          
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: marketProvider.isMarketOpen ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(color: marketProvider.isMarketOpen ? Colors.green.shade200 : Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  marketProvider.isMarketOpen ? Icons.lock_open : Icons.lock,
                  color: marketProvider.isMarketOpen ? Colors.green : Colors.red,
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.04),
                Text(
                  marketProvider.marketStatusMessage,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                    color: marketProvider.isMarketOpen ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.025),
        ],
      ),
    );
  }

  LineChartData _getChartData(String metal, String range) {
    // Dummy Data Generation for Price Trends
    List<FlSpot> spots = [];
    double basePrice = metal == 'gold' ? 120000 : 1400;
    
    // Generate some random fluctuation
    for (int i = 0; i < 7; i++) {
        double offset = (i * 100).toDouble();
        if (i % 2 == 0) offset = -offset;
        spots.add(FlSpot(i.toDouble(), basePrice + offset));
    }

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: metal == 'gold' ? Colors.orange : Colors.blueGrey,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: (metal == 'gold' ? Colors.orange : Colors.blueGrey).withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard(String title, double? price, bool isLoading, double screenWidth, Color iconColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.diamond, color: iconColor, size: screenWidth * 0.06),
                SizedBox(width: screenWidth * 0.03),
                Text(title, style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w500)),
              ],
            ),
            if (isLoading)
              SizedBox(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (price == null)
              Text("Error", style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.04))
            else
              Text(
                "Rs. ${price.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
