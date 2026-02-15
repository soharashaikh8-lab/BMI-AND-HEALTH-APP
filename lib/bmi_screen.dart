import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart'; // Import this for navigation
import 'package:google_sign_in/google_sign_in.dart';

class BMIScreen extends StatefulWidget {
  const BMIScreen({super.key});

  @override
  State<BMIScreen> createState() => _BMIScreenState();
}

class _BMIScreenState extends State<BMIScreen> {
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final ageController = TextEditingController();

  String gender = "Male";
  double bmi = 0;
  String status = "";
  int healthAge = 0;
  String riskLevel = "";
  Color riskColor = Colors.green;

  List<String> healthHistory = [];

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    ageController.dispose();
    super.dispose();
  }

  void calculateBMI() async {
    if (heightController.text.isEmpty ||
        weightController.text.isEmpty ||
        ageController.text.isEmpty)
      return;

    double height = double.parse(heightController.text) / 100;
    double weight = double.parse(weightController.text);
    int age = int.parse(ageController.text);

    setState(() {
      bmi = weight / (height * height);

      if (bmi < 18.5) {
        status = "Underweight";
        riskLevel = "Low (Nutrient Deficiency)";
        riskColor = Colors.blue;
      } else if (bmi < 25) {
        status = "Normal";
        riskLevel = "Optimal Health";
        riskColor = Colors.green;
      } else if (bmi < 30) {
        status = "Overweight";
        riskLevel = "Moderate Risk";
        riskColor = Colors.orange;
      } else {
        status = "Obese";
        riskLevel = "High Risk";
        riskColor = Colors.red;
      }

      if (age < 18) {
        healthAge = age;
      } else if (status == "Normal") {
        healthAge = age - 2;
      } else if (status == "Overweight") {
        healthAge = age + 5;
      } else {
        healthAge = age + 10;
      }

      healthHistory.insert(
        0,
        "BMI: ${bmi.toStringAsFixed(1)} ($status) at Age: $age",
      );
    });

    await DatabaseHelper.instance.saveHealthResult(
      age,
      healthAge,
      riskLevel,
      riskColor.value,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                // 1. Clear Google session
                final GoogleSignIn googleSignIn = GoogleSignIn();
                if (await googleSignIn.isSignedIn()) {
                  await googleSignIn.signOut();
                }

                // 2. Clear Firebase session
                await FirebaseAuth.instance.signOut();

                if (context.mounted) {
                  Navigator.pop(context); // Close the dialog

                  // 3. Navigate AND clear the stack
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                  );
                }
              } catch (e) {
                debugPrint("Logout error: $e");
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "BMI Analytics",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInputSection(),
            const SizedBox(height: 25),
            if (bmi > 0) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _genderButton("Male", Icons.male, Colors.indigo),
              const SizedBox(width: 10),
              _genderButton("Female", Icons.female, Colors.pink),
            ],
          ),
          const SizedBox(height: 20),
          _inputField(heightController, "Height", "cm", Icons.height),
          const SizedBox(height: 15),
          _inputField(weightController, "Weight", "kg", Icons.scale_outlined),
          const SizedBox(height: 15),
          _inputField(
            ageController,
            "Age",
            "yrs",
            Icons.calendar_month_outlined,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: calculateBMI,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                "Calculate BMI",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: riskColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: riskColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            bmi.toStringAsFixed(1),
            style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900),
          ),
          const Text(
            "BMI SCORE",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 30),
          const Text(
            "Category Overview",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: 40,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Under', 'Norm', 'Over', 'You'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[value.toInt()],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _barGroup(0, 18.5, Colors.blue),
                  _barGroup(1, 24.9, Colors.green),
                  _barGroup(2, 29.9, Colors.orange),
                  _barGroup(3, bmi > 40 ? 40 : bmi, riskColor),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _dataTile("Health Age", "$healthAge"),
              _dataTile("Risk", riskLevel.split(' ')[0]),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 40,
            color: Colors.grey[200],
          ),
        ),
      ],
    );
  }

  Widget _genderButton(String title, IconData icon, Color activeColor) {
    bool isSelected = gender == title;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => gender = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
      TextEditingController controller,
      String label,
      String unit,
      IconData icon,
      ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        labelText: label,
        suffixText: unit,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dataTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}