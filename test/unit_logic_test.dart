import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:goldvault/main.dart';
import 'package:goldvault/models/models.dart';
import 'package:goldvault/state/app_state.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Formatting and text normalization helpers', () {
    test('formatMoney formats Colombian peso amounts cleanly', () {
      expect(formatMoney(0), equals('\$0'));
      expect(formatMoney(9979), equals('\$9.979'));
      expect(formatMoney(1250000), equals('\$1.250.000'));
    });

    test('formatCompact abbreviates thousands and millions', () {
      expect(formatCompact(850), equals('\$850'));
      expect(formatCompact(25000), equals('\$25k'));
      expect(formatCompact(2500000), equals('\$2,5M'));
      expect(formatCompact(12000000), equals('\$12M'));
    });

    test('monthShortLabel and monthFullLabel format Spanish months', () {
      expect(monthShortLabel('2026-01'), equals('Ene 2026'));
      expect(monthShortLabel('2026-11'), equals('Nov 2026'));
      expect(monthFullLabel('2026-12'), equals('Diciembre 2026'));
    });

    test('normText strips Spanish accents and normalizes whitespace and case', () {
      expect(normText('  Alimentación & Nómina  '), equals('alimentacion & nomina'));
      expect(normText('Ñoño ÁÉÍÓÚ'), equals('nono aeiou'));
    });
  });

  group('Model serialization round-trips', () {
    test('MovementModel preserves fields across toRow and fromRow', () {
      final original = MovementModel(
        id: 'mv_unit_1',
        space: 'sp_personal',
        date: '2026-11-15',
        type: 'expense',
        desc: 'Mercado semanal',
        amount: 145000,
        category: 'Mercado',
        account: 'Nequi',
        status: 'paid',
        autoBank: 'Nequi',
        autoReviewed: true,
        fx: const FxInfo(ccy: 'USD', amount: 34.5, rate: 4200),
      );

      final decoded = MovementModel.fromRow(original.toRow());
      expect(decoded.id, equals(original.id));
      expect(decoded.space, equals(original.space));
      expect(decoded.date, equals(original.date));
      expect(decoded.type, equals(original.type));
      expect(decoded.desc, equals(original.desc));
      expect(decoded.amount, equals(original.amount));
      expect(decoded.category, equals(original.category));
      expect(decoded.account, equals(original.account));
      expect(decoded.status, equals(original.status));
      expect(decoded.autoBank, equals('Nequi'));
      expect(decoded.autoReviewed, isTrue);
      expect(decoded.fx?.ccy, equals('USD'));
      expect(decoded.fx?.rate, equals(4200));
    });

    test('GoalItem and FrequentItem serialize and deserialize accurately', () {
      final goal = GoalItem(id: 'g_1', name: 'Fondo emergencia', target: 5000000);
      final decodedGoal = GoalItem.fromJson(goal.toJson());
      expect(decodedGoal.id, equals('g_1'));
      expect(decodedGoal.name, equals('Fondo emergencia'));
      expect(decodedGoal.target, equals(5000000));

      final freq = FrequentItem(
        id: 'fq_1',
        desc: 'Internet',
        category: 'Servicios',
        amount: 100000,
        account: 'Nequi',
        day: 5,
      );
      final decodedFreq = FrequentItem.fromJson(freq.toJson());
      expect(decodedFreq.desc, equals('Internet'));
      expect(decodedFreq.amount, equals(100000));
      expect(decodedFreq.day, equals(5));
    });
  });

  group('GoldVaultState financial calculations and quick entry', () {
    test('computes monthly income, expense, saving, available, and goalSaved ignoring cancelled items', () {
      final st = GoldVaultState();
      addTearDown(st.dispose);

      st.ym = '2026-11';
      final spaceId = st.curSpace.id;
      st.movements = [
        MovementModel(
          id: 'm1',
          space: spaceId,
          date: '2026-11-01',
          type: 'income',
          desc: 'Salario',
          amount: 4000000,
          source: 'Nómina',
          status: 'paid',
        ),
        MovementModel(
          id: 'm2',
          space: spaceId,
          date: '2026-11-05',
          type: 'expense',
          desc: 'Arriendo',
          amount: 1200000,
          category: 'Vivienda',
          account: 'Nu',
          status: 'paid',
        ),
        MovementModel(
          id: 'm3',
          space: spaceId,
          date: '2026-11-08',
          type: 'saving',
          desc: 'Abono meta',
          amount: 500000,
          goalId: 'goal_emergencia',
          status: 'paid',
        ),
        MovementModel(
          id: 'm4',
          space: spaceId,
          date: '2026-11-10',
          type: 'expense',
          desc: 'Compra cancelada',
          amount: 999000,
          category: 'Otros',
          status: 'cancelled',
        ),
        MovementModel(
          id: 'm5',
          space: spaceId,
          date: '2026-10-20',
          type: 'expense',
          desc: 'Mes anterior',
          amount: 300000,
          category: 'Mercado',
          status: 'paid',
        ),
      ];

      expect(st.monthIncome, equals(4000000));
      expect(st.monthExpense, equals(1200000));
      expect(st.monthSaving, equals(500000));
      expect(st.monthAvailable, equals(2300000));
      expect(st.goalSaved('goal_emergencia'), equals(500000));
    });

    test('shiftMonth crosses year boundaries accurately', () {
      final st = GoldVaultState();
      addTearDown(st.dispose);

      st.ym = '2026-12';
      st.shiftMonth(1);
      expect(st.ym, equals('2027-01'));

      st.shiftMonth(-1);
      expect(st.ym, equals('2026-12'));
    });

    test('parseQuickEntry parses Spanish expenses, incomes, and savings', () {
      final st = GoldVaultState();
      addTearDown(st.dispose);

      final exp = st.parseQuickEntry('20 mil almuerzo en nequi');
      expect(exp.type, equals('expense'));
      expect(exp.amount, equals(20000));

      final inc = st.parseQuickEntry('pagaron 2m nomina');
      expect(inc.type, equals('income'));
      expect(inc.amount, equals(2000000));

      final sav = st.parseQuickEntry('ahorro 150k');
      expect(sav.type, equals('saving'));
      expect(sav.amount, equals(150000));
    });
  });

  group('Animated startup splash screen', () {
    testWidgets('respects minSplashDuration before revealing login screen', (tester) async {
      final st = GoldVaultState()..initialized = true;
      addTearDown(st.dispose);

      await tester.pumpWidget(
        GoldVaultApp(
          state: st,
          minSplashDuration: const Duration(milliseconds: 400),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continuar con Google'), findsNothing);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Continuar con Google'), findsOneWidget);
    });
  });
}
