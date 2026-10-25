import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color label;
  final Color body;
  final Color meta;
  final Color separator;
  final Color searchFill;
  final Color accent;
  final Color pillFilled;
  final Color pillEmpty;
  final Color pillText;
  final Color destructive;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.label,
    required this.body,
    required this.meta,
    required this.separator,
    required this.searchFill,
    required this.accent,
    required this.pillFilled,
    required this.pillEmpty,
    required this.pillText,
    required this.destructive,
  });

  static const AppColors light = AppColors(
    background: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    label: Color(0xFF1C1C1E),
    body: Color(0xFF48484A),
    meta: Color(0xFF6C6C70),
    separator: Color.fromRGBO(60, 60, 67, 0.16),
    searchFill: Color(0xFFE3E3E8),
    accent: Color(0xFFFF2D55),
    pillFilled: Color(0xFFFFD1DC),
    pillEmpty: Color(0xFFFFEBF0),
    pillText: Color(0xFF8B0029),
    destructive: Color(0xFFD70015),
  );

  static const AppColors dark = AppColors(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceElevated: Color(0xFF3A3A43),
    label: Color(0xFFFFFFFF),
    body: Color(0xFFD1D1D6),
    meta: Color(0xFF98989F),
    separator: Color.fromRGBO(84, 84, 88, 0.6),
    searchFill: Color(0xFF2C2C2E),
    accent: Color(0xFFFF375F),
    pillFilled: Color(0xFF3A2329),
    pillEmpty: Color(0xFF281B1E),
    pillText: Color(0xFFFF94B2),
    destructive: Color(0xFFFF453F),
  );

  static AppColors getThemeColors({required bool isDark, required int accentIndex}) {
    final idx = accentIndex.clamp(0, DesignTokens.accentColors.length - 1);
    final accentOpt = DesignTokens.accentColors[idx];

    final base = isDark ? dark : light;
    final rawColor = isDark ? accentOpt.darkColor : accentOpt.lightColor;
    final rawPillFill = isDark ? accentOpt.darkPillFilled : accentOpt.lightPillFilled;
    final rawPillEmpty = isDark ? accentOpt.darkPillEmpty : accentOpt.lightPillEmpty;

    // Apply a subtle 10% warm red tint (0xFFFF2D55) to give the accent & theme character
    const redTint = Color(0xFFFF2D55);
    final color = Color.alphaBlend(redTint.withValues(alpha: 0.10), rawColor);
    final pillFill = Color.alphaBlend(redTint.withValues(alpha: 0.10), rawPillFill);
    final pillEmpty = Color.alphaBlend(redTint.withValues(alpha: 0.10), rawPillEmpty);

    // Google Material-style dynamic accent background & surface tinting
    final double bgTintFactor = isDark ? 0.06 : 0.03;
    final double surfaceTintFactor = isDark ? 0.08 : 0.02;

    final tintedBg = Color.alphaBlend(color.withValues(alpha: bgTintFactor), base.background);
    final tintedSurface = Color.alphaBlend(color.withValues(alpha: surfaceTintFactor), base.surface);
    final tintedElevated = Color.alphaBlend(color.withValues(alpha: surfaceTintFactor + 0.02), base.surfaceElevated);
    final tintedSearchFill = Color.alphaBlend(color.withValues(alpha: isDark ? 0.12 : 0.05), base.searchFill);

    return base.copyWith(
      background: tintedBg,
      surface: tintedSurface,
      surfaceElevated: tintedElevated,
      searchFill: tintedSearchFill,
      accent: color,
      pillFilled: pillFill,
      pillEmpty: pillEmpty,
      pillText: isDark ? color : const Color(0xFF1C1C1E),
    );
  }

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? label,
    Color? body,
    Color? meta,
    Color? separator,
    Color? searchFill,
    Color? accent,
    Color? pillFilled,
    Color? pillEmpty,
    Color? pillText,
    Color? destructive,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      label: label ?? this.label,
      body: body ?? this.body,
      meta: meta ?? this.meta,
      separator: separator ?? this.separator,
      searchFill: searchFill ?? this.searchFill,
      accent: accent ?? this.accent,
      pillFilled: pillFilled ?? this.pillFilled,
      pillEmpty: pillEmpty ?? this.pillEmpty,
      pillText: pillText ?? this.pillText,
      destructive: destructive ?? this.destructive,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      label: Color.lerp(label, other.label, t)!,
      body: Color.lerp(body, other.body, t)!,
      meta: Color.lerp(meta, other.meta, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      searchFill: Color.lerp(searchFill, other.searchFill, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      pillFilled: Color.lerp(pillFilled, other.pillFilled, t)!,
      pillEmpty: Color.lerp(pillEmpty, other.pillEmpty, t)!,
      pillText: Color.lerp(pillText, other.pillText, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
    );
  }
}

extension AppColorsExtension on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppColors.dark
          : AppColors.light);
}

