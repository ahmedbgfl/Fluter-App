import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});
  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  String? classId;
  DateTime? date, correctionDate;
  TimeOfDay? time, correctionTime;
  final subjectCtrl = TextEditingController();

  @override
  void dispose() {
    subjectCtrl.dispose();
    super.dispose();
  }

  String? _fmtTime(TimeOfDay? t) =>
      t == null ? null : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (classId == null && state.classes.isNotEmpty) classId = state.classes.first.id;
    final sortedHw = [...state.homeworks]..sort((a, b) => a.date.compareTo(b.date));

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📝 الفروض', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('القسم، تاريخ وتوقيت الفرض، وتاريخ وتوقيت تصحيحه (اختياري).', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                if (state.classes.isEmpty)
                  const Text('أضف أقساما أولا')
                else ...[
                  DropdownButtonFormField<String>(
                    value: classId,
                    decoration: const InputDecoration(labelText: 'القسم', isDense: true),
                    items: [for (final c in state.classes) DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.level})'))],
                    onChanged: (v) => setState(() => classId = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: subjectCtrl,
                    decoration: const InputDecoration(labelText: 'الموضوع (اختياري)', isDense: true),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton(
                      onPressed: () async {
                        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (d != null) setState(() => date = d);
                      },
                      child: Text('تاريخ الفرض: ${date == null ? "—" : AppState.fmtDate(date!)}'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (t != null) setState(() => time = t);
                      },
                      child: Text('توقيته: ${_fmtTime(time) ?? "—"}'),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton(
                      onPressed: () async {
                        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (d != null) setState(() => correctionDate = d);
                      },
                      child: Text('تاريخ التصحيح: ${correctionDate == null ? "—" : AppState.fmtDate(correctionDate!)}'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (t != null) setState(() => correctionTime = t);
                      },
                      child: Text('توقيته: ${_fmtTime(correctionTime) ?? "—"}'),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة فرض'),
                    onPressed: () {
                      if (classId == null || date == null) return;
                      state.addHomework(HomeworkItem(
                        id: newId(),
                        classId: classId!,
                        date: AppState.fmtDate(date!),
                        time: _fmtTime(time) ?? '',
                        subject: subjectCtrl.text.trim(),
                        correctionDate: correctionDate != null ? AppState.fmtDate(correctionDate!) : '',
                        correctionTime: _fmtTime(correctionTime) ?? '',
                      ));
                      setState(() {
                        date = null; time = null; correctionDate = null; correctionTime = null;
                        subjectCtrl.clear();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        for (final h in sortedHw)
          Card(
            child: ListTile(
              leading: const Icon(Icons.assignment_rounded),
              title: Text('${state.classes.where((c) => c.id == h.classId).map((c) => c.name).firstOrNull ?? "—"}'
                  '${h.subject.isNotEmpty ? " — ${h.subject}" : ""}'),
              subtitle: Text(
                  'الفرض: ${AppState.dispDate(h.date)} ${h.time}\n'
                  '${h.correctionDate.isNotEmpty ? "التصحيح: ${AppState.dispDate(h.correctionDate)} ${h.correctionTime}" : ""}'),
              isThreeLine: h.correctionDate.isNotEmpty,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => state.removeHomework(h.id),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📚 الاختبارات', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('تاريخ بداية ونهاية اختبارات كل فصل، وتاريخ وتوقيت تصحيحها (اختياري).', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 10),
                for (final t in ['T1', 'T2', 'T3']) _ExamTermRow(term: t),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExamTermRow extends StatelessWidget {
  final String term;
  const _ExamTermRow({required this.term});

  Future<DateTime?> _pickDate(BuildContext context) => showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ex = state.exams[term]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kExamLabel[term]!, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(
              onPressed: () async {
                final d = await _pickDate(context);
                if (d != null) {
                  await state.updateExamTerm(term, ExamTerm(
                    start: AppState.fmtDate(d), end: ex.end,
                    correctionDate: ex.correctionDate, correctionTime: ex.correctionTime));
                }
              },
              child: Text('من: ${ex.start.isEmpty ? "—" : AppState.dispDate(ex.start)}'),
            ),
            OutlinedButton(
              onPressed: () async {
                final d = await _pickDate(context);
                if (d != null) {
                  await state.updateExamTerm(term, ExamTerm(
                    start: ex.start, end: AppState.fmtDate(d),
                    correctionDate: ex.correctionDate, correctionTime: ex.correctionTime));
                }
              },
              child: Text('الى: ${ex.end.isEmpty ? "—" : AppState.dispDate(ex.end)}'),
            ),
            OutlinedButton(
              onPressed: () async {
                final d = await _pickDate(context);
                if (d != null) {
                  await state.updateExamTerm(term, ExamTerm(
                    start: ex.start, end: ex.end,
                    correctionDate: AppState.fmtDate(d), correctionTime: ex.correctionTime));
                }
              },
              child: Text('تصحيح: ${ex.correctionDate.isEmpty ? "—" : AppState.dispDate(ex.correctionDate)}'),
            ),
            OutlinedButton(
              onPressed: () async {
                final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (t != null) {
                  await state.updateExamTerm(term, ExamTerm(
                    start: ex.start, end: ex.end, correctionDate: ex.correctionDate,
                    correctionTime: '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'));
                }
              },
              child: Text('توقيت التصحيح: ${ex.correctionTime.isEmpty ? "—" : ex.correctionTime}'),
            ),
          ]),
          const Divider(),
        ],
      ),
    );
  }
}

extension _FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
