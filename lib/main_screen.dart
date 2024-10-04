import 'package:flutter/material.dart';

import 'home_page.dart';
import 'decrypt_page.dart';
import 'history_page.dart';
import 'settings_page.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    HomePage(),
    DecryptPage(),
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Decrypt';
      case 2:
        return 'History';
      case 3:
        return 'Settings';
      default:
        return 'Redact';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(), style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          _buildAnimatedPopupMenu(),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.lock_open), label: "Decrypt"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  // ... (rest of the code remains unchanged)


  // ... (rest of the code remains unchanged)


  Widget _buildAnimatedPopupMenu() {
    return PopupMenuButton<String>(
      offset: Offset(0, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: CircleAvatar(
        child: Icon(Icons.person),
        radius: 16,
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildAnimatedMenuItem("profile", Icons.person, "My Profile"),
        _buildAnimatedMenuItem("logout", Icons.logout, "Logout"),
      ],
      onSelected: (String value) {
        if (value == "profile") {
          // TODO: Navigate to profile page
        } else if (value == "logout") {
          // _logout();
        }
      },
      
    );
  }

  PopupMenuEntry<String> _buildAnimatedMenuItem(
      String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300),
        builder: (BuildContext context, double value, Widget? child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: ListTile(
                leading: Icon(icon),
                title: Text(text),
              ),
            ),
          );
        },
      ),
    );
  }
}

