import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class WeeksScreen extends StatefulWidget {
  const WeeksScreen({super.key});
  @override
  State<WeeksScreen> createState() => _WeeksScreenState();
}

class _WeeksScreenState extends State<WeeksScreen> {
  DateTime? startDate;
  final countCtrl = TextEditingController(text: '30');

  @override
  void dispose() {
    countCtrl.dispose();
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
                Text('الأسابيع الدراسية', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text(
                  'حدد تاريخ بداية السنة الدراسية وعدد الأسابيع لتوليد القائمة تلقائيا. '
                  'يمكن حذف أي أسبوع لتمثيل عطلة (لن يُستهلك من التوزيع السنوي).',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(startDate == null
                          ? 'اختر تاريخ البداية'
                          : AppState.fmtDate(startDate!)),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => startDate = d);
                      },
                    ),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: countCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'عدد الأسابيع', isDense: true),
                      ),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.event_repeat),
                      label: const Text('توليد الأسابيع'),
                      onPressed: startDate == null
                          ? null
                          : () {
                              final count = int.tryParse(countCtrl.text) ?? 30;
                              state.generateWeeks(AppState.fmtDate(startDate!), count);
                            },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة أسبوع في النهاية'),
                      onPressed: () => state.addWeekAtEnd(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (state.weeks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('لا توجد أسابيع بعد', style: TextStyle(color: Colors.grey))),
          )
        else
          for (var i = 0; i < state.weeks.length; i++)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('$i')),
                title: Text(
                    '${AppState.dispDate(state.weeks[i].start)}  الى  ${AppState.dispDate(AppState.addDays(state.weeks[i].start, 4))}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => state.removeWeek(i),
                ),
              ),
            ),
      ],
    );
  }
}
