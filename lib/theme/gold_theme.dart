import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GVColors {
  final Color bg;
  final Color card;
  final Color card2;
  final Color txt;
  final Color mut;
  final Color line;
  final Color acc;
  final Color acc2;
  final Color ink;
  final Color green;
  final Color red;
  final Color amber;
  final Color placeholder;
  final List<Color> chartPalette;

  const GVColors({
    required this.bg,
    required this.card,
    required this.card2,
    required this.txt,
    required this.mut,
    required this.line,
    required this.acc,
    required this.acc2,
    required this.ink,
    required this.green,
    required this.red,
    required this.amber,
    required this.placeholder,
    required this.chartPalette,
  });

  static const dark = GVColors(
    bg: Color(0xFF0E0F12),
    card: Color(0xFF14161B),
    card2: Color(0xFF191C22),
    txt: Color(0xFFECE7DD),
    mut: Color(0xFF8B867C),
    line: Color(0x1AECE7DD),
    acc: Color(0xFFD9B87A),
    acc2: Color(0xFFB8965A),
    ink: Color(0xFF17130B),
    green: Color(0xFF6FA882),
    red: Color(0xFFD07A72),
    amber: Color(0xFFD4AC58),
    placeholder: Color(0x8CECE7DD),
    chartPalette: [
      Color(0xFFD9B87A),
      Color(0xFF7FA3B8),
      Color(0xFF6FA882),
      Color(0xFFC8876C),
      Color(0xFF9D8BC2),
      Color(0xFFB8A878),
    ],
  );

  static const light = GVColors(
    bg: Color(0xFFF6F2EA),
    card: Color(0xFFEFEAE0),
    card2: Color(0xFFE6E0D3),
    txt: Color(0xFF1C1A16),
    mut: Color(0xFF787166),
    line: Color(0x1F1C1A16),
    acc: Color(0xFF8A6830),
    acc2: Color(0xFF6E5122),
    ink: Color(0xFFFBF8F2),
    green: Color(0xFF2F6E49),
    red: Color(0xFFAC443C),
    amber: Color(0xFF946B1D),
    placeholder: Color(0x8C1C1A16),
    chartPalette: [
      Color(0xFF8A6830),
      Color(0xFF3E6B85),
      Color(0xFF2F6E49),
      Color(0xFFA8573B),
      Color(0xFF695394),
      Color(0xFF7C6B3F),
    ],
  );

  static GVColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

/// Escala tipográfica estricta de 8 niveles estandarizada en toda la aplicación
class GVTxt {
  static const double fsDisplay = 36.0; // 2.25rem — Monto principal Hero e input de monto
  static const double fsH1 = 24.0;      // 1.50rem — Títulos pantalla completa (Onboarding / Login)
  static const double fsH2 = 20.0;      // 1.25rem — Títulos principales de vista (.brand)
  static const double fsH3 = 16.0;      // 1.00rem — Títulos de tarjetas y modales
  static const double fsBody = 15.0;    // 0.9375rem — Cuerpo principal, filas, inputs, botones
  static const double fsSm = 13.0;      // 0.8125rem — Subtítulos descriptivos (.card-desc), placeholders, chips
  static const double fsXs = 12.0;      // 0.75rem — Etiquetas mayúsculas (.lbl2), notas al pie (.note-txt)
  static const double fs2xs = 11.0;     // 0.6875rem — Micro-etiquetas, badges, barra inferior

  static TextStyle _font({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    double? letterSpacing,
    required Color color,
  }) {
    if (kIsWeb) {
      return GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    }
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle display(GVColors c) => _font(
        fontSize: fsDisplay,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.8,
        color: c.acc,
      );

  static TextStyle h1(GVColors c) => _font(
        fontSize: fsH1,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.4,
        color: c.txt,
      );

  static TextStyle h2(GVColors c) => _font(
        fontSize: fsH2,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.3,
        color: c.txt,
      );

  static TextStyle h3(GVColors c) => _font(
        fontSize: fsH3,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: c.txt,
      );

  static TextStyle body(GVColors c, {FontWeight weight = FontWeight.w600, Color? color}) =>
      _font(
        fontSize: fsBody,
        fontWeight: weight,
        height: 1.4,
        color: color ?? c.txt,
      );

  static TextStyle sm(GVColors c, {FontWeight weight = FontWeight.w500, Color? color}) =>
      _font(
        fontSize: fsSm,
        fontWeight: weight,
        height: 1.5,
        color: color ?? c.mut,
      );

  static TextStyle xs(GVColors c, {FontWeight weight = FontWeight.w600, Color? color, double? letterSpacing}) =>
      _font(
        fontSize: fsXs,
        fontWeight: weight,
        height: 1.5,
        letterSpacing: letterSpacing,
        color: color ?? c.mut,
      );

  static TextStyle xs2(GVColors c, {FontWeight weight = FontWeight.w700, Color? color, double? letterSpacing}) =>
      _font(
        fontSize: fs2xs,
        fontWeight: weight,
        height: 1.2,
        letterSpacing: letterSpacing,
        color: color ?? c.mut,
      );
}

class GoldTheme {
  static ThemeData build(Brightness brightness) {
    final c = brightness == Brightness.dark ? GVColors.dark : GVColors.light;
    final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
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
      textTheme: base.textTheme.apply(
        fontFamily: kIsWeb ? GoogleFonts.plusJakartaSans().fontFamily : null,
        bodyColor: c.txt,
        displayColor: c.txt,
      ),
      dividerColor: c.line,
    );
  }
}

class GoldVaultLogo extends StatelessWidget {
  final double fontSize;
  const GoldVaultLogo({super.key, this.fontSize = GVTxt.fsH2});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size(fontSize * 1.1, fontSize * 1.1),
            painter: _VaultArchPainter(c.acc),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: GVTxt._font(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -0.3,
                color: c.txt,
              ),
              children: [
                const TextSpan(text: 'Gold'),
                TextSpan(text: 'Vault', style: TextStyle(color: c.acc)),
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
      ..strokeWidth = 2.2 * sx
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
      ..strokeWidth = 1.7 * sx
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
