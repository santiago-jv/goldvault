import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified geometry tokens aligned with Apple Human Interface Guidelines
/// and minimalist fintech surfaces (Copilot / Apple Wallet / Revolut).
class GVRadius {
  static const double bento = 18.0;
  static const double card = 16.0;
  static const double control = 12.0;
  static const double squircle = 11.0;
  static const double pill = 999.0;
}

/// Unified spacing scale across screens and components.
class GVSpacing {
  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
}

/// Maps category names to crisp vector icons so Web, iOS, and Android render identically
/// without inconsistent or monochrome platform emoji glyphs.
IconData categoryIconData(String? category) {
  final name = (category ?? '').toLowerCase();
  if (name.contains('vivienda') || name.contains('arriendo') || name.contains('hogar')) {
    return Icons.home_outlined;
  }
  if (name.contains('mercado') || name.contains('super')) {
    return Icons.shopping_cart_outlined;
  }
  if (name.contains('comida') || name.contains('restaurante') || name.contains('almuerzo')) {
    return Icons.restaurant_outlined;
  }
  if (name.contains('transporte') || name.contains('uber') || name.contains('auto')) {
    return Icons.directions_car_outlined;
  }
  if (name.contains('suscrip') || name.contains('servicio')) {
    return Icons.subscriptions_outlined;
  }
  if (name.contains('salud') || name.contains('farmacia') || name.contains('gym')) {
    return Icons.favorite_outline_rounded;
  }
  if (name.contains('educa') || name.contains('libro')) {
    return Icons.school_outlined;
  }
  if (name.contains('ocio') || name.contains('entreten')) {
    return Icons.celebration_outlined;
  }
  if (name.contains('ropa') || name.contains('calzado')) {
    return Icons.checkroom_outlined;
  }
  if (name.contains('deuda') || name.contains('tarjeta') || name.contains('crédito')) {
    return Icons.credit_card_outlined;
  }
  if (name.contains('regalo')) {
    return Icons.card_giftcard_outlined;
  }
  return Icons.category_outlined;
}

class GVColors {
  final bool isDark;
  final Color bg;
  final Color card;
  final Color card2;
  final Color navGlass;
  final Color txt;
  final Color mut;
  final Color tertiary;
  final Color line;
  final Color lineStrong;
  final Color acc;
  final Color acc2;
  final Color ink;
  final Color green;
  final Color red;
  final Color amber;
  final Color blue;
  final Color placeholder;
  final List<Color> chartPalette;

  const GVColors({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.card2,
    required this.navGlass,
    required this.txt,
    required this.mut,
    required this.tertiary,
    required this.line,
    required this.lineStrong,
    required this.acc,
    required this.acc2,
    required this.ink,
    required this.green,
    required this.red,
    required this.amber,
    required this.blue,
    required this.placeholder,
    required this.chartPalette,
  });

  /// Calm matte obsidian dark palette with restrained Apple semantic accents.
  static const dark = GVColors(
    isDark: true,
    bg: Color(0xFF0B0B0E),
    card: Color(0xFF151519),
    card2: Color(0xFF1E1E24),
    navGlass: Color(0xE0151519),
    txt: Color(0xFFF5F5F7),
    mut: Color(0xFFA8A8B3),
    tertiary: Color(0xFF8E8E98),
    line: Color(0x14FFFFFF),
    lineStrong: Color(0x2EFFFFFF),
    acc: Color(0xFFF5F5F7),
    acc2: Color(0xFFD2D2D7),
    ink: Color(0xFF0B0B0E),
    green: Color(0xFF30D158),
    red: Color(0xFFFF453A),
    amber: Color(0xFFFF9F0A),
    blue: Color(0xFF0A84FF),
    placeholder: Color(0x66F5F5F7),
    chartPalette: [
      Color(0xFF0A84FF),
      Color(0xFF30D158),
      Color(0xFFFF9F0A),
      Color(0xFFBF5AF2),
      Color(0xFFFF453A),
      Color(0xFF64D2FF),
    ],
  );

