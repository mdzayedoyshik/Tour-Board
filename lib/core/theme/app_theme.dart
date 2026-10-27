import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand and surface tokens. The palette follows the logo: ocean blue,
/// sunset orange and deep navy, on soft neutral surfaces.
abstract final class AppColors {
  static const ocean = Color(0xFF1F6FEB);
  static const oceanLight = Color(0xFF7FB0FF);
  static const sunset = Color(0xFFF59E0B);
  static const sunsetLight = Color(0xFFFFC266);
  static const navy = Color(0xFF0F2A4A);

  /// Kept for compatibility with existing widgets/tests.
  static const accent = ocean;
  static const accentDark = oceanLight;

  static const lightBackground = Color(0xFFF5F7FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFEDF1F7);
  static const lightOutline = Color(0xFFE1E6EF);
  static const lightText = Color(0xFF0F1B2D);
  static const lightTextSecondary = Color(0xFF55627A);

  static const darkBackground = Color(0xFF0D1117);
  static const darkSurface = Color(0xFF161B23);
  static const darkSurfaceHigh = Color(0xFF1F2530);
  static const darkOutline = Color(0xFF2A313D);
  static const darkText = Color(0xFFF1F4F9);
  static const darkTextSecondary = Color(0xFFA6B0C2);

  static const success = Color(0xFF15803D);
  static const successDark = Color(0xFF4ADE80);
  static const warning = Color(0xFFB45309);
  static const warningDark = Color(0xFFFBBF24);
  static const error = Color(0xFFDC2626);
  static const errorDark = Color(0xFFF87171);
}

abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Horizontal page padding.
  static const page = 20.0;
}

abstract final class AppRadii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

abstract final class AppSizes {
  static const iconSm = 16.0;
  static const iconMd = 20.0;
  static const iconLg = 24.0;
  static const avatarXs = 20.0;
  static const avatarSm = 28.0;
  static const avatarMd = 40.0;
  static const avatarLg = 56.0;

  /// Comfortable minimum tap target.
  static const tapTarget = 48.0;

  /// Max content width on large screens so the app does not stretch.
  static const maxContentWidth = 720.0;
}

/// Gradient "covers" that give each tour its own identity. Chosen
/// deterministically from the tour ID so every device shows the same one.
abstract final class TourPalette {
  static const gradients = <List<Color>>[
    [Color(0xFF1F6FEB), Color(0xFF38BDF8)], // ocean
    [Color(0xFFF59E0B), Color(0xFFF43F5E)], // sunset
    [Color(0xFF0EA5A4), Color(0xFF22C55E)], // lagoon
    [Color(0xFF7C3AED), Color(0xFFEC4899)], // dusk
    [Color(0xFF0F2A4A), Color(0xFF1F6FEB)], // deep sea
    [Color(0xFFEA580C), Color(0xFFFACC15)], // desert
  ];

  static List<Color> forId(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return gradients[hash % gradients.length];
  }

  static LinearGradient gradientFor(String id) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: forId(id),
  );
}

/// Semantic status colors resolved for the current brightness.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.muted,
  });

  final Color success;
  final Color warning;
  final Color error;
  final Color muted;

  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>()!;

  @override
  StatusColors copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? muted,
  }) => StatusColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    muted: muted ?? this.muted,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

/// Soft elevation used for floating cards (map sheets, search bars).
@immutable
class Elevations extends ThemeExtension<Elevations> {
  const Elevations({required this.card, required this.floating});

  final List<BoxShadow> card;
  final List<BoxShadow> floating;

  static Elevations of(BuildContext context) =>
      Theme.of(context).extension<Elevations>()!;

  @override
  Elevations copyWith({List<BoxShadow>? card, List<BoxShadow>? floating}) =>
      Elevations(card: card ?? this.card, floating: floating ?? this.floating);

  @override
  Elevations lerp(Elevations? other, double t) => t < 0.5 ? this : other!;
}

abstract final class AppTheme {
  static const fontFamily = 'PlusJakartaSans';

