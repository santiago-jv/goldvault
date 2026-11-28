import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/gold_theme.dart';
import '../widgets/gv_components.dart';

/// Displays an Apple-style bottom sheet for switching or creating financial spaces.
void showSpacesSheet(BuildContext context, GoldVaultState state) {
  final c = GVColors.of(context);
  final nameCtrl = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
            Text('Tus espacios', style: GVTxt.h2(c)),
            const SizedBox(height: 12),
            ...state.spaces.values.map((sp) {
              final isCurrent = sp.id == state.curSpace.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GVCard(
                  radius: GVRadius.control,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  color: isCurrent ? c.acc.withValues(alpha: 0.10) : c.card2,
                  borderColor: isCurrent ? c.acc.withValues(alpha: 0.45) : c.line,
                  onTap: () {
                    state.switchSpace(sp.id);
                    Navigator.pop(ctx);
                  },
                  child: Row(
                    children: [
                      Text(sp.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(sp.name, style: GVTxt.body(c, weight: FontWeight.w600)),
                      ),
                      if (isCurrent) GVPillBadge(label: 'Actual', color: c.acc),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GVTextField(
                    controller: nameCtrl,
                    hintText: 'Nuevo espacio (ej: Negocio, Viaje)',
                  ),
                ),
                const SizedBox(width: 10),
                GVPillButton(
                  label: 'Crear',
                  fullWidth: false,
                  compact: true,
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    state.createNewSpace(nameCtrl.text.trim(), '💼');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(nameCtrl.dispose);
}

/// Displays an Apple-style bottom sheet to customize categories and accounts in the active space.
void showCustomizeSpaceSheet(BuildContext context, GoldVaultState state) {
  final c = GVColors.of(context);
  final catCtrl = TextEditingController();
  final acctCtrl = TextEditingController();
  final cardCtrl = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModal) => Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              Text('Personalizar — ${state.curSpace.name}', style: GVTxt.h2(c)),
              const SizedBox(height: 16),
              Text(
                'CATEGORÍAS',
                style: GVTxt.xs2(c, color: c.tertiary, weight: FontWeight.w700, letterSpacing: 0.7),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.curSpace.categories
                    .map(
                      (cat) => Chip(
                        backgroundColor: c.card2,
                        side: BorderSide(color: c.line),
                        shape: const StadiumBorder(),
                        label: Text('${cat.icon} ${cat.name}', style: GVTxt.xs(c, color: c.txt)),
                        onDeleted: state.curSpace.categories.length > 1
                            ? () {
                                state.curSpace.categories.remove(cat);
                                state.pushSpace(state.curSpace);
                                setModal(() {});
                              }
                            : null,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GVTextField(controller: catCtrl, hintText: 'Nueva categoría'),
                  ),
                  const SizedBox(width: 8),
                  GVPillButton(
                    label: 'Añadir',
                    fullWidth: false,
                    compact: true,
                    onPressed: () {
                      if (catCtrl.text.trim().isEmpty) return;
                      state.curSpace.categories.add(
                        CategoryItem(name: catCtrl.text.trim(), icon: '🏷️'),
                      );
                      catCtrl.clear();
                      state.pushSpace(state.curSpace);
                      setModal(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'CUENTAS',
                style: GVTxt.xs2(c, color: c.tertiary, weight: FontWeight.w700, letterSpacing: 0.7),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.curSpace.accounts
                    .map(
                      (a) => Chip(
                        backgroundColor: c.card2,
                        side: BorderSide(color: c.line),
                        shape: const StadiumBorder(),
                        label: Text(a, style: GVTxt.xs(c, color: c.txt)),
                        onDeleted: state.curSpace.accounts.length > 1
                            ? () {
                                state.curSpace.accounts.remove(a);
                                state.pushSpace(state.curSpace);
                                setModal(() {});
                              }
                            : null,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GVTextField(controller: acctCtrl, hintText: 'Nueva cuenta'),
                  ),
                  const SizedBox(width: 8),
                  GVPillButton(
                    label: 'Añadir',
                    fullWidth: false,
                    compact: true,
                    onPressed: () {
                      if (acctCtrl.text.trim().isEmpty) return;
                      state.curSpace.accounts.add(acctCtrl.text.trim());
                      acctCtrl.clear();
                      state.pushSpace(state.curSpace);
                      setModal(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'TARJETAS DE CRÉDITO',
                style: GVTxt.xs2(c, color: c.tertiary, weight: FontWeight.w700, letterSpacing: 0.7),
              ),
              const SizedBox(height: 8),
              if (state.curSpace.creditCards.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Aún no has agregado tarjetas de crédito.',
                    style: GVTxt.xs(c, color: c.mut),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.curSpace.creditCards
                      .map(
                        (card) => Chip(
                          backgroundColor: c.card2,
                          side: BorderSide(color: c.line),
                          shape: const StadiumBorder(),
                          avatar: Icon(Icons.credit_card_outlined, size: 15, color: c.mut),
                          label: Text(card, style: GVTxt.xs(c, color: c.txt)),
                          onDeleted: () {
                            state.curSpace.creditCards.remove(card);
                            state.pushSpace(state.curSpace);
                            setModal(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GVTextField(
                      controller: cardCtrl,
                      hintText: 'Nueva tarjeta (ej: Nu Crédito, Visa)',
                    ),
                  ),
                  const SizedBox(width: 8),
                  GVPillButton(
                    label: 'Añadir',
                    fullWidth: false,
                    compact: true,
                    onPressed: () {
                      final name = cardCtrl.text.trim();
                      if (name.isEmpty) return;
                      if (!state.curSpace.creditCards.any((e) => normText(e) == normText(name))) {
                        state.curSpace.creditCards.add(name);
                        state.pushSpace(state.curSpace);
                      }
                      cardCtrl.clear();
                      setModal(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ).whenComplete(() {
    catCtrl.dispose();
    acctCtrl.dispose();
    cardCtrl.dispose();
  });
}

/// Displays an Apple-style bottom sheet for creating a new savings goal.
void showAddGoalSheet(BuildContext context, GoldVaultState state) {
  final c = GVColors.of(context);
  final nameCtrl = TextEditingController();
  final targetCtrl = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
          Text('Nueva meta de ahorro', style: GVTxt.h2(c)),
          const SizedBox(height: 14),
          GVTextField(controller: nameCtrl, hintText: 'Nombre (ej: Viaje, Moto, Fondo)'),
          const SizedBox(height: 10),
          GVTextField(
            controller: targetCtrl,
            hintText: 'Monto objetivo en COP',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          GVPillButton(
            label: 'Guardar meta',
            onPressed: () {
              final nm = nameCtrl.text.trim();
              final tg = int.tryParse(targetCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
              if (nm.isEmpty || tg <= 0) return;
              final g = GoalItem(id: genId('goal'), name: nm, target: tg);
              state.curSpace.goals.add(g);
              state.pushGoal(g, state.curSpace.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    nameCtrl.dispose();
    targetCtrl.dispose();
  });
}
