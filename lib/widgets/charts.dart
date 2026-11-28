import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme/gold_theme.dart';
import 'gv_motion.dart';

class TrendMonthData {
  final String ym;
  final int inc;
  final int exp;

  const TrendMonthData({required this.ym, required this.inc, required this.exp});
}

class TrendChartWidget extends StatelessWidget {
  final List<MovementModel> spaceMovements;
  final String currentYm;

  const TrendChartWidget({super.key, required this.spaceMovements, required this.currentYm});

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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final data = _computeData();
    final hasData = data.any((d) => d.inc > 0 || d.exp > 0);

    if (!hasData) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 24, color: c.mut),
              const SizedBox(height: 8),
              Text('Aún no hay historial suficiente.', style: GVTxt.xs(c)),
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
          child: TweenAnimationBuilder<double>(
            key: ValueKey('trend-$currentYm'),
            tween: Tween<double>(begin: reduceMotion ? 1.0 : 0.0, end: 1.0),
            duration: reduceMotion ? Duration.zero : GVMotion.chart,
            curve: GVMotion.standard,
            builder: (context, progress, _) {
              return CustomPaint(
                painter: _TrendBarPainter(data: data, colors: c, progress: progress),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(c.green, 'Ingresos', c),
            const SizedBox(width: 18),
            _legendDot(c.red, 'Gastos', c),
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
  final double progress;

  _TrendBarPainter({required this.data, required this.colors, required this.progress});

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

    final incPaint = Paint()..color = colors.green.withValues(alpha: 0.92);
    final expPaint = Paint()..color = colors.red.withValues(alpha: 0.88);

    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final x0 = pad + i * slot;
      final bw = (slot - 12) / 2;
      final localT = ((progress - i * 0.06) / 0.70).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(localT);
      final hi = (d.inc / maxVal) * (base - top) * eased;
      final he = (d.exp / maxVal) * (base - top) * eased;

      if (hi > 0.5) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x0 + 3, base - hi, bw, hi),
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          ),
          incPaint,
        );
      }
      if (he > 0.5) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x0 + 5 + bw, base - he, bw, he),
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          ),
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
  bool shouldRepaint(covariant _TrendBarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.data != data || oldDelegate.colors != colors;
}

/// Interactive radial donut chart: tapping a slice or legend item expands that
/// slice outward and morphs the center readout to display the selected category.
class DonutChartWidget extends StatefulWidget {
  final Map<String, int> byCat;
  final int totalExpense;

  const DonutChartWidget({super.key, required this.byCat, required this.totalExpense});

  @override
  State<DonutChartWidget> createState() => _DonutChartWidgetState();
}

class _DonutChartWidgetState extends State<DonutChartWidget> {
  int? _selectedIndex;

  void _toggleIndex(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
  }

  void _handleRingTap(TapUpDetails details, List<MapEntry<String, int>> segs) {
    const center = Offset(64, 64);
    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 32 || dist > 64) {
      if (_selectedIndex != null) setState(() => _selectedIndex = null);
      return;
    }
    var angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;

    var cursor = 0.0;
    for (var i = 0; i < segs.length; i++) {
      final sweep = (segs[i].value / widget.totalExpense) * 2 * pi;
      if (angle >= cursor && angle <= cursor + sweep) {
        _toggleIndex(i);
        return;
      }
      cursor += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.byCat.isEmpty || widget.totalExpense <= 0) return const SizedBox.shrink();
    final c = GVColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final sorted = widget.byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final rest = sorted.skip(5).fold<int>(0, (a, e) => a + e.value);
    final segs = <MapEntry<String, int>>[...top, if (rest > 0) MapEntry('Otras', rest)];

