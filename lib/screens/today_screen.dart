import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/slot_tile.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  int offset = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.weeks.isEmpty || state.schedule.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('أضف التوقيت الأسبوعي والأسابيع الدراسية أولا', textAlign: TextAlign.center),
        ),
      );
    }

    final baseToday = AppState.fmtDate(DateTime.now());
    final selDate = AppState.addDays(baseToday, offset);
    final relLabel = offset == 0
        ? '📍 اليوم'
        : offset == -1
            ? '🔙 أمس'
            : offset == 1
                ? '🔜 غدا'
                : (offset < 0 ? 'قبل ${-offset} أيام' : 'بعد $offset أيام');

    final found = state.findWeekAndDayForDate(selDate);
    final selHw = state.homeworks.where((h) => h.date == selDate || h.correctionDate == selDate).toList();

    return ListView(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.sealDeep, AppColors.seal]),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
            child: Row(
              children: [
                _NavArrow(icon: Icons.arrow_forward_rounded, onTap: () => setState(() => offset--)),
                Expanded(
                  child: Column(
                    children: [
                      Text(relLabel,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(AppState.dispDate(selDate),
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                _NavArrow(icon: Icons.arrow_back_rounded, onTap: () => setState(() => offset++)),
              ],
            ),
          ),
        ),
        if (selHw.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selHw.map((h) {
                final cls = state.classes.where((c) => c.id == h.classId).firstOrNull;
                final isCorrection = h.correctionDate == selDate && h.date != selDate;
                final label = isCorrection ? h.correctionTime : h.time;
                return Chip(
                  avatar: Text(isCorrection ? '✅' : '📝'),
                  label: Text('${cls?.name ?? ""}${label.isNotEmpty ? " — $label" : ""}'
                      '${h.subject.isNotEmpty ? " — ${h.subject}" : ""}'),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 4),
        if (found == null)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('لا توجد بيانات لهذا اليوم (خارج أيام الدراسة أو خارج الأسابيع المدرجة)',
                textAlign: TextAlign.center),
          )
        else
          _DayBody(weekIdx: found.weekIdx, day: found.day, dateStr: selDate),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.16),
        side: BorderSide(color: Colors.white.withOpacity(0.4)),
        shape: const CircleBorder(),
      ),
    );
  }
}

class _DayBody extends StatelessWidget {
  final int weekIdx;
  final int day;
  final String dateStr;
  const _DayBody({required this.weekIdx, required this.day, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final whole = state.wholeDayOverride(dateStr);
    if (whole != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: HolidayBanner(auto: whole, dayRangeLabel: kDays[day]),
      );
    }
    final comp = state.computePlanForWeek(weekIdx);
    final daySlots = comp.slots.where((s) => s.day == day).toList()..sort((a, b) => a.start.compareTo(b.start));
    if (daySlots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text('لا توجد حصص (${kDays[day]})', textAlign: TextAlign.center),
      );
    }
    return Column(
      children: [for (final s in daySlots) SlotTile(slot: s, weekIdx: weekIdx)],
    );
  }
}

extension _FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
