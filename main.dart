import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = PlannerStore();
  await store.load();
  runApp(PlannerApp(store: store));
}

class PlannerTask {
  String id;
  String title;
  int day; // 0 = Mon ... 6 = Sun
  bool done;
  int priority; // 0 low, 1 medium, 2 high

  PlannerTask({
    required this.id,
    required this.title,
    required this.day,
    this.done = false,
    this.priority = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'day': day,
        'done': done,
        'priority': priority,
      };

  factory PlannerTask.fromJson(Map<String, dynamic> j) => PlannerTask(
        id: j['id'] as String,
        title: j['title'] as String,
        day: j['day'] as int,
        done: j['done'] as bool? ?? false,
        priority: j['priority'] as int? ?? 1,
      );
}

class Habit {
  String id;
  String title;
  List<bool> days;

  Habit({required this.id, required this.title, List<bool>? days})
      : days = days ?? List.filled(7, false);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'days': days,
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        title: j['title'] as String,
        days: List<bool>.from(j['days'] as List),
      );
}

class PlannerStore extends ChangeNotifier {
  final List<PlannerTask> tasks = [];
  final List<Habit> habits = [];
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final rawTasks = _prefs!.getString('tasks');
    final rawHabits = _prefs!.getString('habits');

    if (rawTasks != null) {
      tasks
        ..clear()
        ..addAll((jsonDecode(rawTasks) as List)
            .map((e) => PlannerTask.fromJson(e)));
    } else {
      tasks.addAll([
        PlannerTask(id: '1', title: 'Изучить Python', day: 0, priority: 2),
        PlannerTask(id: '2', title: 'Тренировка', day: 0),
        PlannerTask(id: '3', title: 'Сделать проект', day: 1, priority: 2),
        PlannerTask(id: '4', title: 'Прочитать 20 страниц', day: 2),
        PlannerTask(id: '5', title: 'Практика SQL', day: 3),
        PlannerTask(id: '6', title: 'Повторить английский', day: 4),
      ]);
    }

    if (rawHabits != null) {
      habits
        ..clear()
        ..addAll((jsonDecode(rawHabits) as List).map((e) => Habit.fromJson(e)));
    } else {
      habits.addAll([
        Habit(id: 'h1', title: 'Учёба'),
        Habit(id: 'h2', title: 'Спорт'),
        Habit(id: 'h3', title: 'Чтение'),
      ]);
    }
  }

  Future<void> save() async {
    await _prefs?.setString(
        'tasks', jsonEncode(tasks.map((e) => e.toJson()).toList()));
    await _prefs?.setString(
        'habits', jsonEncode(habits.map((e) => e.toJson()).toList()));
  }

  void toggleTask(PlannerTask task) {
    task.done = !task.done;
    save();
    notifyListeners();
  }

  void addTask(String title, int day, int priority) {
    tasks.add(PlannerTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      day: day,
      priority: priority,
    ));
    save();
    notifyListeners();
  }

  void deleteTask(PlannerTask task) {
    tasks.remove(task);
    save();
    notifyListeners();
  }

  void addHabit(String title) {
    habits.add(Habit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
    ));
    save();
    notifyListeners();
  }

  void toggleHabit(Habit habit, int day) {
    habit.days[day] = !habit.days[day];
    save();
    notifyListeners();
  }

  void deleteHabit(Habit habit) {
    habits.remove(habit);
    save();
    notifyListeners();
  }

  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((t) => t.done).length;
  double get progress =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;
}

class PlannerApp extends StatelessWidget {
  final PlannerStore store;
  const PlannerApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'My Planner',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF090909),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE6E6E6),
            secondary: Color(0xFF9E9E9E),
            surface: Color(0xFF141414),
          ),
          fontFamily: 'sans',
          useMaterial3: true,
        ),
        home: HomeScreen(store: store),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final PlannerStore store;
  const HomeScreen({super.key, required this.store});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(store: widget.store),
      WeekPage(store: widget.store),
      HabitsPage(store: widget.store),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[tab],
      ),
      floatingActionButton: tab < 2
          ? FloatingActionButton(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              onPressed: () => showAddTask(context),
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              onPressed: () => showAddHabit(context),
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        backgroundColor: const Color(0xFF101010),
        indicatorColor: const Color(0xFF303030),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Неделя',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Привычки',
          ),
        ],
      ),
    );
  }

  Future<void> showAddTask(BuildContext context) async {
    final title = TextEditingController();
    int day = DateTime.now().weekday - 1;
    int priority = 1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151515),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Новая задача',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Название задачи',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: day,
                decoration: const InputDecoration(
                    labelText: 'День', border: OutlineInputBorder()),
                items: List.generate(
                  7,
                  (i) => DropdownMenuItem(value: i, child: Text(dayName(i))),
                ),
                onChanged: (v) => setModal(() => day = v ?? day),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: priority,
                decoration: const InputDecoration(
                    labelText: 'Приоритет', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Низкий')),
                  DropdownMenuItem(value: 1, child: Text('Средний')),
                  DropdownMenuItem(value: 2, child: Text('Высокий')),
                ],
                onChanged: (v) => setModal(() => priority = v ?? priority),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (title.text.trim().isEmpty) return;
                    widget.store.addTask(title.text.trim(), day, priority);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Добавить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showAddHabit(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        title: const Text('Новая привычка'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Например: Читать 20 минут'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.store.addHabit(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final PlannerStore store;
  const DashboardPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final progress = store.progress;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('МОЙ ПЛАНЕР',
              style: TextStyle(fontSize: 13, letterSpacing: 2.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text('Цели на неделю',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              ),
              CircleProgress(value: progress, size: 78),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              StatCard(
                  label: 'ВЫПОЛНЕНО',
                  value: '${store.completedTasks}',
                  icon: Icons.check_circle_outline),
              const SizedBox(width: 10),
              StatCard(
                  label: 'ОСТАЛОСЬ',
                  value: '${store.totalTasks - store.completedTasks}',
                  icon: Icons.pending_actions),
            ],
          ),
          const SizedBox(height: 20),
          SectionTitle(
            title: 'ЗАДАЧИ НА НЕДЕЛЮ',
            trailing: '${(progress * 100).round()}%',
          ),
          const SizedBox(height: 10),
          ...List.generate(7, (day) {
            final dayTasks = store.tasks.where((t) => t.day == day).toList();
            return DayCard(day: day, tasks: dayTasks, store: store);
          }),
        ],
      ),
    );
  }
}

