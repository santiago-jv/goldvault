import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/gold_theme.dart';
import '../widgets/gv_components.dart';

class MovementSheet extends StatefulWidget {
  final GoldVaultState state;
  final MovementModel? editing;
  final MovementModel? prefilled;

  const MovementSheet({super.key, required this.state, this.editing, this.prefilled});

  @override
  State<MovementSheet> createState() => _MovementSheetState();
}

class _MovementSheetState extends State<MovementSheet> {
  late String type;
  late String currency;
  late TextEditingController amountCtrl;
  late TextEditingController descCtrl;
  late String? category;
  late String? account;
  late String? source;
  late String? goalId;
  late String status;
  late String date;
  bool saveFreq = false;

  @override
  void initState() {
    super.initState();
    final sp = widget.state.curSpace;
    final src = widget.editing ?? widget.prefilled;
    type = src?.type ?? 'expense';
    currency = 'COP';
    amountCtrl = TextEditingController(
      text: (src != null && src.amount > 0) ? src.amount.toString() : '',
    );
    descCtrl = TextEditingController(text: src?.desc ?? '');
    category = src?.category ?? (sp.categories.isNotEmpty ? sp.categories.first.name : 'Otros');
    account = src?.account ?? (sp.accounts.isNotEmpty ? sp.accounts.first : 'Efectivo');
    source = src?.source ?? (sp.sources.isNotEmpty ? sp.sources.first : 'Salario');
    goalId = src?.goalId ?? (sp.goals.isNotEmpty ? sp.goals.first.id : null);
    status = src?.status ?? 'paid';
    date = src?.date ?? todayIso();
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final sp = widget.state.curSpace;
    final rawAmt = double.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.lineStrong,
                  borderRadius: BorderRadius.circular(GVRadius.pill),
                ),
              ),
            ),

            // Movement type segmented control
            GVSegmentedControl<String>(
              value: type,
              items: const [('expense', 'Gasto'), ('saving', 'Ahorro'), ('income', 'Ingreso')],
              onChanged: (next) => setState(() => type = next),
            ),
            const SizedBox(height: 16),

            // Currency toggle and hero numeric amount input
            Center(
              child: Column(
                children: [
                  GVSegmentedControl<String>(
                    value: currency,
                    compact: true,
                    items: const [('COP', 'COP'), ('USD', 'USD')],
                    onChanged: (next) => setState(() => currency = next),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currency == 'USD' ? 'US\$' : 'COP \$',
                        style: GVTxt.h2(c, color: c.tertiary),
                      ),
                      const SizedBox(width: 6),
                      IntrinsicWidth(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 56, maxWidth: 240),
                          child: TextField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: GVTxt.display(c, color: c.txt),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: GVTxt.display(c, color: c.placeholder),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (currency == 'USD' && rawAmt > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: GVPillBadge(
                        label:
                            '≈ ${formatMoney(rawAmt * widget.state.fxRate)} COP · 1 USD = ${formatMoney(widget.state.fxRate)}',
                        color: c.acc,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description field
            GVTextField(
              controller: descCtrl,
              hintText: 'Descripción (ej: Almuerzo, Uber, Mercado)',
            ),
            const SizedBox(height: 16),

            // Category grid, savings goal selector, or income source selector
            if (type == 'expense') ...[
              Text(
                'CATEGORÍA',
                style: GVTxt.xs2(c, color: c.tertiary, weight: FontWeight.w700, letterSpacing: 0.7),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
                children: sp.categories.map((cat) {
                  final on = category == cat.name;
                  return InkWell(
                    onTap: () => setState(() => category = cat.name),
                    borderRadius: BorderRadius.circular(GVRadius.control),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      decoration: BoxDecoration(
                        color: on ? c.acc.withValues(alpha: 0.14) : c.card2,
                        borderRadius: BorderRadius.circular(GVRadius.control),
                        border: Border.all(color: on ? c.acc : c.line, width: on ? 1.4 : 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(categoryIconData(cat.name), size: 20, color: on ? c.txt : c.mut),
                          const SizedBox(height: 5),
                          Text(
                            cat.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GVTxt.xs2(
                              c,
                              color: on ? c.txt : c.mut,
                              weight: on ? FontWeight.w700 : FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else if (type == 'saving') ...[
              Text(
                'META DE AHORRO',
                style: GVTxt.xs2(c, color: c.tertiary, weight: FontWeight.w700, letterSpacing: 0.7),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sp.goals.map((g) {
                  final on = goalId == g.id;
                  return _selectPill(c, g.name, on, () => setState(() => goalId = g.id));
                }).toList(),
              ),
            ] else ...[
              Text(
                'FUENTE DE INGRESO',
                style: GVTxt.xs2(c, color: c.tertiary, weight: FontWeight.w700, letterSpacing: 0.7),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sp.sources.map((s) {
                  final on = source == s;
                  return _selectPill(c, s, on, () => setState(() => source = s));
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),

            // Payment account horizontal pills
            Text(
              'CUENTA',
              style: GVTxt.xs2(c, color: c.tertiary, weight: FontWeight.w700, letterSpacing: 0.7),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sp.accounts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final acc = sp.accounts[i];
                  return _selectPill(c, acc, account == acc, () => setState(() => account = acc));
                },
              ),
            ),
            const SizedBox(height: 20),

            // Save / delete actions
            GVPillButton(
              label: 'Guardar movimiento',
              onPressed: () async {
                if (rawAmt <= 0) return;
                final finalCop = currency == 'USD'
                    ? (rawAmt * widget.state.fxRate).round()
                    : rawAmt.round();
                final mv = MovementModel(
                  id: widget.editing?.id ?? genId('mv'),
                  space: sp.id,
                  date: date,
                  type: type,
                  desc: descCtrl.text.trim(),
                  amount: finalCop,
                  category: type == 'expense' ? category : null,
                  account: account,
                  status: type == 'income' ? 'paid' : status,
                  goalId: type == 'saving' ? goalId : null,
                  source: type == 'income' ? source : null,
                  fx: currency == 'USD'
                      ? FxInfo(ccy: 'USD', amount: rawAmt, rate: widget.state.fxRate)
                      : widget.editing?.fx,
                  autoBank: widget.editing?.autoBank,
                  autoRaw: widget.editing?.autoRaw,
                  autoReviewed: true,
                );
                await widget.state.saveMovement(mv, saveAsFrequent: saveFreq);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            if (widget.editing != null) ...[
              const SizedBox(height: 10),
              GVPillButton(
                label: 'Eliminar movimiento',
                variant: GVPillButtonVariant.danger,
                onPressed: () async {
                  await widget.state.deleteMovement(widget.editing!.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _selectPill(GVColors c, String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GVRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.acc.withValues(alpha: 0.14) : c.card2,
          borderRadius: BorderRadius.circular(GVRadius.pill),
          border: Border.all(color: selected ? c.acc : c.line, width: selected ? 1.3 : 1),
        ),
        child: Text(
          label,
          style: GVTxt.sm(
            c,
            weight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? c.txt : c.mut,
          ),
        ),
      ),
    );
  }
}
