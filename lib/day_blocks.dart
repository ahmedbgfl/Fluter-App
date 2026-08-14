import 'app_state.dart';
import 'models.dart';

/// يمثّل إما يومًا دراسيا عاديا بحصصه، أو مجموعة أيام متتالية دُمجت لأنها تخضع
/// لنفس التجاوز الكلي (عطلة/مناسبة/فترة اختبار) — لتُكتب مرة واحدة بدل تكرارها.
class DayBlock {
  final bool isHoliday;
  final int? day;
  final List<SlotResult>? slots;
  final int? fromDay;
  final int? toDay;
  final AutoOverride? auto;

  DayBlock.normal({required this.day, required this.slots})
      : isHoliday = false,
        fromDay = null,
        toDay = null,
        auto = null;

  DayBlock.holiday({required this.fromDay, required this.toDay, required this.auto})
      : isHoliday = true,
        day = null,
        slots = null;
}

List<DayBlock> buildDayBlocks(AppState state, int weekIdx) {
  final week = state.weeks[weekIdx];
  final comp = state.computePlanForWeek(weekIdx);

  final byDay = <int, List<SlotResult>>{for (var i = 0; i < 5; i++) i: []};
  for (final s in comp.slots) {
    byDay[s.day]!.add(s);
  }
  for (final list in byDay.values) {
    list.sort((a, b) => a.start.compareTo(b.start));
  }

  final blocks = <DayBlock>[];
  var i = 0;
  while (i < 5) {
    final date = AppState.addDays(week.start, i);
    final whole = state.wholeDayOverride(date);
    if (whole != null) {
      var j = i;
      while (j + 1 < 5) {
        final nextDate = AppState.addDays(week.start, j + 1);
        final nextWhole = state.wholeDayOverride(nextDate);
        if (nextWhole != null && nextWhole.key == whole.key) {
          j++;
        } else {
          break;
        }
      }
      blocks.add(DayBlock.holiday(fromDay: i, toDay: j, auto: whole));
      i = j + 1;
    } else {
      if (byDay[i]!.isNotEmpty) blocks.add(DayBlock.normal(day: i, slots: byDay[i]!));
      i++;
    }
  }
  return blocks;
}
