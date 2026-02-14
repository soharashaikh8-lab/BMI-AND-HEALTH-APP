import 'package:flutter/material.dart';
import 'bmi_screen.dart';
import 'water_tracker_screen.dart';
import 'health_analysis_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const BMIScreen(),
    const HealthAnalysisScreen(), // This will show the "No Data" state initially
    const WaterTrackerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevents keyboard from pushing the tabs up/away
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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