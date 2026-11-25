import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/gold_theme.dart';

/// Elevated Apple Bento card surface with subtle hairline border and soft shadow.
class GVCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool anodized;
  final VoidCallback? onTap;

  const GVCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.radius = GVRadius.bento,
    this.color,
    this.borderColor,
    this.anodized = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final decoration = anodized
        ? BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF232328), Color(0xFF141418), Color(0xFF0C0C0E)],
              stops: [0.0, 0.55, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? const Color(0x24FFFFFF),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          )
        : BoxDecoration(
            color: color ?? c.card,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? c.line, width: 1),
            boxShadow: c.cardShadow,
          );

    final content = Container(
      margin: margin,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: Colors.transparent,
          child: onTap != null
              ? InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(radius),
                  child: Padding(padding: padding, child: child),
                )
              : Padding(padding: padding, child: child),
        ),
      ),
    );
    return content;
  }
}

/// Squircle icon container matching Apple Settings / Portfolio Bento icon tiles.
class GVSquircleIcon extends StatelessWidget {
  final Widget child;
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;

  const GVSquircleIcon({
    super.key,
    required this.child,
    this.size = 42,
    this.backgroundColor,
    this.borderColor,
    this.radius = GVRadius.squircle,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? c.card2,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.line),
      ),
      child: child,
    );
  }
}

enum GVPillButtonVariant { primary, dark, secondary, danger }

/// Full-capsule Apple-style button with tactile typography and clean states.
class GVPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final GVPillButtonVariant variant;
  final Widget? leading;
  final bool fullWidth;
  final bool compact;

  const GVPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GVPillButtonVariant.primary,
    this.leading,
    this.fullWidth = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final Color bg;
    final Color fg;
    final Color? border;

    switch (variant) {
      case GVPillButtonVariant.primary:
        bg = c.acc;
        fg = c.ink;
        border = null;
      case GVPillButtonVariant.dark:
        bg = c.isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F);
        fg = c.isDark ? const Color(0xFF121214) : Colors.white;
        border = null;
      case GVPillButtonVariant.secondary:
        bg = c.card2;
        fg = c.txt;
        border = c.line;
      case GVPillButtonVariant.danger:
        bg = c.red.withValues(alpha: 0.11);
        fg = c.red;
        border = c.red.withValues(alpha: 0.22);
    }

    final button = Material(
      color: onPressed == null ? bg.withValues(alpha: 0.45) : bg,
      shape: StadiumBorder(
        side: border != null ? BorderSide(color: border) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 22,
            vertical: compact ? 10 : 14,
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: (compact
                          ? GVTxt.sm(c, weight: FontWeight.w600, color: fg)
                          : GVTxt.body(c, weight: FontWeight.w600, color: fg))
                      .copyWith(letterSpacing: -0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// iOS-inspired segmented control with elevated thumb inside a recessed track.
class GVSegmentedControl<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;
  final bool compact;

  const GVSegmentedControl({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.card2,
        borderRadius: BorderRadius.circular(GVRadius.control),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: items.map((entry) {
          final selected = entry.$1 == value;
          final child = GestureDetector(
            onTap: () => onChanged(entry.$1),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 10,
                vertical: compact ? 6 : 7,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? (c.isDark ? c.acc : c.card) : Colors.transparent,
                borderRadius: BorderRadius.circular(GVRadius.control - 2),
                boxShadow: selected && !c.isDark
                    ? const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                entry.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GVTxt.xs(
                  c,
                  weight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? (c.isDark ? c.ink : c.txt) : c.mut,
                ),
              ),
            ),
          );
          return compact ? child : Expanded(child: child);
        }).toList(),
      ),
    );
  }
}

/// Clean Apple stone/obsidian inset text input.
class GVTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;

  const GVTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card2,
        borderRadius: BorderRadius.circular(GVRadius.control),
        border: Border.all(color: c.lineStrong),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        style: GVTxt.body(c),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GVTxt.sm(c, color: c.placeholder),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: c.tertiary) : null,
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: prefixIcon != null ? 4 : 14,
            vertical: 13,
          ),
        ),
      ),
    );
  }
}

