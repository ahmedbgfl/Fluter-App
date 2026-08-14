import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../file_io.dart';
import '../excel_io.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});
  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  String level = kLevels.first;
  String kind = 'C'; // C | TD

  Future<void> _exportLevel(AppState state) async {
    try {
      await shareCurriculumExcel(state.levelCurriculum(level), level);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر التصدير إلى Excel: $e')),
        );
      }
    }
  }

  Future<void> _importLevel(AppState state) async {
    try {
      final lc = await pickCurriculumExcel();
      if (lc == null) return;
      await state.replaceCurriculumList(level, 'C', lc.c);
      await state.replaceCurriculumList(level, 'TD', lc.td);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم استيراد ${lc.c.length} درسا و${lc.td.length} عملا موجها لمستوى "$level"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذرت قراءة ملف Excel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = kind == 'C' ? state.levelCurriculum(level).c : state.levelCurriculum(level).td;

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'أدخل تسلسل الدروس لكل مستوى بالترتيب الذي ستدرّسه — تُستهلك تلقائيا أسبوعا بعد أسبوع. '
            'اضغط مطولا على أي عنصر لتحريكه أو حذفه.',
            style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
        ),
        Wrap(
          spacing: 6,
          children: [
            for (final lv in kLevels)
              ChoiceChip(
                label: Text(lv),
                selected: level == lv,
                onSelected: (_) => setState(() => level = lv),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'C', label: Text('الدروس')),
            ButtonSegment(value: 'TD', label: Text('الأعمال الموجهة')),
          ],
          selected: {kind},
          onSelectionChanged: (s) => setState(() => kind = s.first),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.file_upload_outlined),
            label: Text('تصدير "$level" (Excel)'),
            onPressed: () => _exportLevel(state),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_open),
            label: const Text('استيراد من ملف Excel'),
            onPressed: () => _importLevel(state),
          ),
        ]),
        const Padding(
          padding: EdgeInsets.only(top: 6, bottom: 4),
          child: Text(
            'الاستيراد يستبدل قوائم الدروس والأعمال الموجهة لهذا المستوى بالكامل بمحتوى ملف Excel. يجب أن يحتوي الملف على ورقتي «الدروس» و«الأعمال الموجهة».',
            style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
          ),
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < list.length; i++)
          _CurriculumRow(
            level: level,
            kind: kind,
            index: i,
            item: list[i],
            isLast: i == list.length - 1,
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('إضافة عنصر في نهاية القائمة'),
          onPressed: () => state.addCurriculumItem(level, kind, CurriculumItem(id: newId())),
        ),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('لا توجد عناصر بعد', style: TextStyle(color: Colors.grey))),
          ),
      ],
    );
  }
}

class _CurriculumRow extends StatelessWidget {
  final String level;
  final String kind;
  final int index;
  final CurriculumItem item;
  final bool isLast;
  const _CurriculumRow({
    required this.level,
    required this.kind,
    required this.index,
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ColorBadge(text: '${index + 1}', color: AppColors.brass, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: _f(context, 'رقم المقطع', item.chapitreNum,
                      (v) => item.chapitreNum = v, small: true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _f(context, 'عنوان المقطع', item.chapitre, (v) => item.chapitre = v),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _f(context, 'المورد', item.title, (v) => item.title = v),
            const SizedBox(height: 6),
            if (kind == 'C')
              Row(
                children: [
                  Expanded(child: _f(context, 'تطبيق', item.app, (v) => item.app = v)),
                  const SizedBox(width: 8),
                  Expanded(child: _f(context, 'واجب منزلي', item.hw, (v) => item.hw = v)),
                ],
              )
            else
              _f(context, 'المحتوى', item.content, (v) => item.content = v),
            const SizedBox(height: 6),
            Row(
              children: [
                SizedBox(width: 100, child: _f(context, 'رقم المذكرة', item.memo, (v) => item.memo = v, small: true)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  onPressed: index == 0 ? null : () => state.moveCurriculumItem(level, kind, index, -1),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  onPressed: isLast ? null : () => state.moveCurriculumItem(level, kind, index, 1),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.seal),
                  tooltip: 'إدراج بعد هذا العنصر',
                  onPressed: () => state.addCurriculumItem(level, kind, CurriculumItem(id: newId()), atIndex: index + 1),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('حذف هذا العنصر؟'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
                        ],
                      ),
                    );
                    if (ok == true) state.removeCurriculumItem(level, kind, index);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _f(BuildContext context, String label, String value, ValueChanged<String> onChanged, {bool small = false}) {
    final state = context.read<AppState>();
    return TextFormField(
      key: ValueKey('$level-$kind-${item.id}-$label'),
      initialValue: value,
      style: TextStyle(fontSize: small ? 12 : 13),
      decoration: InputDecoration(labelText: label, isDense: true),
      onChanged: (v) {
        onChanged(v);
        state.save();
      },
    );
  }
}
