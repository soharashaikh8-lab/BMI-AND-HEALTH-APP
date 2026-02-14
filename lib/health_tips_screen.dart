import 'package:flutter/material.dart';

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchText = "";

  final Map<String, List<Map<String, String>>> tips = {
    "Nutrition": [
      {"title": "Eat fruits daily", "desc": "Fruits provide essential vitamins and fiber."},
      {"title": "Drink enough water", "desc": "Hydration improves digestion and energy."},
      {"title": "Include vegetables", "desc": "Vegetables are rich in minerals and antioxidants."},
      {"title": "Avoid junk food", "desc": "Reduces risk of obesity and heart disease."},
      {"title": "Eat whole grains", "desc": "Helps maintain stable blood sugar levels."},
      {"title": "Limit sugar intake", "desc": "Prevents diabetes and tooth decay."},
      {"title": "Add protein daily", "desc": "Protein helps in muscle repair and growth."},
      {"title": "Healthy fats matter", "desc": "Good fats support brain and heart health."},
      {"title": "Eat on time", "desc": "Improves metabolism and digestion."},
      {"title": "Avoid overeating", "desc": "Prevents weight gain and indigestion."},
    ],
    "Exercise": [
      {"title": "Walk 30 minutes", "desc": "Improves heart health and mood."},
      {"title": "Stretch daily", "desc": "Keeps muscles flexible and prevents injury."},
      {"title": "Do strength training", "desc": "Builds muscle and improves bone health."},
      {"title": "Try yoga", "desc": "Improves flexibility and reduces stress."},
      {"title": "Warm up before exercise", "desc": "Prepares muscles and avoids injury."},
      {"title": "Cool down after workout", "desc": "Helps muscles recover faster."},
      {"title": "Stay consistent", "desc": "Consistency is key for fitness results."},
      {"title": "Take rest days", "desc": "Allows muscles to recover and grow."},
      {"title": "Do cardio exercises", "desc": "Improves lung and heart capacity."},
      {"title": "Maintain good posture", "desc": "Prevents back and neck pain."},
    ],
    "Lifestyle": [
      {"title": "Sleep 7–8 hours", "desc": "Good sleep boosts immunity and focus."},
      {"title": "Reduce screen time", "desc": "Helps eye health and sleep quality."},
      {"title": "Manage stress", "desc": "Reduces anxiety and improves mental health."},
      {"title": "Practice meditation", "desc": "Improves concentration and emotional balance."},
      {"title": "Stay socially connected", "desc": "Supports emotional well-being."},
      {"title": "Maintain a routine", "desc": "Improves productivity and discipline."},
      {"title": "Limit caffeine intake", "desc": "Prevents sleep disturbances."},
      {"title": "Take breaks while working", "desc": "Avoids burnout and fatigue."},
      {"title": "Practice gratitude", "desc": "Improves mental happiness."},
      {"title": "Spend time outdoors", "desc": "Boosts mood and vitamin D levels."},
    ],
  };

  late final List<Map<String, String>> allTips;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tips.length, vsync: this);
    allTips = tips.values.expand((e) => e).toList();
  }

  Map<String, String> get tipOfTheDay {
    final index = DateTime.now().day % allTips.length;
    return allTips[index];
  }

  List<Map<String, String>> filterTips(List<Map<String, String>> list) {
    if (searchText.isEmpty) return list;
    return list.where((tip) =>
    tip["title"]!.toLowerCase().contains(searchText.toLowerCase()) ||
        tip["desc"]!.toLowerCase().contains(searchText.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Tips"),
        bottom: TabBar(
          controller: _tabController,
          tabs: tips.keys.map((e) => Tab(text: e)).toList(),
        ),
      ),
      body: Column(
        children: [
          _tipOfTheDayCard(),
          _searchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tips.keys.map((category) {
                final filtered = filterTips(tips[category]!);
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: filtered.map((tip) => _tipTile(tip)).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipOfTheDayCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tip of the Day: ${tipOfTheDay["title"]}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        decoration: const InputDecoration(
          hintText: "Search tips...",
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() {
            searchText = value;
          });
        },
      ),
    );
  }

  Widget _tipTile(Map<String, String> tip) {
    return Card(
      child: ExpansionTile(
        title: Text(tip["title"]!),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(tip["desc"]!),
          ),
        ],
      ),
    );
  }
}
