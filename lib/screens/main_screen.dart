import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'history/history_screen.dart';
import 'settings/settings_screen.dart';

/// 主屏幕（带底部导航）
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: '首页',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_outlined),
      activeIcon: Icon(Icons.history),
      label: '历史',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: '设置',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: _bottomNavItems
            .map((item) => NavigationDestination(
                  icon: item.icon,
                  selectedIcon: item.activeIcon,
                  label: item.label!,
                ))
            .toList(),
      ),
    );
  }
}
