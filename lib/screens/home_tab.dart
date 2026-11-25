import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/gold_theme.dart';
import '../widgets/charts.dart';
import '../widgets/gv_components.dart';
import 'space_modals.dart';

class HomeTab extends StatefulWidget {
  final GoldVaultState state;
  final TextEditingController quickController;
  final VoidCallback onSubmitQuickEntry;
  final void Function({MovementModel? editing, MovementModel? prefilled}) onOpenSheet;
  final VoidCallback? onNavigateMovements;

  const HomeTab({
    super.key,
    required this.state,
    required this.quickController,
    required this.onSubmitQuickEntry,
    required this.onOpenSheet,
    this.onNavigateMovements,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _summaryTab = 'categories'; // 'categories' | 'trend' | 'accounts'

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final st = widget.state;
    final pend = st.pendingMovements;

    final recent = st.monthMovements.toList()..sort((a, b) => b.date.compareTo(a.date));

    final byCat = <String, int>{};
    for (final m in st.activeMonthMovements.where((x) => x.type == 'expense')) {
      final cat = m.category ?? 'Otros';
      byCat[cat] = (byCat[cat] ?? 0) + m.amount;
    }
    final catEntries = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCat = catEntries.isNotEmpty ? catEntries.first.value : 1;

    final byAcct = <String, int>{};
    for (final m in st.activeMonthMovements.where((x) => x.type != 'income')) {
      final acc = m.account ?? '—';
      byAcct[acc] = (byAcct[acc] ?? 0) + m.amount;
    }

    return RefreshIndicator(
      color: c.acc,
      onRefresh: () => st.syncAll(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
        children: [
          // 1. Minimal Top Bar: Space selector + Month stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => showSpacesSheet(context, st),
                borderRadius: BorderRadius.circular(GVRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(GVRadius.pill),
                    border: Border.all(color: c.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 15, color: c.txt),
                      const SizedBox(width: 6),
                      Text(
                        st.curSpace.name,
                        style: GVTxt.xs(c, weight: FontWeight.w600, color: c.txt),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: c.mut),
                    ],
                  ),
                ),
              ),
              GVMonthStepper(ym: st.ym, onShift: st.shiftMonth),
            ],
          ),
          const SizedBox(height: 26),

          // 2. Open, Calm Balance Hero (Revolut / Copilot / Apple Wallet style)
          _buildCalmHero(context, c, st),
          const SizedBox(height: 28),