/// Subtle pill badge for bank tags, statuses, and metadata.
class GVPillBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? backgroundColor;
  final IconData? icon;

  const GVPillBadge({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final fg = color ?? c.acc;
    final bg = backgroundColor ?? fg.withValues(alpha: c.isDark ? 0.16 : 0.11);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(GVRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GVTxt.xs2(c, color: fg, weight: FontWeight.w600, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

/// Apple-style section heading with optional uppercase eyebrow and trailing action.
class GVSectionHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final Widget? trailing;

  const GVSectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: GVTxt.xs2(c, color: c.tertiary, weight: FontWeight.w600, letterSpacing: 0.7),
                ),
                const SizedBox(height: 2),
              ],
              Text(title, style: GVTxt.h3(c)),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

/// Compact capsule month selector (`< Nov 2026 >`).
class GVMonthStepper extends StatelessWidget {
  final String ym;
  final ValueChanged<int> onShift;

  const GVMonthStepper({super.key, required this.ym, required this.onShift});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(GVRadius.pill),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(c, Icons.chevron_left_rounded, () => onShift(-1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              monthShortLabel(ym),
              style: GVTxt.xs(c, weight: FontWeight.w600, color: c.txt, tabular: true),
            ),
          ),
          _stepBtn(c, Icons.chevron_right_rounded, () => onShift(1)),
        ],
      ),
    );
  }

  Widget _stepBtn(GVColors c, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 17, color: c.mut),
      ),
    );
  }
}

/// Compact sync recovery banner rendered when pending cloud writes or sync errors exist.
class GVSyncBanner extends StatelessWidget {
  final GoldVaultState state;

