import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// يكتب JSON إلى ملف مؤقت ويفتح قائمة المشاركة/الحفظ الخاصة بنظام أندرويد
/// (تسمح للمستخدم بحفظه في أي مكان: التخزين، درايف، إلخ).
Future<void> shareJsonFile(Map<String, dynamic> data, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: fileName));
}

/// يفتح منتقي الملفات الأصلي لنظام أندرويد ليختار المستخدم ملف JSON فعليا من جهازه،
/// ثم يُرجع محتواه كنص (أو null إذا ألغى المستخدم أو تعذرت القراءة).
Future<String?> pickJsonFileContent() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.isEmpty) return null;
  final path = result.files.single.path;
  if (path == null) return null;
  final file = File(path);
  return file.readAsString();
}
