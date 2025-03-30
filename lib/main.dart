import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Tracker',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
      ),
      home: HabitHomePage(),
    );
  }
}

class HabitHomePage extends StatefulWidget {
  @override
  _HabitHomePageState createState() => _HabitHomePageState();
}

class _HabitHomePageState extends State<HabitHomePage> {
  List<String> habits = ["Exercise", "Reading", "Drinking Water"];
  Map<String, int> habitStreaks = {
    "Exercise": 5,
    "Reading": 3,
    "Drinking Water": 7
  };

  void _addHabitDialog() {
    TextEditingController habitController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Habit"),
          content: TextField(
            controller: habitController,
            decoration: InputDecoration(hintText: "Enter habit name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (habitController.text.isNotEmpty) {
                  setState(() {
                    habits.add(habitController.text);
                    habitStreaks[habitController.text] = 0;
                  });
                }
                Navigator.pop(context);
              },
              child: Text("Add"),
            )
          ],
        );
      },
    );
  }

  void _markHabitCompleted(String habit) {
    setState(() {
      habitStreaks[habit] = (habitStreaks[habit] ?? 0) + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          "Habit Tracker",
          style: GoogleFonts.poppins(fontSize: 24),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Track your daily habits & progress!",
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, index) {
                return HabitCard(
                  habit: habits[index],
                  streak: habitStreaks[habits[index]] ?? 0,
                  onComplete: () => _markHabitCompleted(habits[index]),
                );
              },
            ),
          ),
          _buildChart(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabitDialog,
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 250,
      padding: EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          barGroups: habitStreaks.entries.map((entry) {
            return BarChartGroupData(
              x: habits.indexOf(entry.key),
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: Colors.blueAccent,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }).toList(),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  return Text(
                    habits[value.toInt()],
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        ),
      ),
    );
  }
}

class HabitCard extends StatelessWidget {
  final String habit;
  final int streak;
  final VoidCallback onComplete;

  HabitCard({required this.habit, required this.streak, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          habit,
          style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
        ),
        subtitle: Text(
          "🔥 Streak: $streak days",
          style: TextStyle(color: Colors.orangeAccent),
        ),
        trailing: ElevatedButton(
          onPressed: onComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text("Done"),
        ),
      ),
    );
  }
}
