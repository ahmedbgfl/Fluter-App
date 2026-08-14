import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'app_state.dart';
import 'models.dart';
import 'day_blocks.dart';

const _sealDeep = PdfColor.fromInt(0xFF0A4A38);
const _brassSoft = PdfColor.fromInt(0xFFF3E9CE);
const _brassDeep = PdfColor.fromInt(0xFF7A5D1E);
const _lineColor = PdfColor.fromInt(0xFFDED4B8);

String _v(String? ov, String? item) => (ov != null && ov.isNotEmpty) ? ov : (item ?? '');

const Map<String, String> _statusLabel = {'done': 'تم', 'postponed': 'تأجيل'};

String _courseCellText(SlotOverride ov, SlotResult s) {
  if (s.auto != null) {
    final a = s.auto!;
    final period = (a.end.isNotEmpty && a.end != a.start)
        ? '${AppState.dispDate(a.start)} إلى ${AppState.dispDate(a.end)}'
        : AppState.dispDate(a.start);
    return '${a.name}\nالفترة: $period${a.time != null ? ' — ${a.time}' : ''}';
  }
  if (s.type == 'R') {
    final note = _v(ov.noteOv, '');
    return 'استدراك\nملاحظة: ${note.isEmpty ? 'استدراك' : note}';
  }
  final item = s.item;
  if (s.type == 'TD') {
    return 'المقطع: (${_v(ov.chapitreNumOv, item?.chapitreNum)}) ${_v(ov.chapitreOv, item?.chapitre)}\n'
        'المورد: ${_v(ov.titleOv, item?.title)}\n'
        'المحتوى: ${_v(ov.contentOv, item?.content)}';
  }
  return 'المقطع: (${_v(ov.chapitreNumOv, item?.chapitreNum)}) ${_v(ov.chapitreOv, item?.chapitre)}\n'
      'المورد: ${_v(ov.titleOv, item?.title)}\n'
      'تطبيق: ${_v(ov.app, item?.app)}    واجب منزلي: ${_v(ov.hw, item?.hw)}';
}

Future<pw.Document> buildWeekPdf(AppState state, int weekIdx) async {
  final regular = await PdfGoogleFonts.tajawalRegular();
  final bold = await PdfGoogleFonts.tajawalBold();
  final displayBold = await PdfGoogleFonts.cairoBold();

  final doc = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));
  final week = state.weeks[weekIdx];
  final blocks = buildDayBlocks(state, weekIdx);

  // ترتيب الأعمدة بصريا من اليمين إلى اليسار:
  // اليوم | التوقيت | القسم | سير الحصة | رقم المذكرة | ملاحظات
  const headers = ['التوقيت', 'القسم', 'سير الحصة', 'رقم المذكرة', 'ملاحظات'];
  const colWidths = <int, pw.TableColumnWidth>{
    0: pw.FixedColumnWidth(48), // ملاحظات
    1: pw.FixedColumnWidth(48), // رقم المذكرة
    2: pw.FlexColumnWidth(),    // سير الحصة
    3: pw.FixedColumnWidth(62), // القسم
    4: pw.FixedColumnWidth(52), // التوقيت
  };

  pw.Widget cell(String text, {bool header = false, PdfColor? bg}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        color: bg ?? (header ? _sealDeep : null),
        border: pw.Border.all(color: _lineColor, width: 0.5),
      ),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          font: header ? bold : regular,
          fontSize: header ? 8.5 : 8,
          color: header ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  pw.TableRow headerRow() => pw.TableRow(
        repeat: true,
        children: [for (final h in headers.reversed) cell(h, header: true)],
      );

  pw.TableRow dataRow(SlotResult s) {
    final ov = state.overrideFor(weekIdx, s.slotId);
    final memo = (s.auto != null || s.type == 'R') ? '' : _v(ov.memoOv, s.item?.memo);
    final notes = s.auto != null ? 'مؤجلة تلقائيا' : (_statusLabel[ov.status] ?? '');
    final values = [
      '${s.start}\n${s.end}',
      s.displayName(),
      _courseCellText(ov, s),
      memo,
      notes,
    ];
    return pw.TableRow(children: [for (final value in values.reversed) cell(value)]);
  }

  final sections = <pw.Widget>[];
  for (final b in blocks) {
    if (b.isHoliday) {
      final a = b.auto!;
      final dayLabel = b.fromDay == b.toDay
          ? kDays[b.fromDay!]
          : '${kDays[b.fromDay!]} — ${kDays[b.toDay!]}';
      final period = (a.end.isNotEmpty && a.end != a.start)
          ? '${AppState.dispDate(a.start)} إلى ${AppState.dispDate(a.end)}'
          : AppState.dispDate(a.start);
      sections.add(
        pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 6),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: _brassSoft,
            border: pw.Border.all(color: _lineColor),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                a.name,
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(font: displayBold, fontSize: 13, color: _brassDeep),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '$dayLabel · $period${a.time != null ? ' — ${a.time}' : ''}',
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(font: regular, fontSize: 9, color: _brassDeep),
              ),
            ],
          ),
        ),
      );
    } else {
      final date = AppState.addDays(week.start, b.day!);
      final dayLabel = '${kDays[b.day!]}\n${AppState.dispDate(date)}';

      // وضعنا خلية اليوم في جدول خارجي واحد مع جدول الحصص الداخلي،
      // فتظهر خلية اليوم مدمجة بصريا على كامل ارتفاع حصص ذلك اليوم.
      final slotsTable = pw.Table(
        columnWidths: colWidths,
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [headerRow(), for (final s in b.slots!) dataRow(s)],
      );

      sections.add(
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(),
            1: pw.FixedColumnWidth(58),
          },
          children: [
            pw.TableRow(
              verticalAlignment: pw.TableCellVerticalAlignment.full,
              children: [
                slotsTable,
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(
                    color: _brassSoft,
                    border: pw.Border.all(color: _lineColor, width: 0.5),
                  ),
                  child: pw.Text(
                    dayLabel,
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(font: bold, fontSize: 9, color: _brassDeep),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      sections.add(pw.SizedBox(height: 5));
    }
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(20, 16, 20, 16),
      textDirection: pw.TextDirection.rtl,
      build: (context) => [
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'الأسبوع $weekIdx — من ${AppState.dispDate(week.start)} إلى ${AppState.dispDate(AppState.addDays(week.start, 4))}',
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(font: displayBold, fontSize: 16, color: _sealDeep),
              ),
              pw.SizedBox(height: 10),
              ...sections,
            ],
          ),
        ),
      ],
    ),
  );

  return doc;
}

Future<void> printWeekPdf(AppState state, int weekIdx) async {
  final doc = await buildWeekPdf(state, weekIdx);
  await Printing.layoutPdf(onLayout: (format) async => doc.save());
}