    final activeIdx = (_selectedIndex != null && _selectedIndex! < segs.length)
        ? _selectedIndex
        : null;
    final activeSeg = activeIdx != null ? segs[activeIdx] : null;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Row(
        children: [
          GestureDetector(
            onTapUp: (details) => _handleRingTap(details, segs),
            child: SizedBox(
              width: 128,
              height: 128,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: reduceMotion ? 1.0 : 0.0, end: 1.0),
                duration: reduceMotion ? Duration.zero : GVMotion.chart,
                curve: GVMotion.standard,
                builder: (context, progress, child) {
                  return TweenAnimationBuilder<double>(
                    key: ValueKey<int?>(activeIdx),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
                    curve: Curves.easeOutBack,
                    builder: (context, selectT, _) {
                      return CustomPaint(
                        painter: _DonutPainter(
                          segs: segs,
                          total: widget.totalExpense,
                          colors: c,
                          progress: progress,
                          selectedIndex: activeIdx,
                          selectT: selectT,
                        ),
                        child: child,
                      );
                    },
                  );
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AnimatedSwitcher(
                      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.90, end: 1.0).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Column(
                        key: ValueKey<String>(activeSeg?.key ?? 'total'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            activeSeg != null ? activeSeg.key.toUpperCase() : 'TOTAL',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GVTxt.xs2(
                              c,
                              letterSpacing: 0.8,
                              color: activeIdx != null
                                  ? c.chartPalette[activeIdx % c.chartPalette.length]
                                  : c.tertiary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatCompact(activeSeg?.value ?? widget.totalExpense),
                            style: GVTxt.h3(c, tabular: true).copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: List.generate(segs.length, (i) {
                final seg = segs[i];
                final pct = ((seg.value / widget.totalExpense) * 100).round();
                final col = c.chartPalette[i % c.chartPalette.length];
                final isSelected = activeIdx == i;
                final dimmed = activeIdx != null && !isSelected;
                return InkWell(
                  onTap: () => _toggleIndex(i),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedOpacity(
                    duration: reduceMotion ? Duration.zero : GVMotion.fast,
                    opacity: dimmed ? 0.42 : 1.0,
                    child: AnimatedContainer(
                      duration: reduceMotion ? Duration.zero : GVMotion.fast,
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? col.withValues(alpha: 0.10) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: reduceMotion ? Duration.zero : GVMotion.fast,
                            width: isSelected ? 10 : 8,
                            height: isSelected ? 10 : 8,
                            decoration: BoxDecoration(
                              color: col,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              seg.key,
                              style: GVTxt.xs(
                                c,
                                color: isSelected ? c.txt : c.mut,
                                weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: GVTxt.xs(
                              c,
                              weight: FontWeight.w800,
                              color: c.txt,
                              tabular: true,
                            ),
                          ),
                        ],
                      ),
                    ),
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
  final double progress;
  final int? selectedIndex;
  final double selectT;

  _DonutPainter({
    required this.segs,
    required this.total,
    required this.colors,
    required this.progress,
    required this.selectedIndex,
    required this.selectT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width / 2) - 14;

    final trackPaint = Paint()
      ..color = colors.card2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(center, baseRadius, trackPaint);

    var startAngle = -pi / 2;
    final totalSweepLimit = 2 * pi * progress;
    var drawn = 0.0;

    for (var i = 0; i < segs.length; i++) {
      final rawSweep = (segs[i].value / total) * 2 * pi;
      final remaining = totalSweepLimit - drawn;
      if (remaining <= 0) break;
      final sweep = min(rawSweep, remaining);
      final isSelected = selectedIndex == i;
      final dimmed = selectedIndex != null && !isSelected;

      final radius = isSelected ? baseRadius + (3.5 * selectT) : baseRadius;
      final stroke = isSelected ? 14.0 + (3.5 * selectT) : 14.0;
      final baseColor = colors.chartPalette[i % colors.chartPalette.length];

      final paint = Paint()
        ..color = dimmed ? baseColor.withValues(alpha: 0.30) : baseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += rawSweep;
      drawn += rawSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.total != total ||
      oldDelegate.colors != colors ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.selectT != selectT;
}
