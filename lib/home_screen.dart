import 'package:flutter/material.dart';
import 'bmi_screen.dart';
import 'water_tracker_screen.dart';
import 'health_analysis_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => MainDashboardState();
}

class MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  final GlobalKey<HealthAnalysisScreenState> _analysisKey = GlobalKey();
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // 3. Initialize here so the key is properly tied to this State instance
    _pages = [
      const BMIScreen(),
      HealthAnalysisScreen(key: _analysisKey), // Ensure 'const' is NOT here
      const WaterTrackerScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });if (index == 1) {
            _analysisKey.currentState?.loadData();
          }
        },
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: "BMI"),
          BottomNavigationBarItem(icon: Icon(Icons.health_and_safety), label: "Analysis"),
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: "Water Tracker"),
        ],
      ),
    );
  }
}