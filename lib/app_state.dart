import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

const _storageKey = 'dafter_yawmi_state_v1';
const _uuid = Uuid();
String newId() => _uuid.v4().substring(0, 8);

/// نتيجة حصة واحدة ضمن أسبوع محسوب (بعد تطبيق منطق التوزيع والتأجيل التلقائي).
class SlotResult {
  final String slotId;
  final String? classId;
  final int day;
  final String? date; // yyyy-MM-dd
  final String start;
  final String end;
  final SchoolClass? cls;
  final String type;
  final CurriculumItem? item;
  final String? sessionName;
  final AutoOverride? auto;

  SlotResult({
    required this.slotId,
    this.classId,
    required this.day,
    this.date,
    required this.start,
    required this.end,
    this.cls,
    required this.type,
    this.item,
    this.sessionName,
    this.auto,
  });

  String displayName() {
    if (type == 'R') return sessionName ?? cls?.name ?? 'استدراك';
    return cls?.name ?? '—';
  }
}

class WeekComputation {
  final List<SlotResult> slots;
  final Map<String, Map<String, int>> pointerAfter; // classId -> {C: n, TD: n}
  WeekComputation(this.slots, this.pointerAfter);
}

class AppState extends ChangeNotifier {
  List<SchoolClass> classes = [];
  List<ScheduleEntry> schedule = [];
  Map<String, LevelCurriculum> curriculum = {};
  List<WeekEntry> weeks = [];
  Map<String, SlotOverride> overrides = {};
  List<EventItem> events = [];
  List<HomeworkItem> homeworks = [];
  Map<String, ExamTerm> exams = {
    'T1': ExamTerm(),
    'T2': ExamTerm(),
    'T3': ExamTerm(),
  };

  bool loaded = false;

  AppState() {
    for (final lv in kLevels) {
      curriculum[lv] = LevelCurriculum();
    }
    _load();
  }

  LevelCurriculum levelCurriculum(String level) =>
      curriculum.putIfAbsent(level, () => LevelCurriculum());

