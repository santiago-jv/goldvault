import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:goldvault/main.dart';
import 'package:goldvault/models/models.dart';
import 'package:goldvault/screens/home_and_shells.dart';
import 'package:goldvault/state/app_state.dart';
import 'package:goldvault/theme/gold_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Session _fakeSession() => Session(
      accessToken: 'fake-access-token',
      tokenType: 'bearer',
      user: User(
        id: 'user-123',
        appMetadata: const {},
        userMetadata: const {'full_name': 'Santiago Test'},
        aud: 'authenticated',
        email: 'santiago@example.com',
        createdAt: '2026-01-01T00:00:00.000Z',
      ),
    );

class FakeCloudAdapter implements GoldVaultCloudAdapter {
  bool failFetch = false;
  bool failWrites = false;
  final Map<String, Map<String, dynamic>> remoteSpaces = {};
  final Map<String, Map<String, dynamic>> remoteGoals = {};
  final Map<String, Map<String, dynamic>> remoteMovements = {};
  Map<String, dynamic>? remoteProfile = {
    'display_name': 'Santiago Test',
    'avatar': null,
    'webhook_token': 'vaq_testtoken123',
    'default_space_id': 'space_main',
  };
  final List<String> callLog = [];

  @override
  Future<CloudSnapshot> fetchAll() async {
    callLog.add('fetchAll');
    if (failFetch) {
      throw Exception('SocketException: Failed host lookup');
    }
    return CloudSnapshot(
      spaces: remoteSpaces.values.map((e) => Map<String, dynamic>.from(e)).toList(),
      goals: remoteGoals.values.map((e) => Map<String, dynamic>.from(e)).toList(),
      movements: remoteMovements.values.map((e) => Map<String, dynamic>.from(e)).toList(),
      profile: remoteProfile != null ? Map<String, dynamic>.from(remoteProfile!) : null,
    );
  }

  @override
  Future<void> upsertProfile(Map<String, dynamic> row) async {
    callLog.add('upsertProfile');
    if (failWrites) throw Exception('Connection timeout');
    remoteProfile = Map<String, dynamic>.from(row);
  }

  @override
  Future<void> upsertSpace(Map<String, dynamic> row) async {
    callLog.add('upsertSpace:${row['id']}');
    if (failWrites) throw Exception('Connection timeout');
    remoteSpaces[row['id'].toString()] = Map<String, dynamic>.from(row);
  }

  @override
  Future<void> upsertGoal(Map<String, dynamic> row) async {
    callLog.add('upsertGoal:${row['id']}');
    if (failWrites) throw Exception('Connection timeout');
    remoteGoals[row['id'].toString()] = Map<String, dynamic>.from(row);
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    callLog.add('deleteGoal:$goalId');
    if (failWrites) throw Exception('Connection timeout');
    remoteGoals.remove(goalId);
  }

  @override
  Future<void> upsertMovement(Map<String, dynamic> row) async {
    callLog.add('upsertMovement:${row['id']}');
    if (failWrites) throw Exception('Connection timeout');
    remoteMovements[row['id'].toString()] = Map<String, dynamic>.from(row);
  }

