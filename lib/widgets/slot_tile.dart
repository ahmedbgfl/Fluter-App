import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

/// بطاقة حصة واحدة — تعرض التوقيت، القسم، سير الحصة (قابل للتعديل)، رقم المذكرة،
/// وزري "تم"/"تأجيل". إن كانت الحصة مؤجَّلة تلقائيا (عطلة/اختبار/فرض) تُعرض كشريط توضيحي بدلها.
class SlotTile extends StatelessWidget {
  final SlotResult slot;
  final int weekIdx;
  const SlotTile({super.key, required this.slot, required this.weekIdx});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ov = state.overrideFor(weekIdx, slot.slotId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TimePills(start: slot.start, end: slot.end),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PillBadge(
                        text: kTypeLabel[slot.type] ?? slot.type,
                        color: slot.type == 'TD'
                            ? AppColors.brass
                            : slot.type == 'R'
                                ? AppColors.danger
                                : AppColors.seal,
                      ),
                      const SizedBox(height: 4),
                      Text(slot.displayName(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.sealDeep)),
                    ],
                  ),
                ),
                if (slot.type != 'R')
                  _MemoBadge(
                    value: (ov.memoOv?.isNotEmpty ?? false) ? ov.memoOv! : (slot.item?.memo ?? ''),
                    onChanged: (v) => state.setOverrideField(weekIdx, slot.slotId, 'memoOv', v),
                  ),
              ],
            ),
            const Divider(height: 18),
            if (slot.auto != null)
              _AutoBanner(auto: slot.auto!)
            else if (slot.type == 'R')
              _NoteField(
                label: 'ملاحظة',
                value: (ov.noteOv?.isNotEmpty ?? false) ? ov.noteOv! : 'استدراك',
                onChanged: (v) => state.setOverrideField(weekIdx, slot.slotId, 'noteOv', v),
              )
            else if (slot.type == 'TD')
              _TdCourseFields(slot: slot, weekIdx: weekIdx, ov: ov, state: state)
            else
              _LessonCourseFields(slot: slot, weekIdx: weekIdx, ov: ov, state: state),
            if (slot.type != 'R' && slot.auto == null) ...[
              const SizedBox(height: 10),
              _StatusRow(weekIdx: weekIdx, slotId: slot.slotId, ov: ov, state: state),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimePills extends StatelessWidget {
  final String start;
  final String end;
  const _TimePills({required this.start, required this.end});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PillBadge(text: start, color: AppColors.seal),
        const SizedBox(height: 3),
        PillBadge(text: end, color: AppColors.brassSoft, textColor: AppColors.brassDeep),
      ],
    );
  }
}

class _MemoBadge extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _MemoBadge({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: TextFormField(
        initialValue: value,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brassDeep),
        decoration: const InputDecoration(labelText: 'رقم المذكرة', isDense: true),
        onFieldSubmitted: onChanged,
        onEditingComplete: () {},
        onChanged: onChanged,
      ),
    );
  }
}

class _AutoBanner extends StatelessWidget {
  final AutoOverride auto;
  const _AutoBanner({required this.auto});
  @override
  Widget build(BuildContext context) {
    final period = (auto.end.isNotEmpty && auto.end != auto.start)
        ? '${AppState.dispDate(auto.start)} الى ${AppState.dispDate(auto.end)}'
        : AppState.dispDate(auto.start);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.brassSoft, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${kAutoIcon[auto.kind] ?? "⏸"} ${auto.name}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brassDeep, fontSize: 15)),
          const SizedBox(height: 3),
          Text('الفترة: $period${auto.time != null ? " — ${auto.time}" : ""}',
              style: const TextStyle(color: AppColors.brassDeep, fontSize: 12)),
          const SizedBox(height: 3),
          const Text('↪ تُستأنف الحصة تلقائيا بعد هذا التاريخ بنفس الدرس',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 11)),
        ],
      ),
    );
  }
}

class _LessonCourseFields extends StatelessWidget {
  final SlotResult slot;
  final int weekIdx;
  final SlotOverride ov;
  final AppState state;
  const _LessonCourseFields({required this.slot, required this.weekIdx, required this.ov, required this.state});

  String _v(String? ovVal, String? itemVal) => (ovVal != null && ovVal.isNotEmpty) ? ovVal : (itemVal ?? '');