  // ---------------- persistence ----------------
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _fromJson(j);
      }
    } catch (_) {
      // لا توجد بيانات محفوظة سابقا، نبدأ بحالة فارغة
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(toJson()));
    } catch (_) {}
    notifyListeners();
  }

  void _fromJson(Map<String, dynamic> j) {
    classes = (j['classes'] as List? ?? []).map((e) => SchoolClass.fromJson(e)).toList();
    schedule = (j['schedule'] as List? ?? []).map((e) => ScheduleEntry.fromJson(e)).toList();
    final curr = j['curriculum'] as Map<String, dynamic>? ?? {};
    curriculum = {for (final lv in kLevels) lv: LevelCurriculum()};
    curr.forEach((k, v) => curriculum[k] = LevelCurriculum.fromJson(v));
    weeks = (j['weeks'] as List? ?? []).map((e) => WeekEntry.fromJson(e)).toList();
    final ov = j['overrides'] as Map<String, dynamic>? ?? {};
    overrides = ov.map((k, v) => MapEntry(k, SlotOverride.fromJson(v)));
    events = (j['events'] as List? ?? []).map((e) => EventItem.fromJson(e)).toList();
    homeworks = (j['homeworks'] as List? ?? []).map((e) => HomeworkItem.fromJson(e)).toList();
    final ex = j['exams'] as Map<String, dynamic>? ?? {};
    for (final t in ['T1', 'T2', 'T3']) {
      exams[t] = ex[t] != null ? ExamTerm.fromJson(ex[t]) : ExamTerm();
    }
  }

  Map<String, dynamic> toJson() => {
        'classes': classes.map((e) => e.toJson()).toList(),
        'schedule': schedule.map((e) => e.toJson()).toList(),
        'curriculum': curriculum.map((k, v) => MapEntry(k, v.toJson())),
        'weeks': weeks.map((e) => e.toJson()).toList(),
        'overrides': overrides.map((k, v) => MapEntry(k, v.toJson())),
        'events': events.map((e) => e.toJson()).toList(),
        'homeworks': homeworks.map((e) => e.toJson()).toList(),
        'exams': exams.map((k, v) => MapEntry(k, v.toJson())),
      };

  void importFromJson(Map<String, dynamic> j) {
    _fromJson(j);
    save();
  }

  // ---------------- date helpers ----------------
  static String fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime parseDate(String s) => DateTime.parse(s);

  static String addDays(String dateStr, int n) {
    final d = DateTime.parse(dateStr).add(Duration(days: n));
    return fmtDate(d);
  }

  static const _arMonths = [
    'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان',
    'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  static String dispDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    final d = DateTime.parse(dateStr);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  // ---------------- overrides / auto-postponement ----------------

  EventItem? findEventForDate(String dateStr) {
    for (final ev in events) {
      if (dateStr.compareTo(ev.start) >= 0 && dateStr.compareTo(ev.end.isEmpty ? ev.start : ev.end) <= 0) {
        return ev;
      }
    }
    return null;
  }

  bool _timeMatches(ScheduleEntry s, String? t) {
    if (t == null || t.isEmpty) return false;
    return t.compareTo(s.start) >= 0 && t.compareTo(s.end) <= 0;
  }

  /// تجاوز على مستوى اليوم كاملا (عطلة/مناسبة/فترة اختبارات/تصحيح اختبار) — يشمل كل الأقسام.
  AutoOverride? wholeDayOverride(String? dateStr) {
    if (dateStr == null) return null;
    final ev = findEventForDate(dateStr);
    if (ev != null) {
      return AutoOverride(kind: 'holiday', name: ev.name, start: ev.start, end: ev.end);
    }
    for (final t in ['T1', 'T2', 'T3']) {
      final ex = exams[t]!;
      if (ex.start.isNotEmpty &&
          ex.end.isNotEmpty &&
          dateStr.compareTo(ex.start) >= 0 &&
          dateStr.compareTo(ex.end) <= 0) {
        return AutoOverride(kind: 'exam', name: kExamLabel[t]!, start: ex.start, end: ex.end);
      }
      if (ex.correctionDate == dateStr) {
        return AutoOverride(
          kind: 'examCorrection',
          name: 'تصحيح ${kExamLabel[t]!}',
          start: ex.correctionDate,
          end: ex.correctionDate,
          time: ex.correctionTime,
        );
      }
    }
    return null;
  }

  /// تجاوز خاص بحصة معينة (مناسبة/اختبار عام، أو فرض/تصحيح خاص بقسم هذه الحصة).
  AutoOverride? dayOverrideFor(String? dateStr, ScheduleEntry s) {
    if (dateStr == null) return null;
    final whole = wholeDayOverride(dateStr);
    if (whole != null) return whole;
    if ((s.type == 'C' || s.type == 'TD') && s.classId != null) {
      for (final h in homeworks) {
        if (h.classId == s.classId && h.date == dateStr && _timeMatches(s, h.time)) {
          return AutoOverride(
            kind: 'homework',
            name: 'فرض${h.subject.isNotEmpty ? ": ${h.subject}" : ""}',
            start: h.date,
            end: h.date,
            time: h.time,
          );
        }
        if (h.classId == s.classId && h.correctionDate == dateStr && _timeMatches(s, h.correctionTime)) {
          return AutoOverride(
            kind: 'homeworkCorrection',
            name: 'تصحيح فرض${h.subject.isNotEmpty ? ": ${h.subject}" : ""}',
            start: h.correctionDate,
            end: h.correctionDate,
            time: h.correctionTime,
          );
        }
      }
    }
    return null;
  }

  // ---------------- weekly plan generation ----------------

  List<ScheduleEntry> get _sortedSchedule {
    final s = List<ScheduleEntry>.from(schedule);
    s.sort((a, b) {
      final c = a.day.compareTo(b.day);
      return c != 0 ? c : a.start.compareTo(b.start);
    });
    return s;
  }

  /// يحسب خطة أسبوع معين: يوزّع عناصر التوزيع السنوي على حصص الأسبوع بحسب مؤشر تقدم كل قسم،
  /// متجاوزا أي حصة أُجِّلت يدويا أو تلقائيا (عطلة/اختبار/فرض) دون استهلاك عنصر منها.
  WeekComputation computePlanForWeek(int weekIdx) {
    final sorted = _sortedSchedule;
    final pointer = <String, Map<String, int>>{};
    for (final c in classes) {
      pointer[c.id] = {'C': 0, 'TD': 0};
    }

    for (var w = 0; w < weekIdx; w++) {
      if (w >= weeks.length) break;
      final wk = weeks[w];
      for (final s in sorted) {
        if (s.type == 'C' || s.type == 'TD') {
          final dateStr = addDays(wk.start, s.day);
          if (dayOverrideFor(dateStr, s) != null) continue;
          final ov = overrides['${w}_${s.id}'];
          if (ov?.status == 'postponed') continue;
          pointer.putIfAbsent(s.classId ?? '', () => {'C': 0, 'TD': 0});
          final p = pointer[s.classId]!;
          p[s.type] = (p[s.type] ?? 0) + 1;
        }
      }
    }

    final week = weekIdx < weeks.length ? weeks[weekIdx] : null;
    final result = <SlotResult>[];
    for (final s in sorted) {
      SchoolClass? cls;
      if (s.type == 'R') {
        cls = s.classId != null ? classes.where((c) => c.id == s.classId).firstOrNull : null;
      } else {
        cls = classes.where((c) => c.id == s.classId).firstOrNull;
        if (cls == null) continue;
      }
      final dateStr = week != null ? addDays(week.start, s.day) : null;
      final auto = dayOverrideFor(dateStr, s);
      CurriculumItem? item;
      if (auto == null && (s.type == 'C' || s.type == 'TD')) {
        final list = s.type == 'C' ? levelCurriculum(cls!.level).c : levelCurriculum(cls!.level).td;
        final idx = pointer[s.classId]![s.type]!;
        item = idx < list.length ? list[idx] : null;
        pointer[s.classId]![s.type] = idx + 1;
      }
      result.add(SlotResult(
        slotId: s.id,
        classId: s.classId,
        day: s.day,
        date: dateStr,
        start: s.start,
        end: s.end,
        cls: cls,
        type: s.type,
        item: item,
        sessionName: s.sessionName,
        auto: auto,
      ));
    }
    return WeekComputation(result, pointer);
  }

  /// يبحث عن الأسبوع/اليوم اللذين يقع فيهما تاريخ تقويمي معيّن.
  ({int weekIdx, int day})? findWeekAndDayForDate(String dateStr) {
    for (var wi = 0; wi < weeks.length; wi++) {
      for (var di = 0; di < 5; di++) {
        if (addDays(weeks[wi].start, di) == dateStr) return (weekIdx: wi, day: di);
      }
    }
    return null;
  }

  // ---------------- mutation helpers (all persist + notify) ----------------

  Future<void> addClass(String level, String name) async {
    classes.add(SchoolClass(id: newId(), level: level, name: name));
    await save();
  }

  Future<void> removeClass(String id) async {
    classes.removeWhere((c) => c.id == id);
    schedule.removeWhere((s) => s.classId == id);
    await save();
  }

  Future<void> upsertScheduleEntry(ScheduleEntry entry, {String? replaceId}) async {
    if (replaceId != null) schedule.removeWhere((s) => s.id == replaceId);
    schedule.add(entry);
    await save();
  }

  Future<void> removeScheduleEntry(String id) async {
    schedule.removeWhere((s) => s.id == id);
    await save();
  }

  Future<void> addCurriculumItem(String level, String kind, CurriculumItem item, {int? atIndex}) async {
    final list = kind == 'C' ? levelCurriculum(level).c : levelCurriculum(level).td;
    if (atIndex != null) {
      list.insert(atIndex, item);
    } else {
      list.add(item);
    }
    await save();
  }

  Future<void> removeCurriculumItem(String level, String kind, int index) async {
    final list = kind == 'C' ? levelCurriculum(level).c : levelCurriculum(level).td;
    list.removeAt(index);
    await save();
  }

  Future<void> moveCurriculumItem(String level, String kind, int index, int delta) async {
    final list = kind == 'C' ? levelCurriculum(level).c : levelCurriculum(level).td;
    final target = index + delta;
    if (target < 0 || target >= list.length) return;
    final tmp = list[index];
    list[index] = list[target];
    list[target] = tmp;
    await save();
  }

  Future<void> replaceCurriculumList(String level, String kind, List<CurriculumItem> items) async {
    if (kind == 'C') {
      levelCurriculum(level).c = items;
    } else {
      levelCurriculum(level).td = items;
    }
    await save();
  }

  Future<void> generateWeeks(String startDate, int count) async {
    var d = DateTime.parse(startDate);
    final dow = d.weekday % 7; // Sunday=0 in JS terms; DateTime.weekday: Mon=1..Sun=7
    final sundayOffset = d.weekday == DateTime.sunday ? 0 : -(d.weekday % 7);
    d = d.add(Duration(days: sundayOffset));
    weeks = List.generate(
      count,
      (i) => WeekEntry(id: newId(), start: fmtDate(d.add(Duration(days: i * 7)))),
    );
    await save();
  }

  Future<void> addWeekAtEnd() async {
    final start = weeks.isNotEmpty ? addDays(weeks.last.start, 7) : fmtDate(DateTime.now());
    weeks.add(WeekEntry(id: newId(), start: start));
    await save();
  }

  Future<void> removeWeek(int index) async {
    weeks.removeAt(index);
    await save();
  }

  SlotOverride overrideFor(int weekIdx, String slotId) =>
      overrides.putIfAbsent('${weekIdx}_$slotId', () => SlotOverride());

  Future<void> setOverrideField(int weekIdx, String slotId, String field, String value) async {
    final ov = overrideFor(weekIdx, slotId);
    switch (field) {
      case 'chapitreNumOv': ov.chapitreNumOv = value; break;
      case 'chapitreOv': ov.chapitreOv = value; break;
      case 'titleOv': ov.titleOv = value; break;
      case 'contentOv': ov.contentOv = value; break;
      case 'memoOv': ov.memoOv = value; break;
      case 'app': ov.app = value; break;
      case 'hw': ov.hw = value; break;
      case 'noteOv': ov.noteOv = value; break;
      case 'postponeReason': ov.postponeReason = value; break;
    }
    await save();
  }

  Future<void> toggleStatus(int weekIdx, String slotId, String status) async {
    final ov = overrideFor(weekIdx, slotId);
    ov.status = ov.status == status ? '' : status;
    await save();
  }

  Future<void> addEvent(String start, String end, String name) async {
    events.add(EventItem(id: newId(), start: start, end: end.isEmpty ? start : end, name: name));
    await save();
  }

  Future<void> removeEvent(String id) async {
    events.removeWhere((e) => e.id == id);
    await save();
  }

  Future<void> addHomework(HomeworkItem hw) async {
    homeworks.add(hw);
    await save();
  }

  Future<void> removeHomework(String id) async {
    homeworks.removeWhere((h) => h.id == id);
    await save();
  }

  Future<void> updateExamTerm(String term, ExamTerm value) async {
    exams[term] = value;
    await save();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
