import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../file_io.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  Future<void> _showExportDialog(BuildContext context, AppState state) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(state.toJson());
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('نسخة JSON من بياناتك'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: SingleChildScrollView(child: SelectableText(jsonStr, style: const TextStyle(fontSize: 11))),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('نسخ إلى الحافظة'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ')));
            },
          ),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  Future<void> _shareAsFile(BuildContext context, AppState state) async {
    try {
      await shareJsonFile(state.toJson(), 'dafter-yawmi-backup-${AppState.fmtDate(DateTime.now())}.json');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذرت المشاركة: $e')));
      }
    }
  }

  Future<void> _importFromFile(BuildContext context, AppState state) async {
    try {
      final content = await pickJsonFileContent();
      if (content == null) return; // المستخدم ألغى الاختيار
      final j = jsonDecode(content) as Map<String, dynamic>;
      state.importFromJson(j);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الاستيراد بنجاح')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذرت قراءة الملف: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الحفظ التلقائي', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text(
                  'جميع بياناتك تُحفظ تلقائيا وبشكل دائم على الجهاز (بعد كل تعديل)، ولا حاجة لأي إجراء يدوي.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نسخة احتياطية يدوية', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('احتفظ بنسخة من بياناتك أو انقلها لجهاز آخر عبر ملف JSON.', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('عرض / نسخ JSON'),
                    onPressed: () => _showExportDialog(context, state),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة كملف'),
                    onPressed: () => _shareAsFile(context, state),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('استيراد من ملف JSON'),
                    onPressed: () => _importFromFile(context, state),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