  /// Calm daylight fintech palette with crisp white surfaces and whisper-soft hairlines.
  static const light = GVColors(
    isDark: false,
    bg: Color(0xFFF7F8FA),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFF1F2F6),
    navGlass: Color(0xE6FFFFFF),
    txt: Color(0xFF111113),
    mut: Color(0xFF525866),
    tertiary: Color(0xFF636A79),
    line: Color(0x0E000000),
    lineStrong: Color(0x26000000),
    acc: Color(0xFF111113),
    acc2: Color(0xFF374151),
    ink: Color(0xFFFFFFFF),
    green: Color(0xFF16A34A),
    red: Color(0xFFDC2626),
    amber: Color(0xFFD97706),
    blue: Color(0xFF0071E3),
    placeholder: Color(0x66111113),
    chartPalette: [
      Color(0xFF0071E3),
      Color(0xFF16A34A),
      Color(0xFFD97706),
      Color(0xFF7C3AED),
      Color(0xFFDC2626),
      Color(0xFF0284C7),
    ],
  );

  /// Whisper-soft hairline elevation (flat in dark mode, ultra-subtle in light mode).
  List<BoxShadow> get cardShadow => isDark
      ? const []
      : const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2))];

  static GVColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

/// Standardized 8-tier Apple-inspired typographic hierarchy with tabular figure support.
class GVTxt {
  static const double fsDisplay = 38.0;
  static const double fsH1 = 26.0;
  static const double fsH2 = 22.0;
  static const double fsH3 = 16.0;
  static const double fsBody = 15.0;
  static const double fsSm = 13.5;
  static const double fsXs = 12.0;
  static const double fs2xs = 11.0;

  static bool get _isNativeApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static const List<String> _appleFallbackStack = [
    '-apple-system',
    'BlinkMacSystemFont',
    'SF Pro Display',
    'SF Pro Text',
    'Helvetica Neue',
    'sans-serif',
  ];

  static TextStyle _font({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    double? letterSpacing,
    required Color color,
    bool tabular = false,
  }) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontFamily: _isNativeApple ? (fontSize >= 20.0 ? '.SF Pro Display' : '.SF Pro Text') : null,
      fontFamilyFallback: _appleFallbackStack,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
    if (_isNativeApple) {
      return baseStyle;
    }
    return GoogleFonts.inter(textStyle: baseStyle);
  }

  static TextStyle display(GVColors c, {Color? color}) => _font(
    fontSize: fsDisplay,
    fontWeight: FontWeight.w700,
    height: 1.06,
    letterSpacing: -1.2,
    color: color ?? c.txt,
    tabular: true,
  );

  static TextStyle h1(GVColors c, {Color? color}) => _font(
    fontSize: fsH1,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.7,
    color: color ?? c.txt,
  );

  static TextStyle h2(GVColors c, {Color? color}) => _font(
    fontSize: fsH2,
    fontWeight: FontWeight.w700,
    height: 1.18,
    letterSpacing: -0.5,
    color: color ?? c.txt,
  );

  static TextStyle h3(GVColors c, {Color? color, bool tabular = false}) => _font(
    fontSize: fsH3,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.25,
    color: color ?? c.txt,
    tabular: tabular,
  );

  static TextStyle body(
    GVColors c, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    bool tabular = false,
  }) => _font(
    fontSize: fsBody,
    fontWeight: weight,
    height: 1.4,
    letterSpacing: -0.18,
    color: color ?? c.txt,
    tabular: tabular,
  );

  static TextStyle sm(
    GVColors c, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    bool tabular = false,
  }) => _font(
    fontSize: fsSm,
    fontWeight: weight,
    height: 1.45,
    letterSpacing: -0.12,
    color: color ?? c.mut,
    tabular: tabular,
  );

  static TextStyle xs(
    GVColors c, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? letterSpacing,
    bool tabular = false,
  }) => _font(
    fontSize: fsXs,
    fontWeight: weight,
    height: 1.35,
    letterSpacing: letterSpacing ?? -0.05,
    color: color ?? c.mut,
    tabular: tabular,
  );

  static TextStyle xs2(
    GVColors c, {
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
    bool tabular = false,
  }) => _font(
    fontSize: fs2xs,
    fontWeight: weight,
    height: 1.2,
    letterSpacing: letterSpacing ?? 0.2,
    color: color ?? c.tertiary,
    tabular: tabular,
  );
}

