import 'package:flutter/material.dart';
import 'health_tips_screen.dart';
import 'database_helper.dart';

class HealthAnalysisScreen extends StatefulWidget {
  // Keep these as optional for the Navigator.push usage
  final int? actualAge;
  final int? healthAge;
  final String? riskLevel;
  final Color? riskColor;
  final List<String>? history;

  const HealthAnalysisScreen({
    super.key,
    this.actualAge,
    this.healthAge,
    this.riskLevel,
    this.riskColor,
    this.history,
  });

  @override
  State<HealthAnalysisScreen> createState() => _HealthAnalysisScreenState();
}

class _HealthAnalysisScreenState extends State<HealthAnalysisScreen> {
  // Local state variables to hold data fetched from SQLite
  int actualAge = 0;
  int healthAge = 0;
  String riskLevel = "No Data";
  Color riskColor = Colors.grey;
  List<String> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    // 1. If data was passed via constructor (Navigator.push), use it
    if (widget.actualAge != null && widget.actualAge != 0) {
      setState(() {
        actualAge = widget.actualAge!;
        healthAge = widget.healthAge!;
        riskLevel = widget.riskLevel!;
        riskColor = widget.riskColor!;
        history = widget.history!;
        isLoading = false;
      });
    } else {
      // 2. Otherwise (Tab access), fetch from Database
      final allData = await DatabaseHelper.instance.getAllHealthResults();

      if (allData.isNotEmpty) {
        final latest = allData.first; // The newest record for the top cards

        // Convert database rows into the string list for history
        List<String> dbHistory = allData.map((row) {
          return "Age: ${row['actualAge']} - ${row['riskLevel']} (${row['date'].toString().substring(0, 10)})";
        }).toList();

        setState(() {
          actualAge = latest['actualAge'];
          healthAge = latest['healthAge'];
          riskLevel = latest['riskLevel'];
          riskColor = Color(latest['riskColorValue']);
          history = dbHistory; // Now the history list is populated!
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    }
  }

  // Logic to pull data from your DatabaseHelper
  Future<void> _fetchLatestData() async {
    final latestData = await DatabaseHelper.instance.getLatestHealthResult();

    // We can also fetch the history list from your database here if needed
    // For now, let's assume we're loading the most recent result
    if (latestData != null) {
      setState(() {
        actualAge = latestData['actualAge'];
        healthAge = latestData['healthAge'];
        riskLevel = latestData['riskLevel'];
        riskColor = Color(latestData['riskColorValue']);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  String getHealthMessage() {
    if (riskLevel.contains("High")) {
      return "Your health risk is high. Regular exercise and medical advice are recommended.";
    } else if (riskLevel.contains("Moderate")) {
      return "You are doing okay, but improving diet and activity will help.";
    } else {
      return "Great! Maintain your healthy lifestyle.";
    }
  }

  double getHealthScore() {
    if (riskLevel.contains("High")) return 0.3;
    if (riskLevel.contains("Moderate")) return 0.6;
    return 0.9;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (actualAge == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text("Health Analysis")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 100,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 20),
              const Text(
                "No BMI Data Found",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Text("Please calculate your BMI first."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Analysis"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData, // Manual refresh button
          ),
        ],
        // Only show back button if we pushed this screen, hide if it's a tab
        leading: IconButton(
          icon: const Icon(Icons.health_and_safety),
          onPressed: () => _actionButtons(context), // Manual refresh button
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoCard(),
            const SizedBox(height: 16),
            _riskCard(),
            const SizedBox(height: 16),
            _healthScoreCard(),
            const SizedBox(height: 16),
            _messageCard(),
            const SizedBox(height: 20),
            _historyCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- UI WIDGETS (REMAIN THE SAME) ---

  Widget _infoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _infoItem("Actual Age", actualAge.toString()),
            _infoItem("Health Age", healthAge.toString(), highlight: true),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String title, String value, {bool highlight = false}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 25 : 22,
            fontWeight: FontWeight.bold,
            color: highlight ? Colors.teal : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _riskCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            riskLevel.contains("High")
                ? Icons.warning_amber_rounded
                : Icons.favorite,
            color: riskColor,
            size: 30,
          ),
          const SizedBox(width: 12),
          Text(
            riskLevel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: riskColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthScoreCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Health Score",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: getHealthScore(),
              color: riskColor,
              backgroundColor: Colors.grey.shade300,
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text("${(getHealthScore() * 100).toInt()}%"),
          ],
        ),
      ),
    );
  }

  Widget _messageCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(getHealthMessage(), style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _historyCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Health History",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (history.isEmpty) const Text("No history available"),
            ...history.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.timeline, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> _actionButtons(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HealthTipsScreen()),
    );
  }
}