  static ThemeData light() {
    final seeded = ColorScheme.fromSeed(
      seedColor: AppColors.ocean,
      secondary: AppColors.sunset,
    );
    return _build(
      scheme: seeded.copyWith(
        primary: AppColors.ocean,
        onPrimary: Colors.white,
        secondary: AppColors.sunset,
        onSecondary: AppColors.navy,
        tertiary: AppColors.navy,
        error: AppColors.error,
        surface: AppColors.lightBackground,
        onSurface: AppColors.lightText,
        onSurfaceVariant: AppColors.lightTextSecondary,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: AppColors.lightSurface,
        surfaceContainer: AppColors.lightSurface,
        surfaceContainerHigh: AppColors.lightSurfaceHigh,
        surfaceContainerHighest: const Color(0xFFE4E9F2),
        outline: const Color(0xFFC9D1DE),
        outlineVariant: AppColors.lightOutline,
      ),
      status: const StatusColors(
        success: AppColors.success,
        warning: AppColors.warning,
        error: AppColors.error,
        muted: AppColors.lightTextSecondary,
      ),
      elevations: const Elevations(
        card: [
          BoxShadow(
            color: Color(0x0F0F2A4A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
        floating: [
          BoxShadow(
            color: Color(0x290F2A4A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
    );
  }

  static ThemeData dark() {
    final seeded = ColorScheme.fromSeed(
      seedColor: AppColors.ocean,
      secondary: AppColors.sunset,
      brightness: Brightness.dark,
    );
    return _build(
      scheme: seeded.copyWith(
        primary: AppColors.oceanLight,
        onPrimary: const Color(0xFF00214F),
        secondary: AppColors.sunsetLight,
        onSecondary: const Color(0xFF3B2500),
        tertiary: const Color(0xFF9CC3FF),
        error: AppColors.errorDark,
        surface: AppColors.darkBackground,
        onSurface: AppColors.darkText,
        onSurfaceVariant: AppColors.darkTextSecondary,
        surfaceContainerLowest: const Color(0xFF0A0D12),
        surfaceContainerLow: AppColors.darkSurface,
        surfaceContainer: AppColors.darkSurface,
        surfaceContainerHigh: AppColors.darkSurfaceHigh,
        surfaceContainerHighest: const Color(0xFF283040),
        outline: const Color(0xFF3B4454),
        outlineVariant: AppColors.darkOutline,
      ),
      status: const StatusColors(
        success: AppColors.successDark,
        warning: AppColors.warningDark,
        error: AppColors.errorDark,
        muted: AppColors.darkTextSecondary,
      ),
      elevations: const Elevations(
        card: [],
        floating: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required StatusColors status,
    required Elevations elevations,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
    );
    TextStyle? tune(TextStyle? s, FontWeight w, [double? spacing]) =>
        s?.copyWith(fontWeight: w, letterSpacing: spacing);
    final t = base.textTheme;
    final text = t
        .copyWith(
          displaySmall: tune(t.displaySmall, FontWeight.w800, -1),
          headlineLarge: tune(t.headlineLarge, FontWeight.w800, -0.8),
          headlineMedium: tune(t.headlineMedium, FontWeight.w800, -0.6),
          headlineSmall: tune(t.headlineSmall, FontWeight.w700, -0.4),
          titleLarge: tune(t.titleLarge, FontWeight.w700, -0.2),
          titleMedium: tune(t.titleMedium, FontWeight.w700),
          titleSmall: tune(t.titleSmall, FontWeight.w600),
          labelLarge: tune(t.labelLarge, FontWeight.w700),
          labelMedium: tune(t.labelMedium, FontWeight.w600),
          bodyLarge: t.bodyLarge?.copyWith(height: 1.45),
          bodyMedium: t.bodyMedium?.copyWith(height: 1.45),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    );
    final chipLabel = text.labelLarge?.copyWith(fontWeight: FontWeight.w600);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      extensions: [status, elevations],
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: rounded,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: rounded,
          side: BorderSide(color: scheme.outline),
          foregroundColor: scheme.onSurface,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, AppSizes.tapTarget),
          foregroundColor: scheme.primary,
          shape: rounded,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        extendedTextStyle: text.labelLarge?.copyWith(fontSize: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHigh : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: isDark ? scheme.surfaceContainerHigh : Colors.white,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        labelStyle: chipLabel?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: chipLabel?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 18),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurface,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
          textStyle: WidgetStatePropertyAll(chipLabel),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.secondary,
        textColor: scheme.onSecondary,
        textStyle: text.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerLow : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 72,
        shadowColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerLow : Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerLow : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? scheme.surfaceContainerHighest
            : AppColors.navy,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: rounded,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        minVerticalPadding: AppSpacing.md,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
