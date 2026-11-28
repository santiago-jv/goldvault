import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme/gold_theme.dart';

/// Shared Apple-inspired motion durations, curves, and spring physics across GoldVault.
class GVMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration chart = Duration(milliseconds: 620);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphatic = Curves.easeOutExpo;

  /// Tactile iOS-like spring physics (snappy bounce with gentle settle).
  static const SpringDescription snappySpring = SpringDescription(
    mass: 1.0,
    stiffness: 480.0,
    damping: 22.0,
  );
}

/// Tactile pressable wrapper driven by real [SpringSimulation] physics on release
/// with optional light haptic feedback, respecting reduced-motion preferences.
class GVSpringTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double pressedScale;
  final bool haptic;

  const GVSpringTap({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.pressedScale = 0.95,
    this.haptic = false,
  });

  @override
  State<GVSpringTap> createState() => _GVSpringTapState();
}

class _GVSpringTapState extends State<GVSpringTap> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController.unbounded(vsync: this, value: 1.0);
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _pressDown(bool reduceMotion) {
    if (reduceMotion) return;
    _scaleCtrl.animateTo(
      widget.pressedScale,
      duration: const Duration(milliseconds: 95),
      curve: Curves.easeOutCubic,
    );
  }

  void _releaseSpring(bool reduceMotion) {
    if (reduceMotion) {
      _scaleCtrl.value = 1.0;
      return;
    }
    final sim = SpringSimulation(GVMotion.snappySpring, _scaleCtrl.value, 1.0, 0.0);
    _scaleCtrl.animateWith(sim);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final active = widget.enabled && (widget.onTap != null || widget.enabled);
    final scaled = AnimatedBuilder(
      animation: _scaleCtrl,
      builder: (context, child) => Transform.scale(scale: _scaleCtrl.value, child: child),
      child: widget.child,
    );

    return Listener(
      onPointerDown: active ? (_) => _pressDown(reduceMotion) : null,
      onPointerUp: (_) => _releaseSpring(reduceMotion),
      onPointerCancel: (_) => _releaseSpring(reduceMotion),
      child: widget.onTap != null
          ? GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap?.call();
              },
              child: scaled,
            )
          : scaled,
    );
  }
}

/// Smoothly rolls currency amounts when balances change across months or transactions.
class GVAnimatedMoney extends StatefulWidget {
  final int amount;
  final TextStyle style;
  final String prefix;
  final Duration duration;

  const GVAnimatedMoney({
    super.key,
    required this.amount,
    required this.style,
    this.prefix = '',
    this.duration = GVMotion.slow,
  });

  @override
  State<GVAnimatedMoney> createState() => _GVAnimatedMoneyState();
}

class _GVAnimatedMoneyState extends State<GVAnimatedMoney> {
  late double _previous;

  @override
  void initState() {
    super.initState();
    _previous = widget.amount.toDouble();
  }

  @override
  void didUpdateWidget(covariant GVAnimatedMoney oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _previous = oldWidget.amount.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return Text('${widget.prefix}${formatMoney(widget.amount)}', style: widget.style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _previous, end: widget.amount.toDouble()),
      duration: widget.duration,
      curve: GVMotion.emphatic,
      builder: (context, value, _) {
        return Text('${widget.prefix}${formatMoney(value.round())}', style: widget.style);
      },
    );
  }
}

/// Smoothly fills progress bars (budgets, savings goals) with rounded pill geometry.
class GVAnimatedProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color? backgroundColor;
  final double height;

  const GVAnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.backgroundColor,
    this.height = 5.5,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final clamped = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(GVRadius.pill),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: clamped),
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 540),
        curve: GVMotion.standard,
        builder: (context, animatedValue, _) {
          return LinearProgressIndicator(
            value: animatedValue,
            minHeight: height,
            backgroundColor: backgroundColor ?? c.card2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          );
        },
      ),
    );
  }
}

/// Subtle staggered fade + vertical glide entrance for cards and sections.
class GVFadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  final double offsetY;

  const GVFadeSlideIn({super.key, required this.child, this.index = 0, this.offsetY = 10});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) return child;

    final delayMs = (index * 45).clamp(0, 220);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, childWidget) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, (1 - t) * offsetY), child: childWidget),
        );
      },
      child: child,
    );
  }
}
