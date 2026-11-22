part of 'home_and_shells.dart';

class MovementSheet extends StatefulWidget {
  final GoldVaultState state;
  final MovementModel? editing;
  final MovementModel? prefilled;

  const MovementSheet({
    super.key,
    required this.state,
    this.editing,
    this.prefilled,
  });

  @override
  State<MovementSheet> createState() => _MovementSheetState();
}

class _MovementSheetState extends State<MovementSheet> {
  late String type;
  late String ccy;
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
    ccy = 'COP';
    amountCtrl = TextEditingController(text: (src != null && src.amount > 0) ? src.amount.toString() : '');
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
        color: c.card2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            // Type segmented control
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  _segBtn(c, 'expense', 'Gasto'),
                  _segBtn(c, 'saving', 'Ahorro'),
                  _segBtn(c, 'income', 'Ingreso'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // COP / USD Toggle + Centered Amount Row
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ccyBtn(c, 'COP'),
                        _ccyBtn(c, 'USD'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        ccy == 'USD' ? 'US\$' : 'COP \$',
                        style: GVTxt.h2(c).copyWith(color: c.mut),
                      ),
                      const SizedBox(width: 6),
                      IntrinsicWidth(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 48, maxWidth: 240),
                          child: TextField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: GVTxt.display(c).copyWith(color: c.txt),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: GVTxt.display(c).copyWith(color: c.placeholder),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (ccy == 'USD' && rawAmt > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '≈ ${formatMoney(rawAmt * widget.state.fxRate)} COP · 1 USD = ${formatMoney(widget.state.fxRate)}',
                        style: GVTxt.xs(c, color: c.acc2, weight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.line),
              ),
              child: TextField(
                controller: descCtrl,
                style: GVTxt.body(c),
                decoration: InputDecoration(
                  hintText: 'Descripción',
                  hintStyle: GVTxt.sm(c, color: c.placeholder),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category / Goal / Source
            if (type == 'expense') ...[
              Text('CATEGORÍA', style: GVTxt.xs(c, weight: FontWeight.w700, letterSpacing: 0.7)),
              const SizedBox(height: 8),
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
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: on ? c.acc.withValues(alpha: 0.14) : c.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: on ? c.acc : c.line),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat.icon, style: const TextStyle(fontSize: 19)),
                          const SizedBox(height: 3),
                          Text(
                            cat.name,
                            maxLines: 1,
                            style: GVTxt.xs2(c, color: on ? c.txt : c.mut, weight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else if (type == 'saving') ...[
              Text('META DE AHORRO', style: GVTxt.xs(c, weight: FontWeight.w700, letterSpacing: 0.7)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sp.goals.map((g) {
                  final on = goalId == g.id;
                  return ChoiceChip(
                    selected: on,
                    label: Text(g.name),
                    onSelected: (_) => setState(() => goalId = g.id),
                  );
                }).toList(),
              ),
            ] else ...[
              Text('FUENTE DE INGRESO', style: GVTxt.xs(c, weight: FontWeight.w700, letterSpacing: 0.7)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sp.sources.map((s) {
                  final on = source == s;
                  return ChoiceChip(
                    selected: on,
                    label: Text(s),
                    onSelected: (_) => setState(() => source = s),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),

            // Account chips
            Text('CUENTA', style: GVTxt.xs(c, weight: FontWeight.w700, letterSpacing: 0.7)),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sp.accounts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final acc = sp.accounts[i];
                  final on = account == acc;
                  return InkWell(
                    onTap: () => setState(() => account = acc),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        color: on ? c.acc.withValues(alpha: 0.14) : c.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: on ? c.acc : c.line),
                      ),
                      child: Text(acc, style: GVTxt.sm(c, weight: FontWeight.w600, color: c.txt)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Save / Delete Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.acc,
                  foregroundColor: c.ink,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                onPressed: () async {
                  if (rawAmt <= 0) return;
                  final finalCop = ccy == 'USD' ? (rawAmt * widget.state.fxRate).round() : rawAmt.round();
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
                    fx: ccy == 'USD' ? FxInfo(ccy: 'USD', amount: rawAmt, rate: widget.state.fxRate) : widget.editing?.fx,
                    autoBank: widget.editing?.autoBank,
                    autoRaw: widget.editing?.autoRaw,
                    autoReviewed: true,
                  );
                  await widget.state.saveMovement(mv, saveAsFrequent: saveFreq);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text('Guardar movimiento', style: GVTxt.body(c, weight: FontWeight.w800, color: c.ink)),
              ),
            ),
            if (widget.editing != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.red,
                    side: BorderSide(color: c.red.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await widget.state.deleteMovement(widget.editing!.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text('Eliminar movimiento', style: GVTxt.sm(c, weight: FontWeight.w700, color: c.red)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _segBtn(GVColors c, String t, String label) {
    final on = type == t;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => type = t),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? c.acc : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: GVTxt.sm(c, weight: FontWeight.w700, color: on ? c.ink : c.mut),
          ),
        ),
      ),
    );
  }

  Widget _ccyBtn(GVColors c, String code) {
    final on = ccy == code;
    return InkWell(
      onTap: () => setState(() => ccy = code),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: on ? c.acc : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          code,
          style: GVTxt.xs(c, weight: FontWeight.w800, color: on ? c.ink : c.mut),
        ),
      ),
    );
  }
}

