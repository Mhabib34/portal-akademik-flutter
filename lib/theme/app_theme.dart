import 'package:flutter/material.dart';

// ============================================================
// app_theme.dart — Tema Biru & Putih Portal Akademik
// ============================================================

// --- Warna ---
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF1565C0); // biru tua
  static const Color primaryMed = Color(0xFF1976D2); // biru medium
  static const Color primaryLight = Color(0xFFE3F2FD); // biru muda / bg

  // Surface & Background
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFE3F2FD);
  static const Color surfaceGrey = Color(0xFFF5F5F5);

  // Text
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMedium = Color(0xFF37474F);
  static const Color textLight = Color(0xFF78909C);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color danger = Color(0xFFC62828);
  static const Color dangerLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFE65100);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF0277BD);
  static const Color infoLight = Color(0xFFE1F5FE);

  // Border & Divider
  static const Color border = Color(0xFFBBDEFB);
  static const Color divider = Color(0xFFE0E0E0);
}

// --- Text Styles ---
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textMedium,
    letterSpacing: 0.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textMedium,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.8,
  );
}

// --- Dekorasi ---
class AppDecorations {
  AppDecorations._();

  // Card standar
  static BoxDecoration card({Color? color}) => BoxDecoration(
    color: color ?? AppColors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border.withOpacity(0.6)),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.07),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Card dengan aksen biru
  static BoxDecoration primaryCard = BoxDecoration(
    gradient: const LinearGradient(
      colors: [AppColors.primary, AppColors.primaryMed],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Input decoration
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: AppColors.primaryMed, size: 20)
        : null,
    suffixIcon: suffixIcon,
    labelStyle: const TextStyle(color: AppColors.primaryMed, fontSize: 14),
    hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.danger, width: 2),
    ),
  );
}

// --- ThemeData Utama ---
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.primaryMed,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.textDark,
      background: AppColors.background,
      onBackground: AppColors.textDark,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 2,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.white),
      actionsIconTheme: IconThemeData(color: AppColors.white),
    ),

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: AppTextStyles.buttonText,
        elevation: 2,
      ),
    ),

    // TextButton
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // OutlinedButton
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(double.infinity, 48),
      ),
    ),

    // Card
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 2,
      shadowColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryLight,
      labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 4,
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textDark,
      contentTextStyle: const TextStyle(color: AppColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
