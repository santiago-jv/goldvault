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

  const HomeTab({
    super.key,
    required this.state,
    required this.quickController,
    required this.onSubmitQuickEntry,
    required this.onOpenSheet,
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
    final unrev = st.unreviewedBankMovements;
    final pend = st.pendingMovements;

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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          // Top bar: brand + space pill + month stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Flexible(child: GoldVaultLogo(fontSize: GVTxt.fsH2)),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => showSpacesSheet(context, st),
                      borderRadius: BorderRadius.circular(GVRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(GVRadius.pill),
                          border: Border.all(color: c.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              st.curSpace.name,
                              style: GVTxt.xs(c, weight: FontWeight.w600, color: c.txt),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.unfold_more_rounded, size: 14, color: c.mut),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GVMonthStepper(ym: st.ym, onShift: st.shiftMonth),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Hero Balance Card (Anodized Space Black + Apple Semantic Indicators)
          _buildHeroCard(c, st),
          const SizedBox(height: 14),

          // 2. Quick Entry Bar (+ compact frequent capsules if any)
          Row(
            children: [
              Expanded(
                child: GVTextField(
                  controller: widget.quickController,
                  hintText: 'Ej: 20 mil almuerzo en nequi',
                  prefixIcon: Icons.bolt_rounded,
                  onSubmitted: (_) => widget.onSubmitQuickEntry(),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: c.acc,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: widget.onSubmitQuickEntry,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(Icons.arrow_upward_rounded, color: c.ink, size: 20),
                  ),
                ),
              ),
            ],
          ),
          if (st.curSpace.frequents.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: st.curSpace.frequents.take(6).length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = st.curSpace.frequents[i];
                  return InkWell(
                    onTap: () async {
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
                    borderRadius: BorderRadius.circular(GVRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(GVRadius.pill),
                        border: Border.all(color: c.line),
                      ),
                      child: Row(
                        children: [
                          Text(f.desc, style: GVTxt.xs(c, weight: FontWeight.w600, color: c.txt)),
                          const SizedBox(width: 6),
                          Text(formatMoney(f.amount), style: GVTxt.xs(c, tabular: true)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),

          // 3. Action Needed: Auto-detected bank payments (clean, scannable rows)
          if (unrev.isNotEmpty) ...[
            GVCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GVSectionHeader(
                    title: 'Pagos por revisar (${unrev.length})',
                    trailing: InkWell(
                      onTap: () => st.confirmAllAutoBank(),
                      borderRadius: BorderRadius.circular(GVRadius.pill),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Confirmar todos',
                          style: GVTxt.xs(c, weight: FontWeight.w600, color: c.blue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...unrev.take(6).toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final x = entry.value;
                    final showDivider = idx < unrev.take(6).length - 1;
                    return Column(
                      children: [
                        InkWell(
                          onTap: () => widget.onOpenSheet(editing: x),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                GVSquircleIcon(
                                  size: 38,
                                  child: Icon(
                                    categoryIconData(x.category),
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
                                        x.desc.isEmpty ? 'Pago' : x.desc,
                                        style: GVTxt.body(c, weight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${x.autoBank ?? 'Banco'} · ${x.category ?? 'Otros'}${x.fx != null ? ' · US\$${x.fx!.amount}' : ''}',
                                        style: GVTxt.xs(c),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '−${formatMoney(x.amount)}',
                                  style: GVTxt.body(
                                    c,
                                    weight: FontWeight.w600,
                                    color: c.red,
                                    tabular: true,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () => st.confirmAutoBank(x.id),
                                  icon: Icon(Icons.check_circle_rounded, color: c.green, size: 22),
                                  tooltip: 'Confirmar',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                                IconButton(
                                  onPressed: () => st.deleteMovement(x.id),
                                  icon: Icon(Icons.close_rounded, color: c.mut, size: 19),
                                  tooltip: 'Descartar',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (showDivider)
                          Padding(
                            padding: const EdgeInsets.only(left: 50),
                            child: Divider(height: 1, color: c.line),
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Pending payments (only when non-empty)
          if (pend.isNotEmpty) ...[
            GVCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GVSectionHeader(
                    title: 'Pendiente por pagar',
                    trailing: GVPillBadge(
                      label: formatMoney(pend.fold(0, (a, x) => a + x.amount)),
                      color: c.amber,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...pend.take(4).toList().asMap().entries.map((entry) {
                    return GVMovementRow(
                      state: st,
                      movement: entry.value,
                      onTap: () => widget.onOpenSheet(editing: entry.value),
                      showDivider: entry.key < pend.take(4).length - 1,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 4. Unified Monthly Summary Card (Categorías | Tendencia | Cuentas)
          GVCard(
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
                const SizedBox(height: 18),
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

  Widget _buildCategoriesView(
    GVColors c,
    GoldVaultState st,
    Map<String, int> byCat,
    List<MapEntry<String, int>> catEntries,
    int maxCat,
  ) {
    if (catEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('Sin gastos registrados este mes.', style: GVTxt.sm(c)),
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
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    acc,
                    style: GVTxt.xs(c, weight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatMoney(byAcct[acc] ?? 0),
                      style: GVTxt.h3(c, tabular: true).copyWith(fontWeight: FontWeight.w700),
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

  /// Anodized Space Black Hero Card with crisp white balance and subtle Apple semantic dots.
  Widget _buildHeroCard(GVColors c, GoldVaultState st) {
    const heroWhite = Color(0xFFFFFFFF);
    const heroMut = Color(0xFFA1A1A6);

    return GVCard(
      anodized: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DISPONIBLE ESTE MES',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GVTxt.xs2(c, color: heroMut, weight: FontWeight.w600, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(st.monthAvailable),
              style: GVTxt.display(c, color: heroWhite),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _heroMetric(c, 'Ingresos', st.monthIncome, const Color(0xFF30D158)),
              const SizedBox(width: 8),
              _heroMetric(c, 'Gastos', st.monthExpense, const Color(0xFFFF453A)),
              const SizedBox(width: 8),
              _heroMetric(c, 'Ahorro', st.monthSaving, const Color(0xFF0A84FF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(GVColors c, String label, int amount, Color dotColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(GVRadius.control),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GVTxt.xs2(
                      c,
                      color: const Color(0xFFA1A1A6),
                      weight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatMoney(amount),
                style: GVTxt.body(
                  c,
                  weight: FontWeight.w700,
                  color: const Color(0xFFF5F5F7),
                  tabular: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
