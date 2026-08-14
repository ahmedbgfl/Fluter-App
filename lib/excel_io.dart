import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'models.dart';

/// تصدير التوزيع السنوي للمستوى إلى Excel.
/// يتم وضع الدروس والأعمال الموجهة في ورقتين منفصلتين داخل نفس الملف.
Future<void> shareCurriculumExcel(LevelCurriculum curriculum, String level) async {
  final workbook = Excel.createExcel();

  final lessons = workbook['الدروس'];
  final td = workbook['الأعمال الموجهة'];

  final headers = ['الترتيب', 'رقم المقطع', 'عنوان المقطع', 'المورد', 'رقم المذكرة', 'تطبيق', 'واجب منزلي', 'المحتوى'];

  void setupSheet(Sheet sheet, List<CurriculumItem> items, {required bool isTd}) {
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
      );
    }

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final values = [
        i + 1,
        item.chapitreNum,
        item.chapitre,
        item.title,
        item.memo,
        isTd ? '' : item.app,
        isTd ? '' : item.hw,
        isTd ? item.content : '',
      ];
      for (var c = 0; c < values.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1));
        cell.value = c == 0
            ? IntCellValue(values[c] as int)
            : TextCellValue(values[c] as String);
        cell.cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
          textWrapping: TextWrapping.WrapText,
        );
      }
    }

    final widths = <int, double>{
      0: 10, 1: 14, 2: 28, 3: 38, 4: 14, 5: 28, 6: 28, 7: 38,
    };
    widths.forEach((column, width) => sheet.setColumnWidth(column, width));
  }

  setupSheet(lessons, curriculum.c, isTd: false);
  setupSheet(td, curriculum.td, isTd: true);
  workbook.delete('Sheet1');

  final bytes = workbook.save();
  if (bytes == null) throw Exception('تعذر إنشاء ملف Excel');

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/التوزيع_السنوي_$level.xlsx');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: file.path.split('/').last));
}

/// استيراد التوزيع السنوي من Excel.
/// يتوقع ورقتين باسم «الدروس» و«الأعمال الموجهة»، مع صف أول للعناوين.
Future<LevelCurriculum?> pickCurriculumExcel() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    allowMultiple: false,
    withData: false,
  );
  if (result == null || result.files.isEmpty) return null;

  final picked = result.files.single;
  final path = picked.path;
  if (path == null) return null;

  final bytes = await File(path).readAsBytes();
  final workbook = Excel.decodeBytes(bytes);

  List<CurriculumItem> readSheet(String name, {required bool isTd}) {
    final sheet = workbook.tables[name];
    if (sheet == null) return [];

    final result = <CurriculumItem>[];
    for (var r = 1; r < sheet.maxRows; r++) {
      final row = sheet.rows[r];
      String valueAt(int index) {
        if (index >= row.length || row[index] == null) return '';
        final value = row[index]!.value;
        switch (value) {
          case TextCellValue():
            return value.value.text ?? '';
          case IntCellValue():
            return value.value.toString();
          case DoubleCellValue():
            return value.value.toString();
          case BoolCellValue():
            return value.value ? 'نعم' : 'لا';
          case DateCellValue():
            return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
          case DateTimeCellValue():
            return value.asDateTimeLocal().toString();
          case TimeCellValue():
            return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
          case FormulaCellValue():
            return value.formula;
          case null:
            return '';
        }
      }

      final values = List.generate(8, valueAt);
      if (values.every((v) => v.trim().isEmpty)) continue;

      result.add(CurriculumItem(
        id: newIdForImport(),
        chapitreNum: values[1],
        chapitre: values[2],
        title: values[3],
        memo: values[4],
        app: isTd ? '' : values[5],
        hw: isTd ? '' : values[6],
        content: isTd ? values[7] : '',
      ));
    }
    return result;
  }

  return LevelCurriculum(
    c: readSheet('الدروس', isTd: false),
    td: readSheet('الأعمال الموجهة', isTd: true),
  );
}

String newIdForImport() => DateTime.now().microsecondsSinceEpoch.toString();