          // 3. Pending payments (only when non-empty)
          if (pend.isNotEmpty) ...[
            _sectionLabel(
              c,
              'Pendiente por pagar',
              trailing: GVPillBadge(
                label: formatMoney(pend.fold(0, (a, x) => a + x.amount)),
                color: c.amber,
              ),
            ),
            const SizedBox(height: 8),
            GVCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: pend.take(4).toList().asMap().entries.map((entry) {
                  return GVMovementRow(
                    state: st,
                    movement: entry.value,
                    onTap: () => widget.onOpenSheet(editing: entry.value),
                    showDivider: entry.key < pend.take(4).length - 1,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),
          ],

          // 5. Recent Activity (Revolut / Apple Wallet style)
          if (recent.isNotEmpty) ...[
            _sectionLabel(
              c,
              'Actividad reciente',
              trailing: widget.onNavigateMovements != null
                  ? InkWell(
                      onTap: widget.onNavigateMovements,
                      borderRadius: BorderRadius.circular(GVRadius.pill),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Ver todos',
                          style: GVTxt.xs(c, weight: FontWeight.w600, color: c.blue),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            GVCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: recent.take(4).toList().asMap().entries.map((entry) {
                  return GVMovementRow(
                    state: st,
                    movement: entry.value,
                    onTap: () => widget.onOpenSheet(editing: entry.value),
                    showDivider: entry.key < recent.take(4).length - 1,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),
          ],

          // 6. Clean Monthly Overview (Categorías | Tendencia | Cuentas)
          _sectionLabel(c, 'Resumen'),
          const SizedBox(height: 8),
          GVCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GVSegmentedControl<String>(
                  value: _summaryTab,
                  items: const [
                    ('categories', 'Categorías'),
                    ('trend', 'Tendencia'),
                    ('accounts', 'Cuentas'),
                  ],
                  onChanged: (next) => setState(() => _summaryTab = next),
                ),
                const SizedBox(height: 16),
                if (_summaryTab == 'categories')
                  _buildCategoriesView(c, st, byCat, catEntries, maxCat)
                else if (_summaryTab == 'trend')
                  TrendChartWidget(
                    spaceMovements: st.spaceMovements,
                    currentYm: st.ym,
                  )
                else
                  _buildAccountsView(c, st, byAcct),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(GVColors c, String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GVTxt.sm(c, weight: FontWeight.w600, color: c.mut),
          ),
          ?trailing,
        ],
      ),
    );
  }

  /// Open, calm balance hero without heavy black slabs or nested boxes.
  Widget _buildCalmHero(BuildContext context, GVColors c, GoldVaultState st) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disponible este mes',
          style: GVTxt.sm(c, weight: FontWeight.w500, color: c.mut),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatMoney(st.monthAvailable),
            style: GVTxt.display(c).copyWith(fontSize: 42, letterSpacing: -1.6),
          ),
        ),
        const SizedBox(height: 18),
        // Clean inline metric strip separated by delicate hairlines
        IntrinsicHeight(
          child: Row(
            children: [
              _inlineMetric(c, 'Ingresos', st.monthIncome, Icons.south_west_rounded, c.green),
              VerticalDivider(width: 24, thickness: 1, color: c.line),
              _inlineMetric(c, 'Gastos', st.monthExpense, Icons.north_east_rounded, c.red),
              VerticalDivider(width: 24, thickness: 1, color: c.line),
              _inlineMetric(c, 'Ahorro', st.monthSaving, Icons.savings_outlined, c.blue),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Revolut-style minimalist action pills
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _actionPill(
              c,
              icon: Icons.add_rounded,
              label: 'Registrar',
              primary: true,
              onTap: () => widget.onOpenSheet(),
            ),
            _actionPill(
              c,
              icon: Icons.bolt_rounded,
              label: 'Rápido',
              onTap: () => _showQuickEntrySheet(context, c),
            ),
            if (st.curSpace.frequents.isNotEmpty)
              _actionPill(
                c,
                icon: Icons.repeat_rounded,
                label: 'Frecuentes',
                onTap: () => _showFrequentsSheet(context, c, st),
              ),
          ],
        ),
      ],
    );
  }

  Widget _inlineMetric(GVColors c, String label, int amount, IconData icon, Color iconColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GVTxt.xs(c, color: c.mut),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(amount),
              style: GVTxt.body(c, weight: FontWeight.w600, tabular: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionPill(
    GVColors c, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    final bg = primary ? c.acc : c.card;
    final fg = primary ? c.ink : c.txt;
    return Material(
      color: bg,
      shape: StadiumBorder(
        side: primary ? BorderSide.none : BorderSide(color: c.line),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: GVTxt.xs(c, weight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickEntrySheet(BuildContext context, GVColors c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final bottom = MediaQuery.of(sheetCtx).viewInsets.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 24),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.lineStrong,
                    borderRadius: BorderRadius.circular(GVRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Registro rápido', style: GVTxt.h3(c)),
              const SizedBox(height: 4),
              Text(
                'Escribe el gasto como hablas y lo prellenamos por ti.',
                style: GVTxt.xs(c),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GVTextField(
                      controller: widget.quickController,
                      hintText: 'Ej: 20 mil almuerzo en nequi',
                      prefixIcon: Icons.bolt_rounded,
                      onSubmitted: (_) {
                        Navigator.pop(sheetCtx);
                        widget.onSubmitQuickEntry();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: c.acc,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        widget.onSubmitQuickEntry();
                      },
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.arrow_upward_rounded, color: c.ink, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFrequentsSheet(BuildContext context, GVColors c, GoldVaultState st) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.lineStrong,
                    borderRadius: BorderRadius.circular(GVRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Pagos frecuentes', style: GVTxt.h3(c)),
              const SizedBox(height: 4),
              Text('Toca uno para registrarlo al instante en este mes.', style: GVTxt.xs(c)),
              const SizedBox(height: 14),
              ...st.curSpace.frequents.take(8).toList().asMap().entries.map((entry) {
                final idx = entry.key;
                final f = entry.value;
                final showDiv = idx < st.curSpace.frequents.take(8).length - 1;
                return Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        Navigator.pop(sheetCtx);
                        final mv = MovementModel(
                          id: genId('mv'),
                          space: st.curSpace.id,
                          date: todayIso(),
                          type: 'expense',
                          desc: f.desc,
                          amount: f.amount,
                          category: f.category,
                          account: f.account,
                          status: 'paid',
                        );
                        await st.saveMovement(mv);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Registrado: ${f.desc} ${formatMoney(f.amount)}')),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
                        child: Row(
                          children: [
                            GVSquircleIcon(
                              size: 36,
                              child: Icon(categoryIconData(f.category), size: 17, color: c.txt),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.desc, style: GVTxt.body(c, weight: FontWeight.w600)),
                                  Text(
                                    '${f.category} · ${f.account}',
                                    style: GVTxt.xs(c),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatMoney(f.amount),
                              style: GVTxt.body(c, weight: FontWeight.w600, tabular: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showDiv)
                      Padding(
                        padding: const EdgeInsets.only(left: 50),
                        child: Divider(height: 1, color: c.line),
                      ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesView(
    GVColors c,
    GoldVaultState st,
    Map<String, int> byCat,
    List<MapEntry<String, int>> catEntries,
    int maxCat,
  ) {
    if (catEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text('Sin gastos registrados este mes.', style: GVTxt.xs(c)),
        ),
      );
    }
    return Column(
      children: [
        DonutChartWidget(byCat: byCat, totalExpense: st.monthExpense),
        ...catEntries.take(6).toList().asMap().entries.map((item) {
          final i = item.key;
          final e = item.value;
          final cap = st.curSpace.budgets[e.key];
          final ratio = cap != null && cap > 0
              ? (e.value / cap).clamp(0.0, 1.0)
              : (e.value / maxCat).clamp(0.06, 1.0);
          final barCol = cap != null && cap > 0
              ? (e.value >= cap ? c.red : (e.value >= cap * 0.8 ? c.amber : c.blue))
              : c.chartPalette[i % c.chartPalette.length];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                GVSquircleIcon(
                  size: 36,
                  radius: 10,
                  child: Icon(categoryIconData(e.key), size: 17, color: c.txt),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GVTxt.sm(c, weight: FontWeight.w600, color: c.txt),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cap != null
                                ? '${formatMoney(e.value)} / ${formatMoney(cap)}'
                                : formatMoney(e.value),
                            style: GVTxt.sm(
                              c,
                              weight: FontWeight.w600,
                              color: c.txt,
                              tabular: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(GVRadius.pill),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 5,
                          backgroundColor: c.card2,
                          valueColor: AlwaysStoppedAnimation<Color>(barCol),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAccountsView(GVColors c, GoldVaultState st, Map<String, int> byAcct) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final tileWidth = constraints.maxWidth >= 240
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: st.curSpace.accounts.map((acc) {
            return Container(
              width: tileWidth,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.card2,
                borderRadius: BorderRadius.circular(GVRadius.control),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    acc,
                    style: GVTxt.xs(c, weight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatMoney(byAcct[acc] ?? 0),
                      style: GVTxt.body(c, weight: FontWeight.w700, tabular: true),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
