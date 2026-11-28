import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/gold_theme.dart';
import '../widgets/gv_components.dart';
import '../widgets/gv_motion.dart';
import 'space_modals.dart';

class GoalsTab extends StatelessWidget {
  final GoldVaultState state;

  const GoalsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final goals = state.curSpace.goals;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        Text('Metas', style: GVTxt.h1(c)),
        const SizedBox(height: 16),
        if (goals.isEmpty)
          GVFadeSlideIn(
            index: 0,
            child: GVCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.track_changes_rounded, size: 32, color: c.tertiary),
                  const SizedBox(height: 10),
                  Text('Aún no has definido metas de ahorro.', style: GVTxt.sm(c)),
                ],
              ),
            ),
          )
        else
          ...goals.asMap().entries.map((entry) {
            final idx = entry.key;
            final g = entry.value;
            final saved = state.goalSaved(g.id);
            final pct = g.target > 0 ? ((saved / g.target) * 100).clamp(0.0, 100.0) : 0.0;
            final done = pct >= 100;
            final accent = done ? c.green : c.blue;
            return GVFadeSlideIn(
              index: idx,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GVCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _GoalIconBadge(done: done, accent: accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              g.name,
                              style: GVTxt.h3(c),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GVPillBadge(label: '${pct.toStringAsFixed(0)}%', color: accent),
                          IconButton(
                            onPressed: () => state.deleteGoal(g.id),
                            icon: Icon(Icons.delete_outline_rounded, size: 18, color: c.mut),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Eliminar meta',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GVAnimatedProgressBar(
                        value: (pct / 100.0).clamp(0.02, 1.0),
                        color: accent,
                        height: 6,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${formatMoney(saved)} ahorrado',
                              style: GVTxt.xs(c, tabular: true),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Meta: ${formatMoney(g.target)}',
                              style: GVTxt.xs(
                                c,
                                weight: FontWeight.w600,
                                color: c.txt,
                                tabular: true,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 16),
        GVPillButton(
          label: '＋ Nueva meta',
          variant: GVPillButtonVariant.secondary,
          onPressed: () => showAddGoalSheet(context, state),
        ),
      ],
    );
  }
}

class _GoalIconBadge extends StatefulWidget {
  final bool done;
  final Color accent;

  const _GoalIconBadge({required this.done, required this.accent});

  @override
  State<_GoalIconBadge> createState() => _GoalIconBadgeState();
}

class _GoalIconBadgeState extends State<_GoalIconBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    if (widget.done) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _GoalIconBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.done && !oldWidget.done) {
      _pulse.repeat(reverse: true);
    } else if (!widget.done && oldWidget.done) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final badge = GVSquircleIcon(
      size: 38,
      radius: 11,
      backgroundColor: widget.accent.withValues(alpha: 0.12),
      borderColor: widget.accent.withValues(alpha: 0.24),
      child: Icon(
        widget.done ? Icons.emoji_events_rounded : Icons.savings_outlined,
        size: 19,
        color: widget.accent,
      ),
    );

    if (!widget.done || reduceMotion) return badge;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.12 + 0.16 * _pulse.value),
                blurRadius: 8 + 8 * _pulse.value,
                spreadRadius: 1 + 1.5 * _pulse.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: badge,
    );
  }
}
