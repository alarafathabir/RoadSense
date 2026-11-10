import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_sense/screens/camera_screen.dart';
import 'package:road_sense/screens/home_screen.dart';
import 'package:road_sense/screens/map_screen.dart';
import 'package:road_sense/screens/profile_screen.dart';
import 'package:road_sense/screens/repair_tasks_screen.dart';
import 'package:road_sense/state/app_state.dart';
import 'package:road_sense/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const RoadSenseApp());
}

class RoadSenseApp extends StatelessWidget {
  const RoadSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'RoadSense PW',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const MainNavigator(),
        );
      },
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  static MainNavigatorState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainNavigatorState>();

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  void switchTab(int index) {
    if (index >= 0 && index < 4) {
      setState(() => _currentIndex = index);
    }
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          CameraScreen(),
          MapScreen(),
          RepairTasksScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => switchTab(0),
              ),
              _NavItem(
                icon: Icons.videocam_outlined,
                activeIcon: Icons.videocam_rounded,
                label: 'Camera',
                isActive: _currentIndex == 1,
                onTap: () => switchTab(1),
              ),
              _NavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'Map',
                isActive: _currentIndex == 2,
                onTap: () => switchTab(2),
              ),
              _NavItem(
                icon: Icons.tune_rounded,
                activeIcon: Icons.tune_rounded,
                label: 'Tasks',
                isActive: _currentIndex == 3,
                onTap: () => switchTab(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primaryTeal : AppTheme.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.lightBlueAccent.withValues(alpha: 0.3),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: color,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Inter',
                  color: color,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
