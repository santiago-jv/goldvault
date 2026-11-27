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
          GVCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                Icon(Icons.track_changes_rounded, size: 32, color: c.tertiary),
                const SizedBox(height: 10),
                Text('Aún no has definido metas de ahorro.', style: GVTxt.sm(c)),
              ],
            ),
          )
        else
          ...goals.map((g) {
            final saved = state.goalSaved(g.id);
            final pct = g.target > 0 ? ((saved / g.target) * 100).clamp(0.0, 100.0) : 0.0;
            final done = pct >= 100;
            final accent = done ? c.green : c.blue;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GVCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GVSquircleIcon(
                          size: 38,
                          radius: 11,
                          backgroundColor: accent.withValues(alpha: 0.12),
                          borderColor: accent.withValues(alpha: 0.24),
                          child: Icon(
                            done ? Icons.emoji_events_rounded : Icons.savings_outlined,
                            size: 19,
                            color: accent,
                          ),
                        ),
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
                            style: GVTxt.xs(c, weight: FontWeight.w600, color: c.txt, tabular: true),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 4),
        GVPillButton(
          label: '＋ Nueva meta',
          variant: GVPillButtonVariant.secondary,
          onPressed: () => showAddGoalSheet(context, state),
        ),
      ],
    );
  }
}
