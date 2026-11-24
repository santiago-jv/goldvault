import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/gold_theme.dart';
import '../widgets/charts.dart';
import '../widgets/gv_components.dart';
import 'space_modals.dart';

class HomeTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final unrev = state.unreviewedBankMovements;
    final pend = state.pendingMovements;

    final byCat = <String, int>{};
    for (final m in state.activeMonthMovements.where((x) => x.type == 'expense')) {
      final cat = m.category ?? 'Otros';
      byCat[cat] = (byCat[cat] ?? 0) + m.amount;
    }
    final catEntries = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCat = catEntries.isNotEmpty ? catEntries.first.value : 1;

    final byAcct = <String, int>{};
    for (final m in state.activeMonthMovements.where((x) => x.type != 'income')) {
      final acc = m.account ?? '—';
      byAcct[acc] = (byAcct[acc] ?? 0) + m.amount;
    }

    return RefreshIndicator(
      color: c.acc,
      onRefresh: () => state.syncAll(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          // Top navigation bar: brand + space pill + month stepper
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
                      onTap: () => showSpacesSheet(context, state),
                      borderRadius: BorderRadius.circular(GVRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(GVRadius.pill),
                          border: Border.all(color: c.line),
                        ),
                        child: Text(state.curSpace.emoji, style: const TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GVMonthStepper(ym: state.ym, onShift: state.shiftMonth),
            ],
          ),
          const SizedBox(height: 16),

          // Signature Anodized Space Black Pro Hero Vault Card
          _buildAnodizedHeroCard(c),
          const SizedBox(height: 14),

          // Natural-language quick entry bar
          Row(
            children: [
              Expanded(
                child: GVTextField(
                  controller: quickController,
                  hintText: 'Ej: 20 mil almuerzo en nequi',
                  prefixIcon: Icons.bolt_rounded,
                  onSubmitted: (_) => onSubmitQuickEntry(),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: c.acc,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onSubmitQuickEntry,
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
          const SizedBox(height: 12),

          // Quick frequent expense capsules
          if (state.curSpace.frequents.isNotEmpty) ...[
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.curSpace.frequents.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = state.curSpace.frequents[i];
                  return InkWell(
                    onTap: () async {
                      final mv = MovementModel(
                        id: genId('mv'),
                        space: state.curSpace.id,
                        date: todayIso(),
                        type: 'expense',
                        desc: f.desc,
                        amount: f.amount,
                        category: f.category,
                        account: f.account,
                        status: 'paid',
                      );
                      await state.saveMovement(mv);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registrado: ${f.desc} ${formatMoney(f.amount)}')),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(GVRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(GVRadius.pill),
                        border: Border.all(color: c.line),
                      ),
                      child: Row(
                        children: [
                          Text(state.curSpace.iconForCategory(f.category)),
                          const SizedBox(width: 6),
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
            const SizedBox(height: 16),
          ],

          // Auto-detected bank payments card
          if (unrev.isNotEmpty) ...[
            GVCard(
              borderColor: c.acc.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GVSectionHeader(
                    eyebrow: 'Lectura automática',
                    title: 'Pagos detectados',
                    trailing: InkWell(
                      onTap: () => state.confirmAllAutoBank(),
                      borderRadius: BorderRadius.circular(GVRadius.pill),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Confirmar todos',
                          style: GVTxt.xs(c, weight: FontWeight.w700, color: c.acc),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Registrados automáticamente desde tus bancos. Toca la categoría para ajustarla.',
                    style: GVTxt.sm(c),
                  ),
                  const SizedBox(height: 10),
                  ...unrev.take(8).toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final x = entry.value;
                    final showDivider = idx < unrev.take(8).length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            x.desc.isEmpty ? 'Pago' : x.desc,
                                            style: GVTxt.body(c, weight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '−${formatMoney(x.amount)}',
                                          style: GVTxt.body(
                                            c,
                                            weight: FontWeight.w700,
                                            color: c.red,
                                            tabular: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        GVPillBadge(label: '⚡ ${x.autoBank ?? 'Banco'}'),
                                        InkWell(
                                          onTap: () => onOpenSheet(editing: x),
                                          borderRadius: BorderRadius.circular(GVRadius.pill),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: c.card2,
                                              borderRadius: BorderRadius.circular(GVRadius.pill),
                                              border: Border.all(color: c.line),
                                            ),
                                            child: Text(
                                              '${state.curSpace.iconForCategory(x.category)} ${x.category ?? 'Otros'} ✎',
                                              style: GVTxt.xs2(c, weight: FontWeight.w600, color: c.txt),
                                            ),
                                          ),
                                        ),
                                        if (x.fx != null)
                                          Text('US\$${x.fx!.amount}', style: GVTxt.xs(c, tabular: true)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => state.confirmAutoBank(x.id),
                                icon: Icon(Icons.check_circle_outline_rounded, color: c.green, size: 22),
                                tooltip: 'Confirmar',
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                onPressed: () => state.deleteMovement(x.id),
                                icon: Icon(Icons.delete_outline_rounded, color: c.red, size: 20),
                                tooltip: 'Descartar',
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                        if (showDivider) Divider(height: 1, color: c.line),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Pending payments Bento card
          if (pend.isNotEmpty) ...[
            GVCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GVSectionHeader(
                    eyebrow: 'Por pagar',
                    title: 'Pendiente por pagar',
                    trailing: GVPillBadge(
                      label: formatMoney(pend.fold(0, (a, x) => a + x.amount)),
                      color: c.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pend.take(5).toList().asMap().entries.map((entry) {
                    return GVMovementRow(
                      state: state,
                      movement: entry.value,
                      onTap: () => onOpenSheet(editing: entry.value),
                      showDivider: entry.key < pend.take(5).length - 1,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 6-Month Trend Bento card
          GVCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GVSectionHeader(
                  eyebrow: 'Últimos 6 meses',
                  title: 'Tendencia',
                ),
                const SizedBox(height: 14),
                TrendChartWidget(
                  spaceMovements: state.spaceMovements,
                  currentYm: state.ym,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Category Distribution Bento card
          GVCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GVSectionHeader(
                  eyebrow: 'Resumen mensual',
                  title: 'Distribución por categoría',
                  trailing: catEntries.isNotEmpty
                      ? Text(
                          formatMoney(state.monthExpense),
                          style: GVTxt.sm(c, weight: FontWeight.w600, color: c.txt, tabular: true),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                DonutChartWidget(byCat: byCat, totalExpense: state.monthExpense),
                if (catEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('Sin gastos registrados este mes.', style: GVTxt.sm(c)),
                    ),
                  )
                else
                  ...catEntries.map((e) {
                    final cap = state.curSpace.budgets[e.key];
                    final ratio = cap != null && cap > 0
                        ? (e.value / cap).clamp(0.0, 1.0)
                        : (e.value / maxCat).clamp(0.06, 1.0);
                    final barCol = cap != null && cap > 0
                        ? (e.value >= cap
                            ? c.red
                            : (e.value >= cap * 0.8 ? c.amber : c.acc))
                        : c.acc;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          GVSquircleIcon(
                            size: 38,
                            radius: 11,
                            child: Text(
                              state.curSpace.iconForCategory(e.key),
                              style: const TextStyle(fontSize: 16),
                            ),
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
            ),
          ),
          const SizedBox(height: 14),

          // Accounts Bento Grid Card
          GVCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GVSectionHeader(
                  eyebrow: 'Desglose',
                  title: 'Pagos por cuenta',
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 10.0;
                    final tileWidth = constraints.maxWidth >= 240
                        ? (constraints.maxWidth - spacing) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: state.curSpace.accounts.map((acc) {
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Signature Apple Anodized Space Black Pro balance tile in pure monochrome black & white.
  Widget _buildAnodizedHeroCard(GVColors c) {
    const heroWhite = Color(0xFFFFFFFF);
    const heroText = Color(0xFFF5F5F7);
    const heroMut = Color(0xFFA1A1A6);

    return GVCard(
      anodized: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'DISPONIBLE ESTE MES',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GVTxt.xs2(c, color: heroMut, weight: FontWeight.w600, letterSpacing: 1.0),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(GVRadius.pill),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: Text(
                  state.curSpace.name,
                  style: GVTxt.xs2(c, color: heroText, weight: FontWeight.w600, letterSpacing: 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(state.monthAvailable),
              style: GVTxt.display(c, color: heroWhite),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _heroMetric(c, 'INGRESOS', state.monthIncome, heroWhite),
              const SizedBox(width: 8),
              _heroMetric(c, 'GASTOS', state.monthExpense, const Color(0xFF8E8E93)),
              const SizedBox(width: 8),
              _heroMetric(c, 'AHORRO', state.monthSaving, const Color(0xFFD1D1D6)),
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
                      letterSpacing: 0.4,
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
