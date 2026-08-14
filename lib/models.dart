// نماذج البيانات — الدفتر اليومي للأستاذ
// كل نموذج يحمل toJson/fromJson لتسهيل الحفظ المحلي والنسخ الاحتياطي.

const List<String> kLevels = ["1 متوسط", "2 متوسط", "3 متوسط", "4 متوسط"];
const List<String> kDays = ["الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس"];

const Map<String, String> kTypeLabel = {"C": "درس", "TD": "أعمال موجهة", "R": "استدراك"};

class TimeSlot {
  final String start;
  final String end;
  final String period; // morning | afternoon
  const TimeSlot(this.start, this.end, this.period);
}

const List<TimeSlot> kSlots = [
  TimeSlot("08:00", "09:00", "morning"),
  TimeSlot("09:00", "10:00", "morning"),
  TimeSlot("10:00", "11:00", "morning"),
  TimeSlot("11:00", "12:00", "morning"),
  TimeSlot("13:30", "14:30", "afternoon"),
  TimeSlot("14:30", "15:30", "afternoon"),
  TimeSlot("15:30", "16:30", "afternoon"),
  TimeSlot("16:30", "17:30", "afternoon"),
];

class SchoolClass {
  String id;
  String level;
  String name;
  SchoolClass({required this.id, required this.level, required this.name});

  factory SchoolClass.fromJson(Map<String, dynamic> j) =>
      SchoolClass(id: j['id'], level: j['level'], name: j['name']);
  Map<String, dynamic> toJson() => {'id': id, 'level': level, 'name': name};
}

class ScheduleEntry {
  String id;
  int day; // 0..4
  String start;
  String end;
  String? classId;
  String type; // C | TD | R
  String? sessionName; // for R (shared استدراك sessions)
  ScheduleEntry({
    required this.id,
    required this.day,
    required this.start,
    required this.end,
    this.classId,
    required this.type,
    this.sessionName,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> j) => ScheduleEntry(
        id: j['id'],
        day: j['day'],
        start: j['start'],
        end: j['end'],
        classId: j['classId'],
        type: j['type'],
        sessionName: j['sessionName'],
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day,
        'start': start,
        'end': end,
        'classId': classId,
        'type': type,
        'sessionName': sessionName,
      };
}

/// عنصر في التوزيع السنوي (دروس) أو المخطط السنوي للأعمال الموجهة (TD).
class CurriculumItem {
  String id;
  String chapitreNum;
  String chapitre;
  String title; // المورد
  String memo; // رقم المذكرة
  String app; // تطبيق (دروس فقط)
  String hw; // واجب منزلي (دروس فقط)
  String content; // المحتوى (TD فقط)

  CurriculumItem({
    required this.id,
    this.chapitreNum = '',
    this.chapitre = '',
    this.title = '',
    this.memo = '',
    this.app = '',
    this.hw = '',
    this.content = '',
  });

  factory CurriculumItem.fromJson(Map<String, dynamic> j) => CurriculumItem(
        id: j['id'],
        chapitreNum: j['chapitreNum'] ?? '',
        chapitre: j['chapitre'] ?? '',
        title: j['title'] ?? '',
        memo: j['memo'] ?? '',
        app: j['app'] ?? '',
        hw: j['hw'] ?? '',
        content: j['content'] ?? '',
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'chapitreNum': chapitreNum,
        'chapitre': chapitre,
        'title': title,
        'memo': memo,
        'app': app,
        'hw': hw,
        'content': content,
      };
}

class LevelCurriculum {
  List<CurriculumItem> c; // الدروس
  List<CurriculumItem> td; // الأعمال الموجهة
  LevelCurriculum({List<CurriculumItem>? c, List<CurriculumItem>? td})
      : c = c ?? [],
        td = td ?? [];

  factory LevelCurriculum.fromJson(Map<String, dynamic> j) => LevelCurriculum(
        c: (j['C'] as List? ?? []).map((e) => CurriculumItem.fromJson(e)).toList(),
        td: (j['TD'] as List? ?? []).map((e) => CurriculumItem.fromJson(e)).toList(),
      );
  Map<String, dynamic> toJson() => {
        'C': c.map((e) => e.toJson()).toList(),
        'TD': td.map((e) => e.toJson()).toList(),
      };
}

class WeekEntry {
  String id;
  String start; // yyyy-MM-dd (Sunday)
  WeekEntry({required this.id, required this.start});
  factory WeekEntry.fromJson(Map<String, dynamic> j) => WeekEntry(id: j['id'], start: j['start']);
  Map<String, dynamic> toJson() => {'id': id, 'start': start};
}

/// تعديل يدوي لخانة أسبوع/حصة معينة — يُحفظ بمفتاح "weekIdx_slotId".
class SlotOverride {
  String? chapitreNumOv, chapitreOv, titleOv, contentOv, memoOv, app, hw, noteOv, status, postponeReason;
  SlotOverride();

