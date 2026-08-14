import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime? start;
  DateTime? end;
  final nameCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isStart) async {
    final d = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() => isStart ? start = d : end = d);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sorted = [...state.events]..sort((a, b) => a.start.compareTo(b.start));

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎉 المناسبات والأعياد والعطل', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('أدخل تاريخ البداية والنهاية واسم المناسبة أو العيد أو العطلة.', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => _pick(true),
                      child: Text(start == null ? 'من' : AppState.fmtDate(start!)),
                    ),
                    OutlinedButton(
                      onPressed: () => _pick(false),
                      child: Text(end == null ? 'الى' : AppState.fmtDate(end!)),
                    ),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(hintText: 'اسم المناسبة/العيد/العطلة', isDense: true),
                      ),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة'),
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (start == null || name.isEmpty) return;
                        state.addEvent(
                          AppState.fmtDate(start!),
                          end != null ? AppState.fmtDate(end!) : AppState.fmtDate(start!),
                          name,
                        );
                        nameCtrl.clear();
                        setState(() { start = null; end = null; });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (sorted.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('لا توجد مناسبات مضافة بعد', style: TextStyle(color: Colors.grey))),
          )
        else
          for (final ev in sorted)
            Card(
              child: ListTile(
                leading: const Icon(Icons.celebration_rounded),
                title: Text(ev.name),
                subtitle: Text('${AppState.dispDate(ev.start)}  الى  ${AppState.dispDate(ev.end)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => state.removeEvent(ev.id),
                ),
              ),
            ),
      ],
    );
  }
}
