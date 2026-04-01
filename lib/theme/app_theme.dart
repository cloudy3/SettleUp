import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color warning;
  final Color info;

  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.info,
  });

  @override
  AppSemanticColors copyWith({Color? success, Color? warning, Color? info}) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }

    return AppSemanticColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
    );
  }
}

class AppTheme {
  static const AppSemanticColors _lightSemantic = AppSemanticColors(
    success: Color(0xFF0C8A51),
    warning: Color(0xFFB66A00),
    info: Color(0xFF005FB8),
  );

  static const AppSemanticColors _darkSemantic = AppSemanticColors(
    success: Color(0xFF62D99E),
    warning: Color(0xFFFFC970),
    info: Color(0xFF88C6FF),
  );

  static AppSemanticColors semanticOf(BuildContext context) {
    return Theme.of(context).extension<AppSemanticColors>() ?? _lightSemantic;
  }

  static ThemeData get lightTheme {
    final base = FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: Color(0xFF0B3D5C),
        primaryContainer: Color(0xFFD5E8FF),
        secondary: Color(0xFF0A8F7A),
        secondaryContainer: Color(0xFFC7F3EA),
        tertiary: Color(0xFF6D5BD0),
        tertiaryContainer: Color(0xFFE7E0FF),
        appBarColor: Color(0xFFF6F8FC),
        error: Color(0xFFBA1A1A),
      ),
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 10,
      appBarStyle: FlexAppBarStyle.background,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        defaultRadius: AppRadii.lg,
        cardRadius: AppRadii.xl,
        inputDecoratorRadius: AppRadii.lg,
        elevatedButtonRadius: AppRadii.lg,
        outlinedButtonRadius: AppRadii.lg,
        textButtonRadius: AppRadii.lg,
        chipRadius: AppRadii.lg,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[_lightSemantic],
    );
  }

  static ThemeData get darkTheme {
    final base = FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: Color(0xFFA7C8FF),
        primaryContainer: Color(0xFF1A3147),
        secondary: Color(0xFF7DE1D0),
        secondaryContainer: Color(0xFF0F3A34),
        tertiary: Color(0xFFCDBDFF),
        tertiaryContainer: Color(0xFF342B64),
        appBarColor: Color(0xFF111827),
        error: Color(0xFFFFB4AB),
      ),
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 14,
      appBarStyle: FlexAppBarStyle.background,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        defaultRadius: AppRadii.lg,
        cardRadius: AppRadii.xl,
        inputDecoratorRadius: AppRadii.lg,
        elevatedButtonRadius: AppRadii.lg,
        outlinedButtonRadius: AppRadii.lg,
        textButtonRadius: AppRadii.lg,
        chipRadius: AppRadii.lg,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[_darkSemantic],
    );
  }
}
