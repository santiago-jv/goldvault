import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/gold_theme.dart';

class TrendMonthData {
  final String ym;
  final int inc;
  final int exp;

  const TrendMonthData({required this.ym, required this.inc, required this.exp});
}

class TrendChartWidget extends StatelessWidget {
  final List<MovementModel> spaceMovements;
  final String currentYm;

  const TrendChartWidget({
    super.key,
    required this.spaceMovements,
    required this.currentYm,
  });

  List<TrendMonthData> _computeData() {
    final parts = currentYm.split('-');
    final y = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    final list = <TrendMonthData>[];

    for (var i = 5; i >= 0; i--) {
      var mm = m - i;
      var yy = y;
      while (mm < 1) {
        mm += 12;
        yy--;
      }
      final key = '$yy-${mm.toString().padLeft(2, '0')}';
      final rows = spaceMovements.where((x) => x.date.startsWith(key) && x.status != 'cancelled');
      final inc = rows.where((r) => r.type == 'income').fold(0, (a, x) => a + x.amount);
      final exp = rows.where((r) => r.type == 'expense').fold(0, (a, x) => a + x.amount);
      list.add(TrendMonthData(ym: key, inc: inc, exp: exp));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final data = _computeData();
    final hasData = data.any((d) => d.inc > 0 || d.exp > 0);

    if (!hasData) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 28, color: c.mut),
              const SizedBox(height: 8),
              Text('Aún no hay historial suficiente.', style: GVTxt.sm(c)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 150,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendBarPainter(data: data, colors: c),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(c.acc, 'Ingresos', c),
            const SizedBox(width: 18),
            _legendDot(c.mut.withValues(alpha: 0.45), 'Gastos', c),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color dotColor, String label, GVColors c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: GVTxt.xs(c)),
      ],
    );
  }
}

class _TrendBarPainter extends CustomPainter {
  final List<TrendMonthData> data;
  final GVColors colors;

  _TrendBarPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.fold<int>(1, (prev, d) => max(prev, max(d.inc, d.exp)));
    const pad = 12.0;
    final base = size.height - 24.0;
    const top = 14.0;
    final slot = (size.width - pad * 2) / data.length;

    final gridPaint = Paint()
      ..color = colors.line
      ..strokeWidth = 1.0;

    for (final f in [0.0, 0.5, 1.0]) {
      final yy = base - (base - top) * f;
      canvas.drawLine(Offset(pad, yy), Offset(size.width - pad, yy), gridPaint);
    }

    final maxTp = TextPainter(
      text: TextSpan(
        text: formatCompact(maxVal),
        style: TextStyle(color: colors.mut, fontSize: 10, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    maxTp.paint(canvas, const Offset(pad, 0));

    final incPaint = Paint()..color = colors.acc;
    final expPaint = Paint()..color = colors.mut.withValues(alpha: 0.45);

    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final x0 = pad + i * slot;
      final bw = (slot - 12) / 2;
      final hi = (d.inc / maxVal) * (base - top);
      final he = (d.exp / maxVal) * (base - top);

      if (hi > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x0 + 3, base - hi, bw, hi), const Radius.circular(3)),
          incPaint,
        );
      }
      if (he > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x0 + 5 + bw, base - he, bw, he), const Radius.circular(3)),
          expPaint,
        );
      }

      final monIdx = (int.tryParse(d.ym.substring(5)) ?? 1).clamp(1, 12) - 1;
      final monLbl = kMonthsEs[monIdx].substring(0, 3);
      final tp = TextPainter(
        text: TextSpan(
          text: monLbl,
          style: TextStyle(color: colors.mut, fontSize: 10, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x0 + slot / 2 - tp.width / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendBarPainter oldDelegate) => true;
}

class DonutChartWidget extends StatelessWidget {
  final Map<String, int> byCat;
  final int totalExpense;

  const DonutChartWidget({
    super.key,
    required this.byCat,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (byCat.isEmpty || totalExpense <= 0) return const SizedBox.shrink();
    final c = GVColors.of(context);
    final sorted = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final rest = sorted.skip(5).fold<int>(0, (a, e) => a + e.value);
    final segs = <MapEntry<String, int>>[
      ...top,
      if (rest > 0) MapEntry('Otras', rest),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 122,
            height: 122,
            child: CustomPaint(
              painter: _DonutPainter(
                segs: segs,
                total: totalExpense,
                colors: c,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('TOTAL', style: GVTxt.xs2(c, letterSpacing: 1.0)),
                    const SizedBox(height: 2),
                    Text(
                      formatCompact(totalExpense),
                      style: GVTxt.h3(c).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: List.generate(segs.length, (i) {
                final seg = segs[i];
                final pct = ((seg.value / totalExpense) * 100).round();
                final col = c.chartPalette[i % c.chartPalette.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          seg.key,
                          style: GVTxt.xs(c, color: c.mut),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('$pct%', style: GVTxt.xs(c, weight: FontWeight.w800, color: c.txt)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, int>> segs;
  final int total;
  final GVColors colors;

  _DonutPainter({required this.segs, required this.total, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var startAngle = -pi / 2;

    for (var i = 0; i < segs.length; i++) {
      final sweep = (segs[i].value / total) * 2 * pi;
      final paint = Paint()
        ..color = colors.chartPalette[i % colors.chartPalette.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
