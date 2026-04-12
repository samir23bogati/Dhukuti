import 'package:dhukuti/providers/market_provider.dart';
import 'package:dhukuti/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PortfolioTab extends StatefulWidget {
  const PortfolioTab({super.key});

  @override
  State<PortfolioTab> createState() => _PortfolioTabState();
}

class _PortfolioTabState extends State<PortfolioTab> {
  bool _initFetchDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initFetchDone) {
      final user = context.read<UserProvider>().userModel;
      if (user != null) {
        Future.microtask(() {
          if (mounted) {
            context.read<MarketProvider>().fetchPortfolio(user.uid);
          }
        });
        _initFetchDone = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final marketProvider = context.watch<MarketProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (userProvider.errorMessage != null) {
      return Center(child: Text("Error: ${userProvider.errorMessage}", style: TextStyle(fontSize: screenWidth * 0.04)));
    }

    final portfolio = marketProvider.portfolio;
    final silverPrice = marketProvider.currentSilverPrice ?? 0;
    final goldPrice = marketProvider.currentGoldPrice ?? 0;

    if (userProvider.isLoading || portfolio == null || marketProvider.isLoadingPortfolio) {
      return Center(child: CircularProgressIndicator());
    }

    final silverValue = portfolio.totalSilverTola * silverPrice;
    final silverPL = silverValue - portfolio.totalSilverInvestedAmount;
    
    final goldValue = portfolio.totalGoldTola * goldPrice;
    final goldPL = goldValue - portfolio.totalGoldInvestedAmount;

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("My Portfolio", style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold)),
          SizedBox(height: screenHeight * 0.03),
          
          _buildMetalSection("Silver", portfolio.totalSilverTola, portfolio.totalSilverInvestedAmount, silverPL, screenWidth, screenHeight, Colors.blueGrey),
          SizedBox(height: screenHeight * 0.03),
          _buildMetalSection("Gold", portfolio.totalGoldTola, portfolio.totalGoldInvestedAmount, goldPL, screenWidth, screenHeight, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildMetalSection(String title, double qty, double invested, double pl, double screenWidth, double screenHeight, Color color) {
    final isProfit = pl >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.diamond, color: color, size: screenWidth * 0.05),
            SizedBox(width: screenWidth * 0.02),
            Text(title, style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        SizedBox(height: screenHeight * 0.012),
        _buildSummaryCard("Holdings", "${qty.toStringAsFixed(2)} Tola", screenWidth, screenHeight),
        _buildSummaryCard("Invested", "Rs. ${invested.toStringAsFixed(2)}", screenWidth, screenHeight),
        _buildSummaryCard(
          "Profit / Loss",
          "Rs. ${pl.abs().toStringAsFixed(2)}",
          screenWidth,
          screenHeight,
          valueColor: isProfit ? Colors.green : Colors.red,
          subtitle: isProfit ? "Profit" : "Loss",
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, double screenWidth, double screenHeight, {Color? valueColor, String? subtitle}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
      child: ListTile(
        dense: true,
        title: Text(title, style: TextStyle(fontSize: screenWidth * 0.035)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: valueColor, fontSize: screenWidth * 0.03)) : null,
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ),
    );
  }
}
