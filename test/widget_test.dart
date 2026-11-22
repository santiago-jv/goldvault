import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldvault/main.dart';
import 'package:goldvault/models/models.dart';
import 'package:goldvault/screens/home_and_shells.dart';
import 'package:goldvault/state/app_state.dart';
import 'package:goldvault/theme/gold_theme.dart';

void main() {
  test('Only Android exposes notification listener controls', () {
    final state = GoldVaultState();
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      state.dispose();
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(state.supportsBankNotifications, isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(state.supportsBankNotifications, isTrue);
  });

  testWidgets('Onboarding choices remain reachable on a short screen', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = GoldVaultState();
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(home: OnboardingScreen(state: state)));
    await tester.ensureVisible(find.text('Desde cero'));
    expect(find.text('Configuración recomendada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('BankNotificationParser parses Nequi, Nu, Lulo, ARQ, Morse and ignores OTP', () {
    final sp = SpaceModel.fromTemplate('complete', first: true);
    for (final s in kBankSamples) {
      final res = BankNotificationParser.parse(
        rawText: s.text,
        rawTitle: s.title,
        rawApp: s.pkg,
        space: sp,
        fxRate: 4200,
      );
      expect(res.ok, isTrue, reason: 'Failed for ${s.bank}');
      expect(res.bank, equals(s.bank));
      expect(res.amount, greaterThan(0));
    }

    final otp = BankNotificationParser.parse(
      rawText: 'Tu clave dinámica de Nequi es 918273',
      rawTitle: 'Nequi',
      rawApp: 'com.nequi.MobileApp',
      space: sp,
      fxRate: 4200,
    );
    expect(otp.ok, isFalse);
    expect(otp.ignored, isTrue);
  });

  testWidgets('GoldVaultApp renders StartupSplashScreen immediately and transitions to GoogleLoginScreen', (WidgetTester tester) async {
    final st = GoldVaultState();
    await tester.pumpWidget(GoldVaultApp(state: st));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    st.initialized = true;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    st.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Continuar con Google'), findsOneWidget);
  });

  testWidgets('GoldVaultShell renders Home, Movs, Metas, Ajustes and MovementSheet cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final st = GoldVaultState();
    await tester.pumpWidget(
      MaterialApp(
        theme: GoldTheme.build(Brightness.dark),
        home: GoldVaultShell(state: st),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Home view is visible and not crushed by bottomNavigationBar
    expect(find.text('DISPONIBLE ESTE MES'), findsOneWidget);
    final heroRect = tester.getRect(find.text('DISPONIBLE ESTE MES'));
    expect(heroRect.top, lessThan(200));

    // Switch to Movs
    await tester.tap(find.text('Movs'));
    await tester.pumpAndSettle();
    expect(find.text('Movimientos'), findsOneWidget);

    // Switch to Metas
    await tester.tap(find.text('Metas'));
    await tester.pumpAndSettle();
    expect(find.text('＋ Nueva meta'), findsOneWidget);

    // Switch to Ajustes
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Apariencia'), findsOneWidget);

    // Open MovementSheet (+)
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('CATEGORÍA'), findsOneWidget);
  });
}

