import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

ScheduleEntry? _entryCoveringSlot(AppState state, int day, int slotIdx) {
  final slot = kSlots[slotIdx];
  for (final s in state.schedule) {
    if (s.day == day && s.start.compareTo(slot.start) <= 0 && s.end.compareTo(slot.end) >= 0) return s;
  }
  return null;
}

int maxSpanFromSlot(AppState state, int day, int slotIdx, {String? ignoreEntryId}) {
  final period = kSlots[slotIdx].period;
  var span = 0, idx = slotIdx;
  while (idx < kSlots.length && kSlots[idx].period == period) {
    final occ = _entryCoveringSlot(state, day, idx);
    if (occ != null && occ.id != ignoreEntryId) break;
    span++;
    idx++;
  }
  return span;
}

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.classes.isEmpty) {
      return const Center(child: Text('أضف أقساما أولا من تبويب "الأقسام"'));
    }

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'اضغط على أي خانة فارغة لإضافة حصة، أو خانة مشغولة لتعديلها. يمكن دمج خانتين متتاليتين في نفس '
            'اليوم والفترة لتمثيل حصة من ساعتين. حصة "استدراك" حصة مشتركة، تُدخل لها اسمًا بدل قسم محدد.',
            style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _ScheduleGrid(state: state),
        ),
      ],
    );
  }
}

class _ScheduleGrid extends StatelessWidget {
  final AppState state;
  const _ScheduleGrid({required this.state});

  static const double dayColWidth = 70;
  static const double slotColWidth = 78;
  static const double rowHeight = 58;

  ScheduleEntry? _entryStartingAt(int day, int slotIdx) {
    final slot = kSlots[slotIdx];
    for (final s in state.schedule) {
      if (s.day == day && s.start == slot.start) return s;
    }
    return null;
  }

  ScheduleEntry? _entryCovering(int day, int slotIdx) => _entryCoveringSlot(state, day, slotIdx);

  int _spanOf(ScheduleEntry entry, int fromSlotIdx) {
    var span = 0, idx = fromSlotIdx;
    while (idx < kSlots.length && kSlots[idx].start.compareTo(entry.start) >= 0 && kSlots[idx].end.compareTo(entry.end) <= 0) {
      span++;
      idx++;
    }
    return span;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _HeaderCell('اليوم', width: dayColWidth),
            for (final s in kSlots) _HeaderCell('${s.start}\n${s.end}', width: slotColWidth),
          ],
        ),
        for (var di = 0; di < kDays.length; di++)
          Row(children: _buildDayCells(context, di)),
      ],
    );
  }

  List<Widget> _buildDayCells(BuildContext context, int di) {
    final cells = <Widget>[
      Container(
        width: dayColWidth,
        height: rowHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.brassSoft,
          border: Border.all(color: AppColors.brass.withOpacity(0.25)),
        ),
        child: Text(kDays[di],
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brassDeep, fontSize: 12)),
      ),
    ];
    var ci = 0;
    while (ci < kSlots.length) {
      final entry = _entryStartingAt(di, ci);
      if (entry != null) {
        final span = _spanOf(entry, ci);
        final label = entry.type == 'R'
            ? (entry.sessionName ?? 'استدراك')
            : (state.classes.where((c) => c.id == entry.classId).firstOrNull?.name ?? '—');
        final color = entry.type == 'TD'
            ? AppColors.brassSoft
            : entry.type == 'R'
                ? AppColors.dangerSoft
                : AppColors.sealSoft;
        cells.add(InkWell(
          onTap: () => _openEditor(context, day: di, slotIdx: ci, entry: entry),
          child: Container(
            width: slotColWidth * span,
            height: rowHeight,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: AppColors.brass.withOpacity(0.25)),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(kTypeLabel[entry.type] ?? '',
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.sealDeep)),
                Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ));
        ci += span;
      } else {
        cells.add(InkWell(
          onTap: () => _openEditor(context, day: di, slotIdx: ci, entry: null),
          child: Container(
            width: slotColWidth,
            height: rowHeight,
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.brass.withOpacity(0.25)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add, color: Colors.black26),
          ),
        ));
        ci += 1;
      }
    }
    return cells;
  }

  void _openEditor(BuildContext context, {required int day, required int slotIdx, ScheduleEntry? entry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _CellEditorSheet(day: day, slotIdx: slotIdx, entry: entry),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;
  const _HeaderCell(this.text, {required this.width});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 42,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.sealDeep),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
    );
  }
}

class _CellEditorSheet extends StatefulWidget {
  final int day;
  final int slotIdx;
  final ScheduleEntry? entry;
  const _CellEditorSheet({required this.day, required this.slotIdx, required this.entry});

  @override
  State<_CellEditorSheet> createState() => _CellEditorSheetState();
}

class _CellEditorSheetState extends State<_CellEditorSheet> {
  late String type;
  String? classId;
  final sessionCtrl = TextEditingController();
  late int span;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    type = e?.type ?? 'C';
    classId = e?.classId;
    sessionCtrl.text = e?.sessionName ?? '';
    span = 1;
  }

  @override
  void dispose() {
    sessionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final maxSpan = maxSpanFromSlot(state, widget.day, widget.slotIdx, ignoreEntryId: widget.entry?.id);
    if (classId == null && state.classes.isNotEmpty) classId = state.classes.first.id;

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: StatefulBuilder(builder: (context, setSheetState) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${widget.entry != null ? "تعديل" : "إضافة"} حصة — ${kDays[widget.day]} — ${kSlots[widget.slotIdx].start}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'نوع الحصة'),
                items: const [
                  DropdownMenuItem(value: 'C', child: Text('درس')),
                  DropdownMenuItem(value: 'TD', child: Text('أعمال موجهة (TD)')),
                  DropdownMenuItem(value: 'R', child: Text('استدراك')),
                ],
                onChanged: (v) => setSheetState(() => type = v!),
              ),
              const SizedBox(height: 10),
              if (type != 'R')
                DropdownButtonFormField<String>(
                  value: classId,
                  decoration: const InputDecoration(labelText: 'القسم'),
                  items: [for (final c in state.classes) DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.level})'))],
                  onChanged: (v) => setSheetState(() => classId = v),
                )
              else
                TextField(
                  controller: sessionCtrl,
                  decoration: const InputDecoration(labelText: 'اسم حصة الاستدراك'),
                ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: span > maxSpan ? 1 : span,
                decoration: const InputDecoration(labelText: 'عدد الحصص المدموجة'),
                items: [for (var n = 1; n <= maxSpan; n++) DropdownMenuItem(value: n, child: Text('$n ${n == 1 ? "حصة" : "حصص مدموجة"}'))],
                onChanged: (v) => setSheetState(() => span = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ'),
                      onPressed: () async {
                        final end = kSlots[widget.slotIdx + span - 1].end;
                        if (type == 'R') {
                          final name = sessionCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('أدخل اسم حصة الاستدراك')));
                            return;
                          }
                          await state.upsertScheduleEntry(
                            ScheduleEntry(
                                id: newId(), day: widget.day, start: kSlots[widget.slotIdx].start,
                                end: end, classId: null, sessionName: name, type: 'R'),
                            replaceId: widget.entry?.id,
                          );
                        } else {
                          if (classId == null) return;
                          await state.upsertScheduleEntry(
                            ScheduleEntry(
                                id: newId(), day: widget.day, start: kSlots[widget.slotIdx].start,
                                end: end, classId: classId, type: type),
                            replaceId: widget.entry?.id,
                          );
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                  if (widget.entry != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('حذف', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                        onPressed: () async {
                          await state.removeScheduleEntry(widget.entry!.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

extension _FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
