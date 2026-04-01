import 'package:dhukuti/providers/user_provider.dart';
import 'package:dhukuti/screens/admin/admin_dashboard.dart';
import 'package:dhukuti/screens/chatbot/chatbot_screen.dart';
import 'package:dhukuti/screens/history/transaction_history_screen.dart';
import 'package:dhukuti/screens/home/home_tab.dart';
import 'package:dhukuti/screens/portfolio/portfolio_tab.dart';
import 'package:dhukuti/screens/profile/profile_tab.dart';
import 'package:dhukuti/screens/trade/trade_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isAdmin = userProvider.isAdmin;

    final List<Widget> pages = [
      isAdmin ? const AdminDashboard() : const HomeTab(),
      const PortfolioTab(),
      const TradeTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdmin && _currentIndex == 0 ? "Admin Dashboard" :
          _currentIndex == 0 ? "Dashboard" : 
          _currentIndex == 1 ? "Portfolio" :
          _currentIndex == 2 ? "Trade" : "Profile"
        ),
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.55,
        child: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(userProvider.userModel?.name ?? "User", style: const TextStyle(fontSize: 14)),
                accountEmail: Text(userProvider.userModel?.phone ?? "", style: const TextStyle(fontSize: 12)),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 30, color: Colors.blue),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard, size: 20),
                title: const Text("Dashboard", style: TextStyle(fontSize: 13)),
                onTap: () {
                  setState(() => _currentIndex = 0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, size: 20),
                title: const Text("Profile", style: TextStyle(fontSize: 13)),
                onTap: () {
                  setState(() => _currentIndex = 3);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, size: 20),
                title: const Text("Transaction History", style: TextStyle(fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.blue),
                title: const Text("AI Assistant", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red, size: 20),
                title: const Text("Logout", style: TextStyle(color: Colors.red, fontSize: 13)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                     Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: "Portfolio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: "Trade",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
