import 'package:flutter/material.dart';
import 'database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
  List<Habit> habits = [];
  Map<int, HabitStatus> habitStatuses = {};
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  String get formattedDate {
    return "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadHabits() async {
    List<Habit> loadedHabits = await dbHelper.getHabits();
    Map<int, HabitStatus> statuses = {};
    for (var habit in loadedHabits) {
      HabitStatus? status = await dbHelper.getHabitStatus(
        habit.id!,
        formattedDate,
      );
      if (status != null) {
        statuses[habit.id!] = status;
      }
    }
    setState(() {
      habits = loadedHabits;
      habitStatuses = statuses;
    });
  }

  void _toggleHabit(Habit habit, bool? newValue) async {
    bool isCompleted = newValue ?? false;
    await dbHelper.toggleHabitStatus(habit.id!, formattedDate, isCompleted);
    _loadHabits();
  }

  void _changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
    _loadHabits();
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
      _loadHabits();
    }
  }

  void _addHabit() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Add Habit"),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: "Habit title"),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await dbHelper.insertHabit(Habit(title: controller.text));
                    Navigator.pop(context);
                    _loadHabits();
                  }
                },
                child: Text("Add"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
            ],
          ),
    );
  }

  void _deleteHabit(Habit habit) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Delete Habit"),
            content: Text("Are you sure you want to delete this habit?"),
            actions: [
              TextButton(
                onPressed: () async {
                  await dbHelper.deleteHabit(habit.id!);
                  Navigator.pop(context);
                  _loadHabits();
                },
                child: Text("Delete"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
            ],
          ),
    );
  }

  void _editStreak(Habit habit) async {
    TextEditingController controller = TextEditingController();
    HabitStatus? status = habitStatuses[habit.id!];
    int currentStreak = status?.streak ?? 0;
    controller.text = currentStreak.toString();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Edit Streak for ${habit.title}"),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: "Enter new streak"),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  int? newStreak = int.tryParse(controller.text);
                  if (newStreak != null && newStreak >= 0) {
                    await dbHelper.updateHabitStreak(
                      habit.id!,
                      newStreak as String,
                      formattedDate as int,
                    );
                    Navigator.pop(context);
                    _loadHabits();
                  }
                },
                child: Text("Save"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Habits for $formattedDate"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => _changeDate(-1),
        ),
        actions: [
          IconButton(icon: Icon(Icons.calendar_today), onPressed: _selectDate),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView.builder(
          itemCount: habits.length,
          itemBuilder: (_, index) {
            Habit habit = habits[index];
            HabitStatus? status = habitStatuses[habit.id!];
            bool isCompleted = status?.isCompleted == 1;
            int streak = status?.streak ?? 0;
            return ListTile(
              title: Text(habit.title),
              leading: Checkbox(
                value: isCompleted,
                onChanged: (value) => _toggleHabit(habit, value),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Streak: $streak🔥"),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _editStreak(habit),
                  ),
                ],
              ),
              onLongPress: () => _deleteHabit(habit),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: Icon(Icons.add),
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(color: Colors.brown),
        buttonTheme: ButtonThemeData(buttonColor: Colors.blueAccent),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.grey[400]),
        ),
        checkboxTheme: CheckboxThemeData(
          checkColor: WidgetStateProperty.all(Colors.white),
          fillColor: WidgetStateProperty.all(Colors.blueAccent),
        ),
      ),
      home: HomePage(),
    ),
  );
}