  const GVSyncBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final message = state.syncError ??
        '${state.pendingSyncCount} cambio(s) pendiente(s) por sincronizar con la nube.';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: c.amber.withValues(alpha: c.isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(GVRadius.control),
        border: Border.all(color: c.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            state.syncError != null ? Icons.sync_problem_rounded : Icons.cloud_upload_outlined,
            size: 18,
            color: c.amber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GVTxt.xs(c, color: c.txt, weight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: state.loadingCloud ? null : () => state.retrySync(),
            borderRadius: BorderRadius.circular(GVRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: c.amber.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(GVRadius.pill),
              ),
              child: state.loadingCloud
                  ? SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(c.amber),
                      ),
                    )
                  : Text(
                      'Reintentar',
                      style: GVTxt.xs(c, color: c.amber, weight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Apple Wallet-style movement row designed to live inside a grouped `GVCard`.
class GVMovementRow extends StatelessWidget {
  final GoldVaultState state;
  final MovementModel movement;
  final VoidCallback onTap;
  final bool showDivider;

  const GVMovementRow({
    super.key,
    required this.state,
    required this.movement,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final isInc = movement.type == 'income';
    final isSav = movement.type == 'saving';
    final amtColor = isInc ? c.green : (isSav ? c.blue : c.txt);
    final sign = isInc ? '+' : '−';
    final sub = isInc
        ? (movement.source ?? 'Ingreso')
        : (isSav ? state.goalName(movement.goalId) : (movement.category ?? 'Otros'));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                GVSquircleIcon(
                  size: 40,
                  backgroundColor: isInc
                      ? c.green.withValues(alpha: 0.12)
                      : (isSav ? c.blue.withValues(alpha: 0.12) : c.card2),
                  borderColor: isInc
                      ? c.green.withValues(alpha: 0.22)
                      : (isSav ? c.blue.withValues(alpha: 0.22) : c.line),
                  child: isInc
                      ? Icon(Icons.south_west_rounded, size: 18, color: c.green)
                      : isSav
                          ? Icon(Icons.savings_outlined, size: 18, color: c.blue)
                          : Icon(
                              categoryIconData(movement.category),
                              size: 18,
                              color: c.txt,
                            ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement.desc.isNotEmpty ? movement.desc : sub,
                        style: GVTxt.body(c, weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '$sub${movement.account != null ? ' · ${movement.account}' : ''}${movement.fx != null ? ' · US\$${movement.fx!.amount}' : ''}',
                            style: GVTxt.xs(c),
                          ),
                          if (movement.autoBank != null && movement.autoBank!.isNotEmpty)
                            GVPillBadge(label: '⚡ ${movement.autoBank!}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$sign${formatMoney(movement.amount)}',
                      style: GVTxt.body(c, weight: FontWeight.w600, color: amtColor, tabular: true),
                    ),
                    if (!isInc) ...[
                      const SizedBox(height: 4),
                      GVPillBadge(
                        label: movement.status == 'paid' ? 'Pagado' : 'Pendiente',
                        color: movement.status == 'paid' ? c.green : c.amber,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(left: 58),
              child: Divider(height: 1, thickness: 1, color: c.line),
            ),
        ],
      ),
    );
  }
}

/// Frosted Apple-style glass bottom dock with integrated central quick-add action.
/// Replaces the generic Material NavigationBar + overlapping FAB.
class GVGlassDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  const GVGlassDock({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: c.navGlass,
            border: Border(top: BorderSide(color: c.line, width: 1)),
          ),
          padding: EdgeInsets.fromLTRB(8, 8, 8, bottomInset > 0 ? bottomInset : 10),
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Row(
                children: [
                  _tabItem(c, 0, Icons.home_outlined, Icons.home_rounded, 'Inicio'),
                  _tabItem(c, 1, Icons.format_list_bulleted_rounded, Icons.format_list_bulleted_rounded, 'Movs'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Tooltip(
                      message: 'Nuevo movimiento',
                      child: Material(
                        color: c.acc,
                        shape: const CircleBorder(),
                        elevation: 0,
                        child: InkWell(
                          onTap: onAdd,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.add_rounded, color: c.ink, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _tabItem(c, 2, Icons.track_changes_rounded, Icons.track_changes_rounded, 'Metas'),
                  _tabItem(c, 3, Icons.settings_outlined, Icons.settings_rounded, 'Ajustes'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabItem(
    GVColors c,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final active = selectedIndex == index;
    final color = active ? c.acc : c.mut;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(index),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? activeIcon : icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GVTxt.xs2(
                  c,
                  color: color,
                  weight: active ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Official Google "G" vector mark rendered via CustomPainter for Sign-In buttons.
class GoogleGIcon extends StatelessWidget {
  final double size;
  const GoogleGIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Google',
      child: CustomPaint(
        size: Size.square(size),
        painter: _GoogleGPainter(),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.19;
    final center = Offset(s / 2, s / 2);
    final radius = (s - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arcPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Red top-left arc (-145 deg to -42 deg)
    canvas.drawArc(rect, -145 * math.pi / 180, 103 * math.pi / 180, false, arcPaint(const Color(0xFFEA4335)));
    // Yellow left arc (145 deg to 217 deg)
    canvas.drawArc(rect, 145 * math.pi / 180, 72 * math.pi / 180, false, arcPaint(const Color(0xFFFBBC05)));
    // Green bottom arc (40 deg to 147 deg)
    canvas.drawArc(rect, 40 * math.pi / 180, 107 * math.pi / 180, false, arcPaint(const Color(0xFF34A853)));
    // Blue right-bottom arc (-5 deg to 43 deg)
    canvas.drawArc(rect, -5 * math.pi / 180, 48 * math.pi / 180, false, arcPaint(const Color(0xFF4285F4)));

    // Blue horizontal crossbar from center to outer right edge
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barTop = center.dy - stroke * 0.48;
    canvas.drawRect(
      Rect.fromLTRB(center.dx, barTop, s - stroke * 0.04, barTop + stroke * 0.96),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