class AccentColorOption {
  final String nameAmharic;
  final String nameEnglish;
  final Color lightColor;
  final Color darkColor;
  final Color lightPillFilled;
  final Color darkPillFilled;
  final Color lightPillEmpty;
  final Color darkPillEmpty;

  const AccentColorOption({
    required this.nameAmharic,
    required this.nameEnglish,
    required this.lightColor,
    required this.darkColor,
    required this.lightPillFilled,
    required this.darkPillFilled,
    required this.lightPillEmpty,
    required this.darkPillEmpty,
  });
}

class DesignTokens {
  static const String primaryFont = 'Inter';
  static const List<String> fontFallback = ['Noto Sans Ethiopic', 'sans-serif'];
  static const double ethioLetterSpacing = 0.0;

  static const double cardRadius = 18.0;
  static const double searchRadius = 10.0;
  static const double menuRadius = 12.0;

  static const List<AccentColorOption> accentColors = [
    AccentColorOption(
      nameAmharic: 'ቀይ (Red)',
      nameEnglish: 'Red',
      lightColor: Color(0xFFFF3B30),
      darkColor: Color(0xFFE55B5B),
      lightPillFilled: Color(0xFFFFD5D2),
      darkPillFilled: Color(0xFF3D1B19),
      lightPillEmpty: Color(0xFFFFF0EF),
      darkPillEmpty: Color(0xFF291211),
    ),
    AccentColorOption(
      nameAmharic: 'ቢጫ (Yellow)',
      nameEnglish: 'Yellow',
      lightColor: Color(0xFFFFCC00),
      darkColor: Color(0xFFE2BE3B),
      lightPillFilled: Color(0xFFFFF3C2),
      darkPillFilled: Color(0xFF3D3310),
      lightPillEmpty: Color(0xFFFFFBEE),
      darkPillEmpty: Color(0xFF29220A),
    ),
    AccentColorOption(
      nameAmharic: 'አረንጓዴ (Green)',
      nameEnglish: 'Green',
      lightColor: Color(0xFF34C759),
      darkColor: Color(0xFF48C072),
      lightPillFilled: Color(0xFFD2F7DC),
      darkPillFilled: Color(0xFF1E3A25),
      lightPillEmpty: Color(0xFFF0FCF3),
      darkPillEmpty: Color(0xFF15281A),
    ),
    AccentColorOption(
      nameAmharic: 'ሰማያዊ (Blue)',
      nameEnglish: 'Blue',
      lightColor: Color(0xFF007AFF),
      darkColor: Color(0xFF4A98ED),
      lightPillFilled: Color(0xFFD0E1FD),
      darkPillFilled: Color(0xFF1E2F4C),
      lightPillEmpty: Color(0xFFF0F5FE),
      darkPillEmpty: Color(0xFF162033),
    ),
    AccentColorOption(
      nameAmharic: 'ወይንጠጅ (Purple)',
      nameEnglish: 'Purple',
      lightColor: Color(0xFFAF52DE),
      darkColor: Color(0xFFAB68D8),
      lightPillFilled: Color(0xFFEEDAFB),
      darkPillFilled: Color(0xFF362145),
      lightPillEmpty: Color(0xFFF9F0FE),
      darkPillEmpty: Color(0xFF251830),
    ),
    AccentColorOption(
      nameAmharic: 'ብርቱካን (Orange)',
      nameEnglish: 'Orange',
      lightColor: Color(0xFFFF9500),
      darkColor: Color(0xFFE89430),
      lightPillFilled: Color(0xFFFFE8CC),
      darkPillFilled: Color(0xFF452D12),
      lightPillEmpty: Color(0xFFFFF7ED),
      darkPillEmpty: Color(0xFF2E1E0C),
    ),
    AccentColorOption(
      nameAmharic: 'ሳይያን (Teal)',
      nameEnglish: 'Teal',
      lightColor: Color(0xFF30B0C7),
      darkColor: Color(0xFF44A8B9),
      lightPillFilled: Color(0xFFCFF3F8),
      darkPillFilled: Color(0xFF1C383E),
      lightPillEmpty: Color(0xFFEFFBFC),
      darkPillEmpty: Color(0xFF13272B),
    ),
  ];

  static TextStyle headline(BuildContext context) {
    return TextStyle(
      fontSize: 17,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: context.colors.label,
      letterSpacing: ethioLetterSpacing,
      fontFamily: primaryFont,
      fontFamilyFallback: fontFallback,
    );
  }

  static TextStyle subhead(BuildContext context) {
    return TextStyle(
      fontSize: 13,
      height: 1.3,
      fontWeight: FontWeight.normal,
      color: context.colors.meta,
      letterSpacing: ethioLetterSpacing,
      fontFamily: primaryFont,
      fontFamilyFallback: fontFallback,
    );
  }

  static TextStyle footnote(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      height: 1.33,
      fontWeight: FontWeight.w500,
      color: context.colors.meta,
      letterSpacing: ethioLetterSpacing,
      fontFamily: primaryFont,
      fontFamilyFallback: fontFallback,
    );
  }
}
