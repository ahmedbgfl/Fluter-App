import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// نفس الهوية البصرية المعتمدة في نسخة الويب: أخضر "الختم" أساسيا، وذهبي نحاسي للأرقام والتمييز.
class AppColors {
  static const seal = Color(0xFF0E6B4F);
  static const sealDeep = Color(0xFF0A4A38);
  static const sealSoft = Color(0xFFE2EFE7);
  static const brass = Color(0xFFA9812E);
  static const brassDeep = Color(0xFF7A5D1E);
  static const brassSoft = Color(0xFFF3E9CE);
  static const danger = Color(0xFFA6402B);
  static const dangerDeep = Color(0xFF7A2E1D);
  static const dangerSoft = Color(0xFFF4E1D8);
  static const paper = Color(0xFFF4F0E3);
  static const card = Color(0xFFFFFEFA);
  static const ink = Color(0xFF22281F);
  static const inkSoft = Color(0xFF5B5F4F);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.seal,
      primary: AppColors.seal,
      secondary: AppColors.brass,
      error: AppColors.danger,
      surface: AppColors.card,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.paper,
  );

  final bodyFont = GoogleFonts.tajawalTextTheme(base.textTheme);
  final displayFont = GoogleFonts.cairoTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: bodyFont.copyWith(
      headlineSmall: displayFont.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.sealDeep),
      titleLarge: displayFont.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.sealDeep),
      titleMedium: displayFont.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.sealDeep,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: displayFont.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.brass.withOpacity(0.18)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.sealSoft,
      labelStyle: const TextStyle(color: AppColors.sealDeep, fontWeight: FontWeight.w700),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.seal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.sealDeep,
        side: const BorderSide(color: AppColors.seal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.brass.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.seal, width: 2),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.card,
      selectedIconTheme: const IconThemeData(color: AppColors.seal),
      selectedLabelTextStyle: const TextStyle(color: AppColors.sealDeep, fontWeight: FontWeight.w700),
    ),
    dividerColor: AppColors.brass.withOpacity(0.25),
  );
}

/// شارة مستديرة ملوّنة (تُستخدم لرقم المقطع، ونوع الحصة، وغيرها).
class ColorBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final double size;
  const ColorBadge({super.key, required this.text, this.color = AppColors.seal, this.textColor = Colors.white, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: size * 0.42)),
    );
  }
}

/// شريط/شارة نصية دائرية الحواف (لتصنيف نوع الحصة، أو تسمية حقل مثل "تطبيق").
class PillBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const PillBadge({super.key, required this.text, this.color = AppColors.seal, this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}
