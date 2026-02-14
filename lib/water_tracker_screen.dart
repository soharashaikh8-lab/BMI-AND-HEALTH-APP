import 'package:flutter/material.dart';
import 'database_helper.dart';

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> {
  int dailyGoal = 2000;
  int consumedWater = 0;
  List<String> history = [];

  @override
  void initState() {
    super.initState();
    _loadTodayData(); // Load data from SQLite on startup
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetDay,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _goalCard(),
            const SizedBox(height: 20),
            _progressCard(),
            const SizedBox(height: 20),
            _addButtons(),
            const SizedBox(height: 20),
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
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Today's History", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: history.isEmpty
                    ? const Center(child: Text("No water intake yet"))
                    : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text("• ${history[i]}"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}