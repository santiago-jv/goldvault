import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/gold_theme.dart';
import '../widgets/gv_components.dart';
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
        RichText(
          text: TextSpan(
            style: GVTxt.h1(c),
            children: [
              const TextSpan(text: 'Metas de '),
              TextSpan(text: 'ahorro', style: TextStyle(color: c.acc)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Define objetivos y mide tu progreso mes a mes.',
          style: GVTxt.sm(c),
        ),
        const SizedBox(height: 18),
        if (goals.isEmpty)
          GVCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                Icon(Icons.track_changes_rounded, size: 34, color: c.tertiary),
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GVCard(
                borderColor: done ? c.acc.withValues(alpha: 0.5) : c.line,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GVSquircleIcon(
                          size: 40,
                          radius: 12,
                          backgroundColor: c.acc.withValues(alpha: 0.12),
                          borderColor: c.acc.withValues(alpha: 0.25),
                          child: Icon(
                            done ? Icons.emoji_events_rounded : Icons.savings_outlined,
                            size: 20,
                            color: c.acc,
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
                        GVPillBadge(
                          label: '${pct.toStringAsFixed(0)}%',
                          color: done ? c.green : c.acc,
                        ),
                        IconButton(
                          onPressed: () => state.deleteGoal(g.id),
                          icon: Icon(Icons.delete_outline_rounded, size: 19, color: c.red),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Eliminar meta',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(GVRadius.pill),
                      child: LinearProgressIndicator(
                        value: (pct / 100.0).clamp(0.02, 1.0),
                        minHeight: 7,
                        backgroundColor: c.card2,
                        valueColor: AlwaysStoppedAnimation<Color>(done ? c.green : c.acc),
                      ),
                    ),
                    const SizedBox(height: 12),
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
        const SizedBox(height: 6),
        GVPillButton(
          label: '＋ Nueva meta',
          variant: GVPillButtonVariant.secondary,
          onPressed: () => showAddGoalSheet(context, state),
        ),
      ],
    );
  }
}
