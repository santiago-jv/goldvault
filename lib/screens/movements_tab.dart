import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/gold_theme.dart';
import '../widgets/gv_components.dart';

class MovementsTab extends StatelessWidget {
  final GoldVaultState state;
  final void Function({MovementModel? editing, MovementModel? prefilled}) onOpenSheet;

  const MovementsTab({
    super.key,
    required this.state,
    required this.onOpenSheet,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    var list = state.monthMovements.toList()..sort((a, b) => b.date.compareTo(a.date));
    if (state.movFilter != 'all') {
      list = list
          .where((x) => state.movFilter == 'pending' ? x.status == 'pending' : x.type == state.movFilter)
          .toList();
    }
    if (state.movQuery.trim().isNotEmpty) {
      final nq = normText(state.movQuery);
      list = list.where((x) {
        final hay = normText('${x.desc} ${x.category ?? ''} ${x.account ?? ''} ${x.amount}');
        return hay.contains(nq);
      }).toList();
    }

    final grouped = <String, List<MovementModel>>{};
    for (final m in list) {
      grouped.putIfAbsent(m.date, () => []).add(m);
    }

    const filters = [
      ('all', 'Todos'),
      ('expense', 'Gastos'),
      ('saving', 'Ahorros'),
      ('income', 'Ingresos'),
      ('pending', 'Pendientes'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Movimientos', style: GVTxt.h1(c))),
            const SizedBox(width: 8),
            GVMonthStepper(ym: state.ym, onShift: state.shiftMonth),
          ],
        ),
        const SizedBox(height: 14),
        GVTextField(
          hintText: 'Buscar descripción, categoría, cuenta…',
          prefixIcon: Icons.search_rounded,
          onChanged: state.setMovQuery,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = filters[i];
              final on = state.movFilter == f.$1;
              return InkWell(
                onTap: () => state.setMovFilter(f.$1),
                borderRadius: BorderRadius.circular(GVRadius.pill),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: on ? c.acc : c.card,
                    borderRadius: BorderRadius.circular(GVRadius.pill),
                    border: Border.all(color: on ? c.acc : c.line),
                  ),
                  child: Text(
                    f.$2,
                    style: GVTxt.xs(
                      c,
                      weight: on ? FontWeight.w700 : FontWeight.w500,
                      color: on ? c.ink : c.txt,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (grouped.isEmpty)
          GVCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                Icon(Icons.receipt_long_rounded, size: 32, color: c.tertiary),
                const SizedBox(height: 10),
                Text(
                  state.movQuery.isNotEmpty
                      ? 'Nada coincide con tu búsqueda.'
                      : 'Sin movimientos en este periodo.',
                  style: GVTxt.sm(c),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...grouped.entries.map((entry) {
            final dt = DateTime.tryParse(entry.key) ?? DateTime.now();
            final dayTitle = '${dt.day} DE ${kMonthsEs[dt.month - 1].toUpperCase()}';
            final items = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 8),
                    child: Text(
                      dayTitle,
                      style: GVTxt.xs2(c, color: c.tertiary, weight: FontWeight.w700, letterSpacing: 0.7),
                    ),
                  ),
                  GVCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Column(
                      children: items.asMap().entries.map((rowEntry) {
                        return GVMovementRow(
                          state: state,
                          movement: rowEntry.value,
                          onTap: () => onOpenSheet(editing: rowEntry.value),
                          showDivider: rowEntry.key < items.length - 1,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
