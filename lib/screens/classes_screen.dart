import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});
  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  String level = kLevels.first;
  final nameCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الأقسام حسب المستوى', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('أضف الأقسام التي تدرّسها (مثال: 1م1، 4م3...). كل قسم مرتبط بمستوى واحد.',
                    style: TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: level,
                      items: [for (final lv in kLevels) DropdownMenuItem(value: lv, child: Text(lv))],
                      onChanged: (v) => setState(() => level = v!),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(hintText: 'اسم القسم (1م1)', isDense: true),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        state.addClass(level, name);
                        nameCtrl.clear();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة قسم'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        for (final lv in kLevels)
          if (state.classes.any((c) => c.level == lv))
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(lv, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    for (final c in state.classes.where((c) => c.level == lv))
                      ListTile(
                        dense: true,
                        title: Text(c.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => state.removeClass(c.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        if (state.classes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('لا توجد أقسام بعد', style: TextStyle(color: Colors.grey))),
          ),
      ],
    );
  }
}