  factory SlotOverride.fromJson(Map<String, dynamic> j) => SlotOverride()
    ..chapitreNumOv = j['chapitreNumOv']
    ..chapitreOv = j['chapitreOv']
    ..titleOv = j['titleOv']
    ..contentOv = j['contentOv']
    ..memoOv = j['memoOv']
    ..app = j['app']
    ..hw = j['hw']
    ..noteOv = j['noteOv']
    ..status = j['status']
    ..postponeReason = j['postponeReason'];

  Map<String, dynamic> toJson() => {
        if (chapitreNumOv != null) 'chapitreNumOv': chapitreNumOv,
        if (chapitreOv != null) 'chapitreOv': chapitreOv,
        if (titleOv != null) 'titleOv': titleOv,
        if (contentOv != null) 'contentOv': contentOv,
        if (memoOv != null) 'memoOv': memoOv,
        if (app != null) 'app': app,
        if (hw != null) 'hw': hw,
        if (noteOv != null) 'noteOv': noteOv,
        if (status != null) 'status': status,
        if (postponeReason != null) 'postponeReason': postponeReason,
      };
}

class EventItem {
  String id;
  String start;
  String end;
  String name;
  EventItem({required this.id, required this.start, required this.end, required this.name});
  factory EventItem.fromJson(Map<String, dynamic> j) =>
      EventItem(id: j['id'], start: j['start'], end: j['end'], name: j['name']);
  Map<String, dynamic> toJson() => {'id': id, 'start': start, 'end': end, 'name': name};
}

class HomeworkItem {
  String id;
  String classId;
  String date;
  String time;
  String subject;
  String correctionDate;
  String correctionTime;
  HomeworkItem({
    required this.id,
    required this.classId,
    required this.date,
    this.time = '',
    this.subject = '',
    this.correctionDate = '',
    this.correctionTime = '',
  });
  factory HomeworkItem.fromJson(Map<String, dynamic> j) => HomeworkItem(
        id: j['id'],
        classId: j['classId'],
        date: j['date'],
        time: j['time'] ?? '',
        subject: j['subject'] ?? '',
        correctionDate: j['correctionDate'] ?? '',
        correctionTime: j['correctionTime'] ?? '',
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'classId': classId,
        'date': date,
        'time': time,
        'subject': subject,
        'correctionDate': correctionDate,
        'correctionTime': correctionTime,
      };
}

class ExamTerm {
  String start;
  String end;
  String correctionDate;
  String correctionTime;
  ExamTerm({this.start = '', this.end = '', this.correctionDate = '', this.correctionTime = ''});
  factory ExamTerm.fromJson(Map<String, dynamic> j) => ExamTerm(
        start: j['start'] ?? '',
        end: j['end'] ?? '',
        correctionDate: j['correctionDate'] ?? '',
        correctionTime: j['correctionTime'] ?? '',
      );
  Map<String, dynamic> toJson() =>
      {'start': start, 'end': end, 'correctionDate': correctionDate, 'correctionTime': correctionTime};
}

const Map<String, String> kExamLabel = {
  'T1': 'اختبارات الفصل الأول',
  'T2': 'اختبارات الفصل الثاني',
  'T3': 'اختبارات الفصل الثالث',
};

/// نوع تجاوز تلقائي (عطلة/مناسبة/اختبار/فرض/تصحيح) يمنع استهلاك التوزيع السنوي لتلك الحصة.
class AutoOverride {
  final String kind; // holiday | exam | examCorrection | homework | homeworkCorrection
  final String name;
  final String start;
  final String end;
  final String? time;
  AutoOverride({required this.kind, required this.name, required this.start, required this.end, this.time});

  String get key => '$kind|$name|$start|$end';
}

const Map<String, String> kAutoIcon = {
  'holiday': '🎉',
  'exam': '📚',
  'examCorrection': '📝',
  'homework': '📝',
  'homeworkCorrection': '✅',
};
