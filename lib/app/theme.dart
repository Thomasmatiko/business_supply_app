import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF1565C0);
  static const Color secondaryColor = Color(0xFF42A5F5);

  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color surfaceColor = Colors.white;

  static const Color textPrimaryColor = Color(0xFF1F2937);
  static const Color textSecondaryColor = Color(0xFF6B7280);

  static const Color successColor = Color(0xFF16A34A);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFDC2626);

  static const Color dividerColor = Color(0xFFE5E7EB);
  static const Color disabledColor = Color(0xFF9CA3AF);

  static const Color navigationIndicatorColor = Color(0xFFDCEBFA);

  // ============================================================
  // DARK COLORS
  // ============================================================

  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkDividerColor = Color(0xFF333333);
  static const Color darkSecondaryTextColor = Color(0xFFBDBDBD);

  // ============================================================
  // BORDER RADIUS
  // ============================================================

  static const double smallRadius = 8;
  static const double mediumRadius = 12;
  static const double largeRadius = 16;
  static const double extraLargeRadius = 20;

  // ============================================================
  // LIGHT THEME
  // ============================================================

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
    ),

    scaffoldBackgroundColor: backgroundColor,

    visualDensity: VisualDensity.adaptivePlatformDensity,

    // ==========================================================
    // APP BAR
    // ==========================================================

    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimaryColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
    ),

    // ==========================================================
    // CARD
    // ==========================================================

    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(largeRadius),
      ),
    ),

    // ==========================================================
    // INPUT
    // ==========================================================

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,

      hintStyle: const TextStyle(
        color: textSecondaryColor,
        fontSize: 14,
      ),

      labelStyle: const TextStyle(
        color: textSecondaryColor,
        fontSize: 14,
      ),

      prefixIconColor: textSecondaryColor,
      suffixIconColor: textSecondaryColor,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: const BorderSide(
          color: errorColor,
          width: 1,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: const BorderSide(
          color: errorColor,
          width: 2,
        ),
      ),

      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: BorderSide.none,
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),

    // ==========================================================
    // ELEVATED BUTTON
    // ==========================================================

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ==========================================================
    // OUTLINED BUTTON
    // ==========================================================

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        side: const BorderSide(
          color: primaryColor,
          width: 1.2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ==========================================================
    // TEXT BUTTON
    // ==========================================================

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(smallRadius),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ==========================================================
    // NAVIGATION BAR
    // ==========================================================

    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: surfaceColor,
      indicatorColor: navigationIndicatorColor,
      elevation: 0,
      height: 72,

      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
      ),

      iconTheme: WidgetStatePropertyAll(
        IconThemeData(
          size: 24,
        ),
      ),
    ),

    // ==========================================================
    // FLOATING ACTION BUTTON
    // ==========================================================

    floatingActionButtonTheme:
        const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
    ),

    // ==========================================================
    // DIALOG
    // ==========================================================

    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(largeRadius),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: textSecondaryColor,
        height: 1.4,
      ),
    ),

    // ==========================================================
    // BOTTOM SHEET
    // ==========================================================

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      showDragHandle: true,
    ),

    // ==========================================================
    // DIVIDER
    // ==========================================================

    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 1,
    ),

    // ==========================================================
    // CHIP
    // ==========================================================

    chipTheme: ChipThemeData(
      backgroundColor: backgroundColor,
      selectedColor: navigationIndicatorColor,
      disabledColor: backgroundColor,

      side: const BorderSide(
        color: dividerColor,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
      ),

      labelStyle: const TextStyle(
        fontSize: 13,
        color: textPrimaryColor,
        fontWeight: FontWeight.w500,
      ),

      secondaryLabelStyle: const TextStyle(
        fontSize: 13,
        color: textSecondaryColor,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
    ),

    // ==========================================================
    // CHECKBOX
    // ==========================================================

    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),

      side: const BorderSide(
        color: textSecondaryColor,
        width: 1.5,
      ),

      fillColor:
          WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }

          return Colors.transparent;
        },
      ),
    ),

    // ==========================================================
    // SWITCH
    // ==========================================================

    switchTheme: SwitchThemeData(
      thumbColor:
          WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }

          return Colors.white;
        },
      ),

      trackColor:
          WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return navigationIndicatorColor;
          }

          return dividerColor;
        },
      ),
    ),

    // ==========================================================
    // PROGRESS
    // ==========================================================

    progressIndicatorTheme:
        const ProgressIndicatorThemeData(
      color: primaryColor,
    ),

    // ==========================================================
    // SNACKBAR
    // ==========================================================

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: textPrimaryColor,
      elevation: 4,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
      ),

      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
    ),

    // ==========================================================
    // TOOLTIP
    // ==========================================================

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: textPrimaryColor,
        borderRadius: BorderRadius.circular(smallRadius),
      ),

      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
    ),

    // ==========================================================
    // TEXT THEME
    // ==========================================================

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        height: 1.2,
      ),

      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        height: 1.2,
      ),

      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        height: 1.25,
      ),

      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),

      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),

      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),

      bodyLarge: TextStyle(
        fontSize: 16,
        color: textPrimaryColor,
        height: 1.4,
      ),

      bodyMedium: TextStyle(
        fontSize: 14,
        color: textSecondaryColor,
        height: 1.4,
      ),

      bodySmall: TextStyle(
        fontSize: 12,
        color: textSecondaryColor,
        height: 1.3,
      ),

      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),

      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
      ),

      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
      ),
    ),
  );

  // ============================================================
  // DARK THEME
  // ============================================================

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: secondaryColor,
      secondary: primaryColor,
      surface: darkSurfaceColor,
      error: errorColor,
    ),

    scaffoldBackgroundColor: darkBackgroundColor,

    visualDensity: VisualDensity.adaptivePlatformDensity,

    // ==========================================================
    // APP BAR
    // ==========================================================

    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurfaceColor,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,

      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    // ==========================================================
    // CARD
    // ==========================================================

    cardTheme: CardThemeData(
      color: darkSurfaceColor,
      elevation: 0,
      margin: EdgeInsets.zero,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(largeRadius),
      ),
    ),

    // ==========================================================
    // INPUT
    // ==========================================================

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceColor,

      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
      ),

      labelStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
      ),

      prefixIconColor: const Color(0xFF9CA3AF),
      suffixIconColor: const Color(0xFF9CA3AF),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: const BorderSide(
          color: secondaryColor,
          width: 2,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: const BorderSide(
          color: errorColor,
          width: 1,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: const BorderSide(
          color: errorColor,
          width: 2,
        ),
      ),

      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: BorderSide.none,
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),

    // ==========================================================
    // ELEVATED BUTTON
    // ==========================================================

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,

        minimumSize: const Size(
          double.infinity,
          50,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
        ),

        elevation: 0,

        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ==========================================================
    // OUTLINED BUTTON
    // ==========================================================

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryColor,

        minimumSize: const Size(
          double.infinity,
          50,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),

        side: const BorderSide(
          color: secondaryColor,
          width: 1.2,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
        ),

        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ==========================================================
    // TEXT BUTTON
    // ==========================================================

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryColor,

        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(smallRadius),
        ),

        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ==========================================================
    // NAVIGATION BAR
    // ==========================================================

    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: darkSurfaceColor,
      indicatorColor: Color(0xFF263238),

      elevation: 0,
      height: 72,

      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      iconTheme: WidgetStatePropertyAll(
        IconThemeData(
          size: 24,
          color: Colors.white,
        ),
      ),
    ),

    // ==========================================================
    // FAB
    // ==========================================================

    floatingActionButtonTheme:
        const FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
    ),

    // ==========================================================
    // DIALOG
    // ==========================================================

    dialogTheme: DialogThemeData(
      backgroundColor: darkSurfaceColor,
      elevation: 4,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(largeRadius),
      ),

      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),

      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: darkSecondaryTextColor,
        height: 1.4,
      ),
    ),

    // ==========================================================
    // BOTTOM SHEET
    // ==========================================================

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      showDragHandle: true,
    ),

    // ==========================================================
    // DIVIDER
    // ==========================================================

    dividerTheme: const DividerThemeData(
      color: darkDividerColor,
      thickness: 1,
      space: 1,
    ),

    // ==========================================================
    // CHIP
    // ==========================================================

    chipTheme: ChipThemeData(
      backgroundColor: darkSurfaceColor,
      selectedColor: const Color(0xFF263238),
      disabledColor: darkSurfaceColor,

      side: const BorderSide(
        color: darkDividerColor,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
      ),

      labelStyle: const TextStyle(
        fontSize: 13,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),

      secondaryLabelStyle: const TextStyle(
        fontSize: 13,
        color: darkSecondaryTextColor,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
    ),

    // ==========================================================
    // CHECKBOX
    // ==========================================================

    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),

      side: const BorderSide(
        color: Color(0xFF9CA3AF),
        width: 1.5,
      ),

      fillColor:
          WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return secondaryColor;
          }

          return Colors.transparent;
        },
      ),
    ),

    // ==========================================================
    // SWITCH
    // ==========================================================

    switchTheme: SwitchThemeData(
      thumbColor:
          WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return secondaryColor;
          }

          return Colors.white;
        },
      ),

      trackColor:
          WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF37474F);
          }

          return const Color(0xFF424242);
        },
      ),
    ),

    // ==========================================================
    // PROGRESS
    // ==========================================================

    progressIndicatorTheme:
        const ProgressIndicatorThemeData(
      color: secondaryColor,
    ),

    // ==========================================================
    // SNACKBAR
    // ==========================================================

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,

      backgroundColor: const Color(0xFF333333),

      elevation: 4,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
      ),

      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
    ),

    // ==========================================================
    // TOOLTIP
    // ==========================================================

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(smallRadius),
      ),

      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
    ),

    // ==========================================================
    // TEXT THEME
    // ==========================================================

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      ),

      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      ),

      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.25,
      ),

      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),

      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),

      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),

      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white,
        height: 1.4,
      ),

      bodyMedium: TextStyle(
        fontSize: 14,
        color: darkSecondaryTextColor,
        height: 1.4,
      ),

      bodySmall: TextStyle(
        fontSize: 12,
        color: Color(0xFF9CA3AF),
        height: 1.3,
      ),

      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),

      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: darkSecondaryTextColor,
      ),

      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF9CA3AF),
      ),
    ),
  );
}