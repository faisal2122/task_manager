import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tasksBox');
  runApp(const StudentTaskApp());
}

class StudentTaskApp extends StatefulWidget {
  const StudentTaskApp({super.key});

  @override
  State<StudentTaskApp> createState() => _StudentTaskAppState();
}

class _StudentTaskAppState extends State<StudentTaskApp> {
  ThemeMode themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Student Task Manager",
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.indigo,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      home: HomeScreen(
        onThemeChange: () {
          setState(() {
            themeMode =
                themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          });
        },
        themeMode: themeMode,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeChange;
  final ThemeMode themeMode;

  const HomeScreen(
      {super.key, required this.onThemeChange, required this.themeMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final taskTitle = TextEditingController();
  final subject = TextEditingController();
  DateTime? dueDate;

  final tasksBox = Hive.box('tasksBox');

  void addTask() {
    if (taskTitle.text.isEmpty || subject.text.isEmpty || dueDate == null) {
      return;
    }

    tasksBox.add({
      "title": taskTitle.text,
      "subject": subject.text,
      "date": dueDate.toString(),
      "completed": false
    });

    taskTitle.clear();
    subject.clear();
    dueDate = null;

    Navigator.pop(context);
  }

  void showAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Add Student Task",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: taskTitle,
                  decoration: const InputDecoration(labelText: "Task Title"),
                ),
                TextField(
                  controller: subject,
                  decoration:
                      const InputDecoration(labelText: "Subject / Course"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      initialDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => dueDate = picked);
                    }
                  },
                  child: Text(
                    dueDate == null
                        ? "Select Due Date"
                        : "Due: ${dueDate!.day}-${dueDate!.month}-${dueDate!.year}",
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: addTask,
                  child: const Text("Save Task"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Task Manager"),
        actions: [
          IconButton(
            onPressed: widget.onThemeChange,
            icon: Icon(widget.themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Task"),
      ),
      body: ValueListenableBuilder(
        valueListenable: tasksBox.listenable(),
        builder: (context, box, _) {
          final tasks = box.values.toList();

          if (tasks.isEmpty) {
            return const Center(
              child: Text("No tasks yet. Tap + to add 😊"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final due = DateTime.parse(task["date"]);
              final isCompleted = task["completed"] == true;
              final isOverdue = !isCompleted && due.isBefore(DateTime.now());

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: isCompleted,
                            onChanged: (value) {
                              box.putAt(index, {
                                "title": task["title"],
                                "subject": task["subject"],
                                "date": task["date"],
                                "completed": value
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              task["title"],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Text("Subject: ${task["subject"]}"),
                      Text(
                          "Due: ${due.day}-${due.month}-${due.year}"),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isCompleted)
                            const Chip(label: Text("Completed"))
                          else if (isOverdue)
                            const Chip(label: Text("Overdue"))
                          else
                            const Chip(label: Text("Upcoming")),

                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => box.deleteAt(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