class GoldTheme {
  static ThemeData build(Brightness brightness) {
    final c = brightness == Brightness.dark ? GVColors.dark : GVColors.light;
    final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    final isNativeApple =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    final textFontFamily = isNativeApple ? '.SF Pro Text' : GoogleFonts.inter().fontFamily;
    final baseTextTheme = base.textTheme.apply(
      fontFamily: textFontFamily,
      fontFamilyFallback: GVTxt._appleFallbackStack,
      bodyColor: c.txt,
      displayColor: c.txt,
    );
    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: c.txt.withValues(alpha: 0.05),
      hoverColor: c.txt.withValues(alpha: 0.045),
      focusColor: c.blue.withValues(alpha: 0.16),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.acc,
        onPrimary: c.ink,
        secondary: c.acc2,
        onSecondary: c.ink,
        error: c.red,
        onError: Colors.white,
        surface: c.card,
        onSurface: c.txt,
      ),
      textTheme: baseTextTheme,
      dividerColor: c.line,
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.isDark ? const Color(0xFF242429) : const Color(0xFF1D1D1F),
        contentTextStyle: GVTxt.sm(c, weight: FontWeight.w500, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class GoldVaultLogo extends StatelessWidget {
  final double fontSize;
  final Color? textColor;
  final Color? accentColor;

  const GoldVaultLogo({super.key, this.fontSize = GVTxt.fsH2, this.textColor, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final primaryTxt = textColor ?? c.txt;
    final secondaryTxt = accentColor ?? c.mut;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size(fontSize * 1.05, fontSize * 1.05),
            painter: _VaultVMarkPainter(primaryTxt),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: GVTxt._font(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                height: 1.08,
                letterSpacing: -0.5,
                color: primaryTxt,
              ),
              children: [
                const TextSpan(text: 'Gold'),
                TextSpan(
                  text: 'Vault',
                  style: TextStyle(color: secondaryTxt, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone folded geometric V emblem widget supporting progressive reveal animation.
class GoldVaultMark extends StatelessWidget {
  final double size;
  final Color? color;
  final double progress;

  const GoldVaultMark({super.key, this.size = 36, this.color, this.progress = 1.0});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return CustomPaint(
      size: Size.square(size),
      painter: _VaultVMarkPainter(color ?? c.txt, progress: progress),
    );
  }
}

/// Minimalist folded geometric V emblem matching the GoldVault app icon.
class _VaultVMarkPainter extends CustomPainter {
  final Color color;
  final double progress;
  _VaultVMarkPainter(this.color, {this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24.0;
    final sy = size.height / 24.0;

    final pLeft = (progress / 0.45).clamp(0.0, 1.0);
    final pFold = ((progress - 0.25) / 0.45).clamp(0.0, 1.0);
    final pRight = ((progress - 0.45) / 0.55).clamp(0.0, 1.0);

    // Left ribbon arm
    if (pLeft > 0) {
      final leftPaint = Paint()
        ..color = color.withValues(alpha: pLeft)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(0, (1 - pLeft) * 3.0 * sy);
      final leftArm = Path()
        ..moveTo(5.8 * sx, 4.2 * sy)
        ..lineTo(3.0 * sx, 8.8 * sy)
        ..lineTo(10.8 * sx, 20.4 * sy)
        ..lineTo(13.5 * sx, 15.8 * sy)
        ..close();
      canvas.drawPath(leftArm, leftPaint);
      canvas.restore();
    }

    // Inner folded ribbon facet
    if (pFold > 0) {
      final foldPaint = Paint()
        ..color = color.withValues(alpha: 0.72 * pFold)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(0, (1 - pFold) * -2.5 * sy);
      final innerFacet = Path()
        ..moveTo(14.5 * sx, 4.2 * sy)
        ..lineTo(10.9 * sx, 10.4 * sy)
        ..lineTo(13.4 * sx, 14.4 * sy)
        ..lineTo(18.0 * sx, 6.6 * sy)
        ..lineTo(16.7 * sx, 4.2 * sy)
        ..close();
      canvas.drawPath(innerFacet, foldPaint);
      canvas.restore();
    }

    // Right primary ribbon arm
    if (pRight > 0) {
      final rightPaint = Paint()
        ..color = color.withValues(alpha: pRight)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(0, (1 - pRight) * 3.0 * sy);
      final rightArm = Path()
        ..moveTo(16.7 * sx, 4.2 * sy)
        ..lineTo(19.6 * sx, 4.2 * sy)
        ..lineTo(22.0 * sx, 8.4 * sy)
        ..lineTo(14.8 * sx, 20.6 * sy)
        ..lineTo(11.4 * sx, 20.6 * sy)
        ..lineTo(18.4 * sx, 8.6 * sy)
        ..close();
      canvas.drawPath(rightArm, rightPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _VaultVMarkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}