  @override
  Future<void> deleteMovement(String movementId) async {
    callLog.add('deleteMovement:$movementId');
    if (failWrites) throw Exception('Connection timeout');
    remoteMovements.remove(movementId);
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Initial sync failure shows SyncErrorScreen (not Onboarding) and recovers on retry', (tester) async {
    final cloud = FakeCloudAdapter()..failFetch = true;
    final remoteSpace = SpaceModel.fromTemplate('complete', first: true);
    cloud.remoteSpaces[remoteSpace.id] = remoteSpace.toRow();

    final state = GoldVaultState(cloud: cloud, onlineChecker: () async => true)
      ..initialized = true
      ..isOnline = true
      ..session = _fakeSession();
    addTearDown(state.dispose);

    await tester.pumpWidget(GoldVaultApp(state: state));

    final ok = await state.syncAll();
    expect(ok, isFalse);
    expect(state.needsOnboarding, isFalse);
    expect(state.syncError, isNotNull);

    await tester.pumpAndSettle();
    expect(find.text('Error al sincronizar'), findsOneWidget);
    expect(find.text('¿Cómo quieres empezar?'), findsNothing);

    // Cloud recovers -> tap retry button
    cloud.failFetch = false;
    await tester.tap(find.text('Reintentar sincronización'));
    await tester.pumpAndSettle();

    expect(state.cloudSynced, isTrue);
    expect(state.syncError, isNull);
    expect(state.spaces.containsKey('space_main'), isTrue);
    expect(find.text('Disponible este mes'), findsOneWidget);
  });

  testWidgets('Verified empty cloud account transitions to OnboardingScreen', (tester) async {
    final cloud = FakeCloudAdapter();
    final state = GoldVaultState(cloud: cloud, onlineChecker: () async => true)
      ..initialized = true
      ..isOnline = true
      ..session = _fakeSession();
    addTearDown(state.dispose);

    await tester.pumpWidget(GoldVaultApp(state: state));
    final ok = await state.syncAll();
    expect(ok, isTrue);
    expect(state.needsOnboarding, isTrue);

    await tester.pumpAndSettle();
    expect(find.text('Configuración recomendada'), findsOneWidget);
  });

  testWidgets('Failed movement write is queued, preserved across failed syncs, and flushed before pull on recovery', (tester) async {
    final cloud = FakeCloudAdapter();
    final space = SpaceModel.fromTemplate('complete', first: true);
    cloud.remoteSpaces[space.id] = space.toRow();

    final state = GoldVaultState(cloud: cloud, onlineChecker: () async => true)
      ..initialized = true
      ..isOnline = true
      ..session = _fakeSession();
    addTearDown(state.dispose);

    expect(await state.syncAll(), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: GoldTheme.build(Brightness.dark),
        home: GoldVaultShell(state: state),
      ),
    );
    await tester.pumpAndSettle();

    // Simulate transient write failure
    cloud.failWrites = true;
    final mv = MovementModel(
      id: 'mv_offline_1',
      space: space.id,
      date: todayIso(),
      type: 'expense',
      desc: 'Café aeropuerto',
      amount: 18000,
      category: 'Comida',
      account: 'Nequi',
    );
    await state.saveMovement(mv);
    await tester.pumpAndSettle();

    expect(state.pendingSyncCount, 1);
    expect(state.syncError, isNotNull);
    expect(find.text('Reintentar'), findsOneWidget);

    // Even if syncAll runs while writes are still failing, remote pull MUST NOT wipe local movement
    expect(await state.syncAll(), isFalse);
    expect(state.movements.any((m) => m.id == 'mv_offline_1'), isTrue);

    // Cloud recovers -> tap Reintentar in banner
    cloud.failWrites = false;
    cloud.callLog.clear();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(state.pendingSyncCount, 0);
    expect(state.syncError, isNull);
    expect(cloud.remoteMovements.containsKey('mv_offline_1'), isTrue);
    // Verify flush happened BEFORE fetchAll
    expect(cloud.callLog.indexOf('upsertMovement:mv_offline_1'), lessThan(cloud.callLog.indexOf('fetchAll')));
    expect(state.movements.any((m) => m.id == 'mv_offline_1'), isTrue);
    expect(find.text('Reintentar'), findsNothing);
  });

  test('Delete then undo coalesces pending operations cleanly and offline->online auto-recovers', () async {
    var online = true;
    final cloud = FakeCloudAdapter();
    final space = SpaceModel.fromTemplate('complete', first: true);
    cloud.remoteSpaces[space.id] = space.toRow();

    final mv = MovementModel(
      id: 'mv_coalesce_1',
      space: space.id,
      date: todayIso(),
      type: 'expense',
      desc: 'Almuerzo',
      amount: 25000,
      category: 'Comida',
      account: 'Nequi',
    );
    cloud.remoteMovements[mv.id] = mv.toRow();

    final state = GoldVaultState(cloud: cloud, onlineChecker: () async => online)
      ..initialized = true
      ..isOnline = true
      ..session = _fakeSession();
    addTearDown(state.dispose);

    expect(await state.syncAll(), isTrue);

    // Drop writes, delete then undo -> should coalesce to a single upsert_movement
    cloud.failWrites = true;
    await state.deleteMovement(mv.id);
    expect(state.pendingSyncOps.single.kind, 'delete_movement');

    await state.undoDeleteMovement();
    expect(state.pendingSyncOps.single.kind, 'upsert_movement');

    // Go offline then back online -> checkOnlineStatus(manual: false) auto-recovers!
    online = false;
    expect(await state.checkOnlineStatus(), isFalse);
    expect(state.isOnline, isFalse);

    online = true;
    cloud.failWrites = false;
    expect(await state.checkOnlineStatus(), isTrue);
    expect(state.pendingSyncCount, 0);
    expect(state.syncError, isNull);
    expect(cloud.remoteMovements.containsKey(mv.id), isTrue);
  });

  testWidgets('Native iOS Settings hides Android APK download and shows iOS Shortcuts', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final state = GoldVaultState();
    addTearDown(state.dispose);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: GoldTheme.build(Brightness.dark),
          home: GoldVaultShell(state: state),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();

      expect(find.text('Descargar App Android (.APK)'), findsNothing);
      expect(find.textContaining('En iPhone'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
