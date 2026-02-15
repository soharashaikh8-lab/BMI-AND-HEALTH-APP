import 'package:flutter/material.dart';
import 'database_helper.dart';

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> with WidgetsBindingObserver {
  int dailyGoal = 2000;
  int consumedWater = 0;
  List<String> history = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndResetDaily(); // Load data from SQLite on startup
  }
  @override
  void dispose() {
    // 3. Unregister the observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 4. Trigger the check whenever the app is resumed
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndResetDaily();
    }
  }
  Future<void> _checkAndResetDaily() async {
    // 1. Get today's date formatted (YYYY-MM-DD)
    final String today = DateTime.now().toString().split(' ')[0];

    // 2. Ask SQLite for the date of the last glass of water you logged
    final String? lastEntryDate = await DatabaseHelper.instance.getLastEntryDate();

    // 3. Compare them
    if (lastEntryDate != null && lastEntryDate != today) {
      // If the dates don't match, it's a new day!
      await DatabaseHelper.instance.resetToday(); // Your method that deletes/archives records

      if (mounted) {
        setState(() {
          consumedWater = 0;
          history.clear();
        });
        _showSnackBar("Good morning! Your progress has been reset.");
      }
    }

    // 4. Always load the data for the current date
    _loadTodayData();
  }
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // Fetch data from Database
  Future<void> _loadTodayData() async {
    final data = await DatabaseHelper.instance.getTodayHistory();
    int total = 0;
    List<String> tempHistory = [];

    for (var item in data) {
      total += item['amount'] as int;
      tempHistory.add("Drank ${item['amount']} ml at ${item['time']}");
    }

    setState(() {
      consumedWater = total;
      history = tempHistory;
    });
  }

  void addWater(int amount) async {
    await DatabaseHelper.instance.insertWater(amount);
    _loadTodayData(); // Refresh UI from Database
  }

  void resetDay() async {
    await DatabaseHelper.instance.resetToday();
    setState(() {
      consumedWater = 0;
      history.clear();
    });
  }

  // --- UI PROGRESS LOGIC ---
  double get progress => (consumedWater / dailyGoal).clamp(0.0, 1.0);

  String get statusText {
    if (progress >= 1) return "Great! Goal Completed 🎉";
    if (progress >= 0.7) return "Almost there, keep going 💪";
    if (progress >= 0.4) return "Good start, stay hydrated 💧";
    return "Start drinking water 🚰";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Water Tracker"),
      ),
      // FIX 1: Wrap in SingleChildScrollView to handle small screens/keyboards
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _goalCard(),
            const SizedBox(height: 20),
            _progressCard(),
            const SizedBox(height: 20),
            _addButtons(),
            const SizedBox(height: 20),
            // FIX 2: Call the updated history section
            _historySection(),
          ],
        ),
      ),
    );
  }

  Widget _goalCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.flag),
        title: const Text("Daily Goal"),
        subtitle: Text("$dailyGoal ml"),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _showGoalDialog,
        ),
      ),
    );
  }

  void _showGoalDialog() async {
    final controller = TextEditingController(text: dailyGoal.toString());
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Set Daily Goal (ml)"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => dailyGoal = int.tryParse(controller.text) ?? dailyGoal);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "$consumedWater / $dailyGoal ml",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.blue.shade50,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            Text(statusText, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _addButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _waterButton("250 ml", 250),
        _waterButton("500 ml", 500),
      ],
    );
  }

  Widget _waterButton(String label, int amount) {
    return ElevatedButton.icon(
      onPressed: () => addWater(amount),
      icon: const Icon(Icons.water_drop),
      label: Text(label),
    );
  }

  Widget _historySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Constrain the column size
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's History", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // FIX 3: Remove Expanded and use shrinkWrap with Physics
            history.isEmpty
                ? const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No water intake yet"),
            ))
                : ListView.builder(
              shrinkWrap: true, // Allows ListView to take only needed space
              physics: const NeverScrollableScrollPhysics(), // Let the parent ScrollView handle scrolling
              itemCount: history.length,
              itemBuilder: (_, i) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                title: Text(history[i], style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}