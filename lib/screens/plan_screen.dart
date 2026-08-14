import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../day_blocks.dart';
import '../pdf_export.dart';
import '../widgets/slot_tile.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});
  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  int weekIdx = 0;
  bool printing = false;

  Future<void> _print(AppState state) async {
    setState(() => printing = true);
    try {
      await printWeekPdf(state, weekIdx);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذرت الطباعة: $e')));
      }
    } finally {
      if (mounted) setState(() => printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.weeks.isEmpty) {
      return const Center(child: Text('أضف الأسابيع الدراسية أولا من تبويب "الأسابيع الدراسية"'));
    }
    if (state.schedule.isEmpty) {
      return const Center(child: Text('أضف التوقيت الأسبوعي أولا'));
    }
    weekIdx = weekIdx.clamp(0, state.weeks.length - 1);
    final week = state.weeks[weekIdx];
    final comp = state.computePlanForWeek(weekIdx);
    final blocks = buildDayBlocks(state, weekIdx);

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                IconButton(
                  onPressed: weekIdx > 0 ? () => setState(() => weekIdx--) : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  tooltip: 'الأسبوع السابق',
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('الأسبوع $weekIdx',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sealDeep, fontSize: 16)),
                      Text(
                        '${AppState.dispDate(week.start)} الى ${AppState.dispDate(AppState.addDays(week.start, 4))}',
                        style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: printing ? null : () => _print(state),
                  icon: printing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.print_rounded),
                  tooltip: 'طباعة',
                ),
                IconButton(
                  onPressed: weekIdx < state.weeks.length - 1 ? () => setState(() => weekIdx++) : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'الأسبوع التالي',
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.classes.map((c) {
              final p = comp.pointerAfter[c.id] ?? {'C': 0, 'TD': 0};
              final cLen = state.levelCurriculum(c.level).c.length;
              final tdLen = state.levelCurriculum(c.level).td.length;
              return Chip(label: Text('${c.name}: الدرس ${p['C']}/$cLen — TD ${p['TD']}/$tdLen'));
            }).toList(),
          ),
        ),
        for (final b in blocks) ...[
          if (b.isHoliday)
            HolidayBanner(
              auto: b.auto!,
              dayRangeLabel: b.fromDay == b.toDay ? kDays[b.fromDay!] : '${kDays[b.fromDay!]} — ${kDays[b.toDay!]}',
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Divider(color: AppColors.brass.withOpacity(0.4))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(kDays[b.day!],
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sealDeep)),
                  ),
                  Expanded(child: Divider(color: AppColors.brass.withOpacity(0.4))),
                ],
              ),
            ),
            for (final s in b.slots!) SlotTile(slot: s, weekIdx: weekIdx),
          ],
        ],
      ],
    );
  }
}