  @override
  Widget build(BuildContext context) {
    final item = slot.item;
    if (item == null && ov.chapitreOv == null && ov.titleOv == null) {
      return const _MissingItemWarning();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('المقطع :', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.sealDeep)),
            const SizedBox(width: 6),
            ColorBadge(text: _v(ov.chapitreNumOv, item?.chapitreNum), size: 26),
            const SizedBox(width: 6),
            Expanded(
              child: _InlineField(
                value: _v(ov.chapitreOv, item?.chapitre),
                onChanged: (v) => state.setOverrideField(weekIdx, slot.slotId, 'chapitreOv', v),
              ),
            ),
          ],
        ),
        _LabeledLine(
          label: 'المورد:',
          value: _v(ov.titleOv, item?.title),
          onChanged: (v) => state.setOverrideField(weekIdx, slot.slotId, 'titleOv', v),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Row(children: [
                const PillBadge(text: 'تطبيق', color: AppColors.seal),
                const SizedBox(width: 5),
                Expanded(
                  child: _InlineField(
                    value: _v(ov.app, item?.app),
                    onChanged: (v) => state.setOverrideField(weekIdx, slot.slotId, 'app', v),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(children: [
                const PillBadge(text: 'واجب منزلي', color: AppColors.brass),
                const SizedBox(width: 5),
                Expanded(
                  child: _InlineField(
                    value: _v(ov.hw, item?.hw),
                    onChanged: (v) => state.setOverrideField(weekIdx, slot.slotId, 'hw', v),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

class _TdCourseFields extends StatelessWidget {
  final SlotResult slot;
  final int weekIdx;
  final SlotOverride ov;
  final AppState state;
  const _TdCourseFields({required this.slot, required this.weekIdx, required this.ov, required this.state});

  String _v(String? ovVal, String? itemVal) => (ovVal != null && ovVal.isNotEmpty) ? ovVal : (itemVal ?? '');

  @override
  Widget build(BuildContext context) {
    final item = slot.item;
    if (item == null && ov.titleOv == null) return const _MissingItemWarning();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('المقطع :', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.sealDeep)),
            const SizedBox(width: 6),
            ColorBadge(text: _v(ov.chapitreNumOv, item?.chapitreNum), color: AppColors.brass),
            const SizedBox(width: 6),
            Expanded(
              child: _InlineField(
                value: _v(ov.chapitreOv, item?.chapitre),
                onChanged: (v) => state.setOverrideField(weekIdx, slot.slotId, 'chapitreOv', v),
              ),
            ),
          ],
        ),
        _LabeledLine(
          label: 'المورد:',
          value: _v(ov.titleOv, item?.title),
          onChanged: (v) => state.setOverrideField(weekIdx, slot.slotId, 'titleOv', v),
        ),
        _LabeledLine(
          label: 'المحتوى:',
          value: _v(ov.contentOv, item?.content),
          onChanged: (v) => state.setOverrideField(weekIdx, slot.slotId, 'contentOv', v),
        ),
      ],
    );
  }
}

class _MissingItemWarning extends StatelessWidget {
  const _MissingItemWarning();
  @override
  Widget build(BuildContext context) {
    return const Text('⚠ لا يوجد عنصر متبقٍ في التوزيع السنوي لهذا القسم',
        style: TextStyle(color: AppColors.dangerDeep, fontSize: 12));
  }
}

class _LabeledLine extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _LabeledLine({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.sealDeep)),
          const SizedBox(width: 6),
          Expanded(child: _InlineField(value: value, onChanged: onChanged)),
        ],
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _NoteField({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => _LabeledLine(label: '$label:', value: value, onChanged: onChanged);
}

class _InlineField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _InlineField({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(value.hashCode.toString() + value.length.toString()),
      initialValue: value,
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
      onChanged: onChanged,
    );
  }
}

class _StatusRow extends StatelessWidget {
  final int weekIdx;
  final String slotId;
  final SlotOverride ov;
  final AppState state;
  const _StatusRow({required this.weekIdx, required this.slotId, required this.ov, required this.state});

  @override
  Widget build(BuildContext context) {
    final status = ov.status ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => state.toggleStatus(weekIdx, slotId, 'done'),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('تم'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: status == 'done' ? AppColors.seal : null,
                  foregroundColor: status == 'done' ? Colors.white : AppColors.seal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => state.toggleStatus(weekIdx, slotId, 'postponed'),
                icon: const Icon(Icons.pause_circle_rounded, size: 18),
                label: const Text('تأجيل'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: status == 'postponed' ? AppColors.danger : null,
                  foregroundColor: status == 'postponed' ? Colors.white : AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ),
          ],
        ),
        if (status == 'postponed') ...[
          const SizedBox(height: 6),
          TextFormField(
            initialValue: ov.postponeReason ?? '',
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(labelText: 'سبب التأجيل', isDense: true),
            onChanged: (v) => state.setOverrideField(weekIdx, slotId, 'postponeReason', v),
          ),
        ],
      ],
    );
  }
}

/// شريط بانر لمناسبة/عطلة/اختبار يمتد على عدة أيام متتالية — يُكتب مرة واحدة بدل تكراره لكل يوم.
class HolidayBanner extends StatelessWidget {
  final AutoOverride auto;
  final String dayRangeLabel;
  const HolidayBanner({super.key, required this.auto, required this.dayRangeLabel});

  @override
  Widget build(BuildContext context) {
    final period = (auto.end.isNotEmpty && auto.end != auto.start)
        ? '${AppState.dispDate(auto.start)} الى ${AppState.dispDate(auto.end)}'
        : AppState.dispDate(auto.start);
    return Card(
      color: AppColors.brassSoft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(kAutoIcon[auto.kind] ?? '⏸', style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(auto.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.brassDeep)),
            const SizedBox(height: 3),
            Text('$dayRangeLabel · $period${auto.time != null ? " — ${auto.time}" : ""}',
                style: const TextStyle(color: AppColors.brassDeep, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
