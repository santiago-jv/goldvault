import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified geometry tokens aligned with Apple Human Interface Guidelines
/// and Bento surface design.
class GVRadius {
  static const double bento = 24.0;
  static const double card = 20.0;
  static const double control = 14.0;
  static const double squircle = 12.0;
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

  /// Apple Anodized Space Black chrome with crisp Apple semantic colors.
  static const dark = GVColors(
    isDark: true,
    bg: Color(0xFF000000),
    card: Color(0xFF141417),
    card2: Color(0xFF1E1E22),
    navGlass: Color(0xD9141417),
    txt: Color(0xFFF5F5F7),
    mut: Color(0xFF98989F),
    tertiary: Color(0xFF6E6E73),
    line: Color(0x18FFFFFF),
    lineStrong: Color(0x2CFFFFFF),
    acc: Color(0xFFFFFFFF),
    acc2: Color(0xFFD2D2D7),
    ink: Color(0xFF0C0C0E),
    green: Color(0xFF30D158),
    red: Color(0xFFFF453A),
    amber: Color(0xFFFF9F0A),
    blue: Color(0xFF0A84FF),
    placeholder: Color(0x73F5F5F7),
    chartPalette: [
      Color(0xFF0A84FF),
      Color(0xFF30D158),
      Color(0xFFFF9F0A),
      Color(0xFFBF5AF2),
      Color(0xFFFF453A),
      Color(0xFF64D2FF),
    ],
  );

  /// Apple Cupertino Daylight chrome with crisp Apple semantic colors.
  static const light = GVColors(
    isDark: false,
    bg: Color(0xFFF5F5F7),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFEFEFF2),
    navGlass: Color(0xD9FFFFFF),
    txt: Color(0xFF1D1D1F),
    mut: Color(0xFF6E6E73),
    tertiary: Color(0xFF86868B),
    line: Color(0x13000000),
    lineStrong: Color(0x24000000),
    acc: Color(0xFF1D1D1F),
    acc2: Color(0xFF3A3A3D),
    ink: Color(0xFFFFFFFF),
    green: Color(0xFF1D8348),
    red: Color(0xFFD70015),
    amber: Color(0xFFC27200),
    blue: Color(0xFF0071E3),
    placeholder: Color(0x731D1D1F),
    chartPalette: [
      Color(0xFF0071E3),
      Color(0xFF1D8348),
      Color(0xFFD97706),
      Color(0xFF7C3AED),
      Color(0xFFD70015),
      Color(0xFF0284C7),
    ],
  );

  /// Soft multi-layered Bento elevation shadow.
  List<BoxShadow> get cardShadow => isDark
      ? const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ];

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
      fontFamily: _isNativeApple
          ? (fontSize >= 20.0 ? '.SF Pro Display' : '.SF Pro Text')
          : null,
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
  }) =>
      _font(
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
  }) =>
      _font(
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
  }) =>
      _font(
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
  }) =>
      _font(
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
    final isNativeApple = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    final baseTextTheme = isNativeApple
        ? base.textTheme.apply(
            fontFamily: '.SF Pro Text',
            bodyColor: c.txt,
            displayColor: c.txt,
          )
        : GoogleFonts.interTextTheme(base.textTheme).apply(
            bodyColor: c.txt,
            displayColor: c.txt,
          );
    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: c.txt.withValues(alpha: 0.04),
      hoverColor: c.txt.withValues(alpha: 0.03),
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

  const GoldVaultLogo({
    super.key,
    this.fontSize = GVTxt.fsH2,
    this.textColor,
    this.accentColor,
  });

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
            painter: _VaultArchPainter(primaryTxt),
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

class _VaultArchPainter extends CustomPainter {
  final Color color;
  _VaultArchPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24.0;
    final sy = size.height / 24.0;

    final p1 = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1 * sx
      ..strokeCap = StrokeCap.round;

    final outer = Path()
      ..moveTo(3.5 * sx, 21 * sy)
      ..lineTo(3.5 * sx, 11.5 * sy)
      ..arcToPoint(
        Offset(20.5 * sx, 11.5 * sy),
        radius: Radius.elliptical(8.5 * sx, 8.5 * sy),
        clockwise: true,
      )
      ..lineTo(20.5 * sx, 21 * sy);
    canvas.drawPath(outer, p1);

    final p2 = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65 * sx
      ..strokeCap = StrokeCap.round;

    final inner = Path()
      ..moveTo(9 * sx, 21 * sy)
      ..lineTo(9 * sx, 11.8 * sy)
      ..arcToPoint(
        Offset(15 * sx, 11.8 * sy),
        radius: Radius.elliptical(3 * sx, 3 * sy),
        clockwise: true,
      )
      ..lineTo(15 * sx, 21 * sy);
    canvas.drawPath(inner, p2);
  }

  @override
  bool shouldRepaint(covariant _VaultArchPainter oldDelegate) => oldDelegate.color != color;
}