class WeekPage extends StatelessWidget {
  final PlannerStore store;
  const WeekPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('НЕДЕЛЯ',
              style: TextStyle(fontSize: 13, letterSpacing: 2.5)),
          const SizedBox(height: 6),
          const Text('План задач',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          ...List.generate(
            7,
            (day) => DayCard(
              day: day,
              tasks: store.tasks.where((t) => t.day == day).toList(),
              store: store,
              expanded: true,
            ),
          ),
        ],
      ),
    );
  }
}

class HabitsPage extends StatelessWidget {
  final PlannerStore store;
  const HabitsPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ПРИВЫЧКИ',
              style: TextStyle(fontSize: 13, letterSpacing: 2.5)),
          const SizedBox(height: 6),
          const Text('Трекер привычек',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          if (store.habits.isEmpty)
            const EmptyBox(text: 'Пока нет привычек. Нажми +, чтобы добавить.'),
          ...store.habits.map(
            (habit) => HabitCard(habit: habit, store: store),
          ),
        ],
      ),
    );
  }
}

class DayCard extends StatelessWidget {
  final int day;
  final List<PlannerTask> tasks;
  final PlannerStore store;
  final bool expanded;

  const DayCard({
    super.key,
    required this.day,
    required this.tasks,
    required this.store,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((t) => t.done).length;
    return Card(
      color: const Color(0xFF141414),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF242424),
                  ),
                  alignment: Alignment.center,
                  child: Text(shortDay(day),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(dayName(day),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                Text('$completed/${tasks.length}',
                    style: const TextStyle(color: Colors.white54)),
              ],
            ),
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...tasks.map(
                (task) => Dismissible(
                  key: ValueKey(task.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => store.deleteTask(task),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline),
                  ),
                  child: TaskRow(task: task, store: store),
                ),
              ),
            ] else if (expanded)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Нет задач',
                      style: TextStyle(color: Colors.white38)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TaskRow extends StatelessWidget {
  final PlannerTask task;
  final PlannerStore store;
  const TaskRow({super.key, required this.task, required this.store});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => store.toggleTask(task),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 23,
              height: 23,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.done ? Colors.white : Colors.transparent,
                border: Border.all(color: Colors.white54),
              ),
              child: task.done
                  ? const Icon(Icons.check, size: 15, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 15,
                  decoration: task.done ? TextDecoration.lineThrough : null,
                  color: task.done ? Colors.white38 : Colors.white,
                ),
              ),
            ),
            if (task.priority == 2)
              const Icon(Icons.flag, size: 16, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class HabitCard extends StatelessWidget {
  final Habit habit;
  final PlannerStore store;
  const HabitCard({super.key, required this.habit, required this.store});

  @override
  Widget build(BuildContext context) {
    final count = habit.days.where((x) => x).length;
    return Card(
      color: const Color(0xFF141414),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(habit.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Text('$count/7',
                    style: const TextStyle(color: Colors.white54)),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') store.deleteHabit(habit);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'delete', child: Text('Удалить привычку')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final active = habit.days[i];
                return GestureDetector(
                  onTap: () => store.toggleHabit(habit, i),
                  child: Column(
                    children: [
                      Text(shortDay(i),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white54)),
                      const SizedBox(height: 5),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? Colors.white : const Color(0xFF262626),
                        ),
                        alignment: Alignment.center,
                        child: active
                            ? const Icon(Icons.check,
                                size: 17, color: Colors.black)
                            : const Icon(Icons.circle,
                                size: 7, color: Colors.white24),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class CircleProgress extends StatelessWidget {
  final double value;
  final double size;
  const CircleProgress({super.key, required this.value, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 8,
              backgroundColor: const Color(0xFF292929),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          Text('${(value * 100).round()}%',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const StatCard(
      {super.key,
      required this.label,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: const Color(0xFF141414),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.2,
                          color: Colors.white54)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String trailing;
  const SectionTitle({super.key, required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70)),
        ),
        Text(trailing, style: const TextStyle(color: Colors.white54)),
      ],
    );
  }
}

class EmptyBox extends StatelessWidget {
  final String text;
  const EmptyBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF141414),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54)),
        ),
      ),
    );
  }
}

String dayName(int day) => const [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье'
    ][day];

String shortDay(int day) => const ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'][day];
