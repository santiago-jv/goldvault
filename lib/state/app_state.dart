import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class CloudSnapshot {
  final List<Map<String, dynamic>> spaces;
  final List<Map<String, dynamic>> goals;
  final List<Map<String, dynamic>> movements;
  final Map<String, dynamic>? profile;

  const CloudSnapshot({
    required this.spaces,
    required this.goals,
    required this.movements,
    this.profile,
  });
}

abstract class GoldVaultCloudAdapter {
  Future<CloudSnapshot> fetchAll();
  Future<void> upsertProfile(Map<String, dynamic> row);
  Future<void> upsertSpace(Map<String, dynamic> row);
  Future<void> upsertGoal(Map<String, dynamic> row);
  Future<void> deleteGoal(String goalId);
  Future<void> upsertMovement(Map<String, dynamic> row);
  Future<void> deleteMovement(String movementId);
}

class SupabaseCloudAdapter implements GoldVaultCloudAdapter {
  final SupabaseClient Function() _clientProvider;

  SupabaseCloudAdapter(this._clientProvider);

  SupabaseClient get _sb => _clientProvider();

  @override
  Future<CloudSnapshot> fetchAll() async {
    final resSpaces = await _sb.from('spaces').select();
    final resGoals = await _sb.from('goals').select();
    final resMovs = await _sb.from('movements').select();
    final resProf = await _sb
        .from('profiles')
        .select('display_name,avatar,webhook_token,default_space_id')
        .maybeSingle();

    return CloudSnapshot(
      spaces: (resSpaces as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      goals: (resGoals as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      movements: (resMovs as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      profile: resProf != null ? Map<String, dynamic>.from(resProf as Map) : null,
    );
  }

  @override
  Future<void> upsertProfile(Map<String, dynamic> row) async {
    await _sb.from('profiles').upsert(row, onConflict: 'user_id');
  }

  @override
  Future<void> upsertSpace(Map<String, dynamic> row) async {
    await _sb.from('spaces').upsert(row, onConflict: 'user_id,id');
  }

  @override
  Future<void> upsertGoal(Map<String, dynamic> row) async {
    await _sb.from('goals').upsert(row, onConflict: 'user_id,id');
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    await _sb.from('goals').delete().eq('id', goalId);
  }

  @override
  Future<void> upsertMovement(Map<String, dynamic> row) async {
    await _sb.from('movements').upsert(row, onConflict: 'user_id,id');
  }

  @override
  Future<void> deleteMovement(String movementId) async {
    await _sb.from('movements').delete().eq('id', movementId);
  }
}

class PendingSyncOp {
  final String kind;
  final String entityId;
  final Map<String, dynamic> payload;
  final String queuedAt;

  const PendingSyncOp({
    required this.kind,
    required this.entityId,
    required this.payload,
    required this.queuedAt,
  });

  String get entityFamily {
    if (kind.endsWith('_space')) return 'space';
    if (kind.endsWith('_goal')) return 'goal';
    if (kind.endsWith('_movement')) return 'movement';
    return 'profile';
  }

  int get flushPriority {
    switch (kind) {
      case 'upsert_space':
        return 0;
      case 'upsert_goal':
        return 1;
      case 'upsert_movement':
        return 2;
      case 'delete_movement':
        return 3;
      case 'delete_goal':
        return 4;
      case 'upsert_profile':
      default:
        return 5;
    }
  }

  factory PendingSyncOp.fromJson(Map<String, dynamic> j) => PendingSyncOp(
    kind: (j['kind'] ?? 'upsert_profile').toString(),
    entityId: (j['entityId'] ?? 'profile').toString(),
    payload: j['payload'] is Map
        ? Map<String, dynamic>.from(j['payload'] as Map)
        : <String, dynamic>{},
    queuedAt: (j['queuedAt'] ?? DateTime.now().toIso8601String()).toString(),
  );

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'entityId': entityId,
    'payload': payload,
    'queuedAt': queuedAt,
  };
}

class GoldVaultState extends ChangeNotifier {
  static const String sbUrl = 'https://spjvxvmhosptezmteypm.supabase.co';
  static const String sbKey = 'sb_publishable_uXP3oxhMoUXdsMDdIv71Cg_L1SA4C6B';
  static const String prodWebUrl = 'https://goldvault-app.vercel.app';
  static const MethodChannel _bankChannel = MethodChannel('app.goldvault/bank_notifications');
  static const String _pendingOpsKey = 'gv_pending_sync_ops';

  late final GoldVaultCloudAdapter _cloud;
  final Future<bool> Function()? onlineChecker;

  GoldVaultState({GoldVaultCloudAdapter? cloud, this.onlineChecker}) {
    _cloud = cloud ?? SupabaseCloudAdapter(() => sb);
  }

  bool get supportsBankNotifications => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get isNativeIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  SupabaseClient get sb => Supabase.instance.client;
  Session? session;
  bool initialized = false;
  bool loadingCloud = false;
  bool cloudSynced = false;
  bool isOnline = true;
  String? authError;
  String? syncError;
  DateTime? lastSyncedAt;

  Map<String, SpaceModel> spaces = {};
  String curSpaceId = 'space_main';
  List<MovementModel> movements = [];
  String ym = currentYm();
  String movFilter = 'all';
  String movQuery = '';

  String themePref = 'auto'; // 'auto' | 'light' | 'dark'
  double fxRate = 4200.0;

  String? displayName;
  String? avatarUrl;
  String webhookToken = '';

  // Native Android state (NotificationListenerService)
  bool androidPermissionGranted = false;
  bool androidListenerToggleOn = true;

  MovementModel? lastDeletedMovement;
  final List<PendingSyncOp> _pendingOps = [];
  StreamSubscription<AuthState>? _authSub;
  Timer? _connectivityTimer;
  Future<bool>? _activeSync;
  bool _resyncRequested = false;
  bool _supabaseReady = false;
  String? _lastUserId;

  int get pendingSyncCount => _pendingOps.length;
  bool get hasPendingSync => _pendingOps.isNotEmpty;
  List<PendingSyncOp> get pendingSyncOps => List.unmodifiable(_pendingOps);

  ThemeMode get themeMode {
    if (themePref == 'light') return ThemeMode.light;
    if (themePref == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  SpaceModel get curSpace {
    if (spaces.containsKey(curSpaceId)) return spaces[curSpaceId]!;
    if (spaces.isNotEmpty) {
      curSpaceId = spaces.keys.first;
      return spaces[curSpaceId]!;
    }
    return SpaceModel.fromTemplate('complete', first: true);
  }

  /// True while the user is authenticated and has no local spaces yet,
  /// and we have not confirmed an empty account from the cloud.
  bool get needsInitialSync => session != null && !cloudSynced && spaces.isEmpty;

  /// Only send the user to Onboarding after a verified successful cloud sync
  /// returned zero spaces (never after a sync error or before sync finishes).
  bool get needsOnboarding =>
      session != null && !loadingCloud && cloudSynced && syncError == null && spaces.isEmpty;

  List<MovementModel> get spaceMovements => movements.where((m) => m.space == curSpace.id).toList();

  List<MovementModel> get monthMovements =>
      spaceMovements.where((m) => m.date.startsWith(ym)).toList();

  List<MovementModel> get activeMonthMovements =>
      monthMovements.where((m) => m.status != 'cancelled').toList();

  int get monthIncome =>
      activeMonthMovements.where((m) => m.type == 'income').fold(0, (a, x) => a + x.amount);

  int get monthExpense =>
      activeMonthMovements.where((m) => m.type == 'expense').fold(0, (a, x) => a + x.amount);

  int get monthSaving =>
      activeMonthMovements.where((m) => m.type == 'saving').fold(0, (a, x) => a + x.amount);

  int get monthAvailable => monthIncome - monthExpense - monthSaving;

  List<MovementModel> get pendingMovements =>
      activeMonthMovements.where((m) => m.status == 'pending' && m.type != 'income').toList();

  List<MovementModel> get unreviewedBankMovements =>
      spaceMovements
          .where(
            (m) =>
                m.autoBank != null &&
                m.autoBank!.isNotEmpty &&
                !m.autoReviewed &&
                m.status != 'cancelled',
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  int goalSaved(String goalId) => spaceMovements
      .where((m) => m.type == 'saving' && m.goalId == goalId && m.status != 'cancelled')
      .fold(0, (a, x) => a + x.amount);

  String goalName(String? goalId) {
    if (goalId == null) return '';
    for (final g in curSpace.goals) {
      if (g.id == goalId) return g.name;
    }
    return '';
  }

  Future<bool> _ensureSupabaseInitialized() async {
    if (_supabaseReady) return true;
    try {
      // Check if Supabase was already initialized externally
      Supabase.instance.client;
      _supabaseReady = true;
      return true;
    } catch (_) {}
    try {
      await Supabase.initialize(
        url: sbUrl,
        // ignore: deprecated_member_use
        anonKey: sbKey,
      ).timeout(const Duration(seconds: 6));
      _supabaseReady = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> bootstrap() async {
    await _ensureSupabaseInitialized();
    await init();
  }

  void _attachAuthListener() {
    if (_authSub != null || !_supabaseReady) return;
    try {
      session = sb.auth.currentSession;
      _lastUserId = session?.user.id;
      _authSub = sb.auth.onAuthStateChange.listen((data) {
        final nextSession = data.session;
        final nextUserId = nextSession?.user.id;
        final userChanged = nextUserId != _lastUserId;
        session = nextSession;
        _lastUserId = nextUserId;
        authError = null;
        if (nextSession == null) {
          cloudSynced = false;
          syncError = null;
          loadingCloud = false;
          notifyListeners();
        } else {
          if (userChanged) {
            cloudSynced = false;
            syncError = null;
          }
          loadingCloud = true;
          notifyListeners();
          syncAll();
        }
      });
    } catch (_) {}
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      themePref = prefs.getString('gv_theme') ?? 'auto';
      curSpaceId = prefs.getString('gv_cur_space') ?? 'space_main';
      webhookToken = prefs.getString('gv_webhook_token') ?? _generateToken();
      androidListenerToggleOn = prefs.getBool('gv_bank_listener_on') ?? true;
      await prefs.setString('gv_webhook_token', webhookToken);
      _loadLocalCache(prefs);
      _loadPendingOps(prefs);
    } catch (_) {}

    _attachAuthListener();

    if (session != null) {
      loadingCloud = true;
    }
    initialized = true;
    notifyListeners();

    if (supportsBankNotifications) {
      _setupAndroidChannel();
      refreshAndroidPermission();
    }

    checkOnlineStatus();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 12), (_) => checkOnlineStatus());
    fetchFxRate();

    if (session != null) {
      syncAll();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  String _generateToken() {
    final rnd = Random.secure();
    final hex = List.generate(20, (_) => rnd.nextInt(16).toRadixString(16)).join();
    return 'vaq_$hex';
  }

  void _setupAndroidChannel() {
    _bankChannel.setMethodCallHandler((call) async {
      if (call.method == 'onBankNotification' && call.arguments is Map) {
        final map = Map<String, dynamic>.from(call.arguments as Map);
        final pkg = (map['pkg'] ?? '').toString();
        final title = (map['title'] ?? '').toString();
        final text = (map['text'] ?? '').toString();
        if (text.isNotEmpty || title.isNotEmpty) {
          ingestBankNotification(rawText: text, rawTitle: title, rawApp: pkg);
        }
      } else if (call.method == 'onAuthDeepLink' && call.arguments != null) {
        final rawUrl = call.arguments.toString();
        await handleAuthDeepLink(rawUrl);
      }
    });
    _checkInitialAuthDeepLink();
  }

  Future<void> _checkInitialAuthDeepLink() async {
    if (!supportsBankNotifications) return;
    try {
      final initialLink = await _bankChannel.invokeMethod<String>('getInitialAuthDeepLink');
      if (initialLink != null && initialLink.isNotEmpty) {
        await handleAuthDeepLink(initialLink);
      }
    } catch (_) {}
  }

  Future<void> handleAuthDeepLink(String rawUrl) async {
    if (rawUrl.isEmpty) return;
    await _ensureSupabaseInitialized();
    _attachAuthListener();
    try {
      final uri = Uri.parse(rawUrl);
      final hasCode = uri.queryParameters.containsKey('code');
      final hasToken = uri.fragment.contains('access_token=');
      final hasError = uri.queryParameters.containsKey('error') || uri.fragment.contains('error=');

      if (hasError) {
        final errDesc =
            uri.queryParameters['error_description'] ?? 'Autenticación cancelada o inválida';
        authError = errDesc;
        notifyListeners();
        return;
      }

      if (hasCode || hasToken) {
        final response = await sb.auth.getSessionFromUrl(uri);
        session = response.session;
        _lastUserId = session?.user.id;
        authError = null;
        loadingCloud = true;
        notifyListeners();
        await syncAll();
      }
    } catch (_) {
      // Fallback: if Supabase SDK already processed the deep link internally, refresh session
      if (_supabaseReady) {
        final current = sb.auth.currentSession;
        if (current != null) {
          session = current;
          _lastUserId = current.user.id;
          authError = null;
          loadingCloud = true;
          notifyListeners();
          await syncAll();
        }
      }
    }
  }

  Future<void> refreshAndroidPermission() async {
    if (!supportsBankNotifications) return;
    try {
      final enabled =
          await _bankChannel.invokeMethod<bool>('isNotificationServiceEnabled') ?? false;
      androidPermissionGranted = enabled;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> openAndroidNotificationSettings() async {
    if (!supportsBankNotifications) return;
    try {
      await _bankChannel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  Future<void> openAndroidAppDetailsSettings() async {
    if (!supportsBankNotifications) return;
    try {
      await _bankChannel.invokeMethod('openAppDetailsSettings');
    } catch (_) {}
  }

  Future<void> setAndroidListenerToggle(bool val) async {
    androidListenerToggleOn = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gv_bank_listener_on', val);
    notifyListeners();
  }

  Future<bool> checkOnlineStatus({bool manual = false}) async {
    final wasOffline = !isOnline;
    try {
      if (onlineChecker != null) {
        isOnline = await onlineChecker!();
      } else {
        final res = await http
            .get(Uri.parse('$sbUrl/rest/v1/'), headers: {'apikey': sbKey})
            .timeout(const Duration(seconds: 5));
        isOnline = res.statusCode < 500;
      }
    } catch (_) {
      isOnline = false;
    }

    if (isOnline && !_supabaseReady && _cloud is SupabaseCloudAdapter) {
      await _ensureSupabaseInitialized();
      _attachAuthListener();
    }

    notifyListeners();

    final shouldRecoverSync =
        isOnline &&
        session != null &&
        (manual || wasOffline || !cloudSynced || hasPendingSync || syncError != null);
    if (shouldRecoverSync) {
      await syncAll();
    }
    return isOnline;
  }

  Future<void> fetchFxRate() async {
    try {
      final res = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final cop = data['rates']?['COP'];
        if (cop != null) {
          fxRate = (cop as num).toDouble();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> setThemePref(String pref) async {
    themePref = pref;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gv_theme', pref);
    notifyListeners();
  }

  void shiftMonth(int delta) {
    final parts = ym.split('-');
    var y = int.tryParse(parts[0]) ?? DateTime.now().year;
    var m = (int.tryParse(parts[1]) ?? 1) + delta;
    while (m < 1) {
      m += 12;
      y--;
    }
    while (m > 12) {
      m -= 12;
      y++;
    }
    ym = '$y-${m.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  void setMovFilter(String f) {
    movFilter = f;
    notifyListeners();
  }

  void setMovQuery(String q) {
    movQuery = q;
    notifyListeners();
  }

  Future<void> googleLogin() async {
    if (!await checkOnlineStatus()) return;
    if (!await _ensureSupabaseInitialized()) {
      authError = 'No se pudo conectar con el servidor de autenticación. Intenta de nuevo.';
      notifyListeners();
      return;
    }
    _attachAuthListener();
    authError = null;
    notifyListeners();
    try {
      if (kIsWeb) {
        await sb.auth.signInWithOAuth(OAuthProvider.google, redirectTo: Uri.base.origin);
      } else {
        // Use the authorized web origin with ?apk_redirect=1 so Supabase never falls back
        // to the web app even if goldvault:// is not manually added in Supabase Redirect URLs.
        // The web index.html immediately bounces the auth code/token to goldvault://login-callback.
        await sb.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: '$prodWebUrl/?apk_redirect=1',
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      authError = 'No se pudo iniciar con Google: $e';
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      if (_supabaseReady) {
        await sb.auth.signOut();
      }
    } catch (_) {}
    session = null;
    _lastUserId = null;
    loadingCloud = false;
    cloudSynced = false;
    syncError = null;
    lastSyncedAt = null;
    _pendingOps.clear();
    spaces.clear();
    movements.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('gv_cache_spaces');
      await prefs.remove('gv_cache_movements');
      await prefs.remove(_pendingOpsKey);
    } catch (_) {}
    notifyListeners();
  }

  void _loadLocalCache(SharedPreferences prefs) {
    try {
      final spRaw = prefs.getString('gv_cache_spaces');
      final mvRaw = prefs.getString('gv_cache_movements');
      if (spRaw != null) {
        final decoded = jsonDecode(spRaw) as Map<String, dynamic>;
        spaces = decoded.map((k, v) {
          final map = Map<String, dynamic>.from(v as Map);
          final goalsRaw = (map['goals'] as List?) ?? [];
          final goals = goalsRaw
              .map((g) => GoalItem.fromJson(Map<String, dynamic>.from(g as Map)))
              .toList();
          return MapEntry(k, SpaceModel.fromRow(map, goals));
        });
      }
      if (mvRaw != null) {
        final list = jsonDecode(mvRaw) as List;
        movements = list
            .map((e) => MovementModel.fromRow(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _saveLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final spMap = spaces.map((k, v) {
        final r = v.toRow();
        r['goals'] = v.goals.map((g) => g.toJson()).toList();
        return MapEntry(k, r);
      });
      await prefs.setString('gv_cache_spaces', jsonEncode(spMap));
      await prefs.setString(
        'gv_cache_movements',
        jsonEncode(movements.map((m) => m.toRow()).toList()),
      );
      await prefs.setString('gv_cur_space', curSpaceId);
    } catch (_) {}
  }

  void _loadPendingOps(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_pendingOpsKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      _pendingOps
        ..clear()
        ..addAll(list.map((e) => PendingSyncOp.fromJson(Map<String, dynamic>.from(e as Map))));
    } catch (_) {}
  }

  Future<void> _savePendingOps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_pendingOps.isEmpty) {
        await prefs.remove(_pendingOpsKey);
      } else {
        await prefs.setString(
          _pendingOpsKey,
          jsonEncode(_pendingOps.map((e) => e.toJson()).toList()),
        );
      }
    } catch (_) {}
  }

  Future<void> _enqueuePendingOp(PendingSyncOp op) async {
    _pendingOps.removeWhere(
      (existing) => existing.entityFamily == op.entityFamily && existing.entityId == op.entityId,
    );
    _pendingOps.add(op);
    await _savePendingOps();
  }

  String _formatSyncFailure(Object err, {String action = 'sincronizar tus datos'}) {
    final msg = err.toString().toLowerCase();
    if (msg.contains('jwt') ||
        msg.contains('401') ||
        msg.contains('unauthorized') ||
        msg.contains('expired')) {
      return 'Tu sesión expiró al $action. Reintenta o vuelve a iniciar sesión.';
    }
    if (msg.contains('timeout') ||
        msg.contains('socket') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection')) {
      return 'Conexión inestable al $action. Tus cambios locales están a salvo; reintenta cuando mejore la señal.';
    }
    return 'No se pudo $action con la nube. Tus cambios locales siguen guardados.';
  }

  Future<bool> _executePendingOp(PendingSyncOp op) async {
    final uid = session?.user.id;
    switch (op.kind) {
      case 'upsert_space':
        final row = Map<String, dynamic>.from(op.payload);
        if (uid != null) row['user_id'] = uid;
        row['updated_at'] = DateTime.now().toIso8601String();
        await _cloud.upsertSpace(row);
        return true;
      case 'upsert_goal':
        final row = Map<String, dynamic>.from(op.payload);
        if (uid != null) row['user_id'] = uid;
        row['updated_at'] = DateTime.now().toIso8601String();
        await _cloud.upsertGoal(row);
        return true;
      case 'delete_goal':
        await _cloud.deleteGoal(op.entityId);
        return true;
      case 'upsert_movement':
        final row = Map<String, dynamic>.from(op.payload);
        if (uid != null) row['user_id'] = uid;
        row['updated_at'] = DateTime.now().toIso8601String();
        await _cloud.upsertMovement(row);
        return true;
      case 'delete_movement':
        await _cloud.deleteMovement(op.entityId);
        return true;
      case 'upsert_profile':
        final row = Map<String, dynamic>.from(op.payload);
        if (uid != null) row['user_id'] = uid;
        row['updated_at'] = DateTime.now().toIso8601String();
        await _cloud.upsertProfile(row);
        return true;
      default:
        return true;
    }
  }

  /// Flushes queued offline/failed writes in causal order before any remote pull.
  /// Returns true only when all pending operations have been confirmed by the cloud.
  Future<bool> _flushPendingOps() async {
    if (_pendingOps.isEmpty) return true;
    final ordered = List<PendingSyncOp>.from(_pendingOps)
      ..sort((a, b) {
        final p = a.flushPriority.compareTo(b.flushPriority);
        return p != 0 ? p : a.queuedAt.compareTo(b.queuedAt);
      });

    for (final op in ordered) {
      try {
        await _executePendingOp(op);
        _pendingOps.removeWhere(
          (e) =>
              e.entityFamily == op.entityFamily && e.entityId == op.entityId && e.kind == op.kind,
        );
        await _savePendingOps();
      } catch (e) {
        syncError = _formatSyncFailure(e, action: 'subir cambios pendientes');
        await _savePendingOps();
        return false;
      }
    }
    return true;
  }

  Future<bool> retrySync() async {
    if (!isOnline) {
      final online = await checkOnlineStatus(manual: true);
      return online && syncError == null && !hasPendingSync;
    }
    return syncAll();
  }

  Future<bool> syncAll() async {
    if (session == null) return false;
    if (_activeSync != null) {
      _resyncRequested = true;
      return _activeSync!;
    }

    final future = _runSyncAll();
    _activeSync = future;
    bool ok = false;
    bool shouldResync = false;
    try {
      ok = await future;
      shouldResync = _resyncRequested && session != null;
    } finally {
      if (identical(_activeSync, future)) {
        _activeSync = null;
      }
      _resyncRequested = false;
    }
    if (shouldResync) {
      return syncAll();
    }
    return ok;
  }

  Future<bool> _runSyncAll() async {
    if (session == null) return false;
    loadingCloud = true;
    notifyListeners();
    try {
      if (_cloud is SupabaseCloudAdapter && !await _ensureSupabaseInitialized()) {
        syncError = 'No se pudo inicializar la conexión con la nube. Reintenta en unos segundos.';
        return false;
      }

      // 1. Always push queued local mutations before pulling remote state
      // so unsynced user edits are never overwritten by stale cloud rows.
      final flushed = await _flushPendingOps();
      if (!flushed) {
        return false;
      }

      // 2. Pull fresh state from cloud
      final snapshot = await _cloud.fetchAll();

      final goalsBySpace = <String, List<GoalItem>>{};
      for (final map in snapshot.goals) {
        final spId = (map['space_id'] ?? 'space_main').toString();
        goalsBySpace.putIfAbsent(spId, () => []).add(GoalItem.fromJson(map));
      }

      final remoteSpaces = <String, SpaceModel>{};
      for (final map in snapshot.spaces) {
        final id = (map['id'] ?? 'space_main').toString();
        remoteSpaces[id] = SpaceModel.fromRow(map, goalsBySpace[id] ?? []);
      }

      final remoteMovs = <MovementModel>[];
      for (final map in snapshot.movements) {
        remoteMovs.add(MovementModel.fromRow(map));
      }

      spaces = remoteSpaces;
      movements = remoteMovs;
      if (spaces.isNotEmpty && !spaces.containsKey(curSpaceId)) {
        curSpaceId = spaces.keys.first;
      }

      final resProf = snapshot.profile;
      if (resProf != null) {
        displayName = resProf['display_name']?.toString();
        avatarUrl = resProf['avatar']?.toString();
        final dbToken = resProf['webhook_token']?.toString();
        if (dbToken != null && dbToken.isNotEmpty) {
          webhookToken = dbToken;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('gv_webhook_token', webhookToken);
          } catch (_) {}
        } else {
          await pushProfile();
        }
      } else {
        await pushProfile();
      }

      cloudSynced = true;
      if (_pendingOps.isEmpty) {
        syncError = null;
      }
      lastSyncedAt = DateTime.now();
      await _saveLocalCache();
      return _pendingOps.isEmpty;
    } catch (e) {
      syncError = _formatSyncFailure(e, action: 'sincronizar tus datos');
      return false;
    } finally {
      loadingCloud = false;
      notifyListeners();
    }
  }

  Future<void> pushProfile() async {
    if (session == null) return;
    final row = {
      'user_id': session!.user.id,
      'display_name': displayName ?? userDisplayName,
      'avatar': avatarUrl,
      'webhook_token': webhookToken,
      'default_space_id': spaces.isNotEmpty ? curSpace.id : 'space_main',
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gv_webhook_token', webhookToken);
    } catch (_) {}
    try {
      await _cloud.upsertProfile(row);
    } catch (e) {
      await _enqueuePendingOp(
        PendingSyncOp(
          kind: 'upsert_profile',
          entityId: 'profile',
          payload: row,
          queuedAt: DateTime.now().toIso8601String(),
        ),
      );
      syncError = _formatSyncFailure(e, action: 'guardar tu perfil');
      notifyListeners();
    }
  }

  String get userDisplayName {
    if (displayName != null && displayName!.trim().isNotEmpty) return displayName!.trim();
    final meta = session?.user.userMetadata;
    final fullName = meta?['full_name']?.toString() ?? meta?['name']?.toString();
    if (fullName != null && fullName.trim().isNotEmpty) return fullName.trim();
    final email = session?.user.email ?? 'Usuario';
    return email.split('@').first;
  }

  Future<void> updateDisplayName(String newName) async {
    displayName = newName.trim();
    notifyListeners();
    await pushProfile();
  }

  Future<void> createSpaceFromOnboarding(String tpl) async {
    final sp = SpaceModel.fromTemplate(tpl, first: spaces.isEmpty);
    spaces[sp.id] = sp;
    curSpaceId = sp.id;
    await _saveLocalCache();
    notifyListeners();
    await pushSpaceFull(sp);
    await pushProfile();
  }

  Future<void> createNewSpace(String name, String emoji) async {
    final sp = SpaceModel.fromTemplate('complete', customName: name, first: false);
    sp.emoji = emoji.isNotEmpty ? emoji : '💼';
    spaces[sp.id] = sp;
    curSpaceId = sp.id;
    await _saveLocalCache();
    notifyListeners();
    await pushSpaceFull(sp);
    await pushProfile();
  }

  Future<void> switchSpace(String id) async {
    if (!spaces.containsKey(id)) return;
    curSpaceId = id;
    await _saveLocalCache();
    notifyListeners();
    await pushProfile();
  }

  Future<void> pushSpace(SpaceModel sp) async {
    await _saveLocalCache();
    notifyListeners();
    if (session == null) return;
    final row = sp.toRow();
    row['user_id'] = session!.user.id;
    row['updated_at'] = DateTime.now().toIso8601String();
    try {
      await _cloud.upsertSpace(row);
    } catch (e) {
      await _enqueuePendingOp(
        PendingSyncOp(
          kind: 'upsert_space',
          entityId: sp.id,
          payload: row,
          queuedAt: DateTime.now().toIso8601String(),
        ),
      );
      syncError = _formatSyncFailure(e, action: 'guardar tu espacio');
      notifyListeners();
    }
  }

  Future<void> pushSpaceFull(SpaceModel sp) async {
    await pushSpace(sp);
    for (final g in sp.goals) {
      await pushGoal(g, sp.id);
    }
  }

  Future<void> pushGoal(GoalItem g, String spaceId) async {
    await _saveLocalCache();
    notifyListeners();
    if (session == null) return;
    final row = {
      'id': g.id,
      'user_id': session!.user.id,
      'space_id': spaceId,
      'name': g.name,
      'target': g.target,
      'achieved_at': g.achievedAt,
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      await _cloud.upsertGoal(row);
    } catch (e) {
      await _enqueuePendingOp(
        PendingSyncOp(
          kind: 'upsert_goal',
          entityId: g.id,
          payload: row,
          queuedAt: DateTime.now().toIso8601String(),
        ),
      );
      syncError = _formatSyncFailure(e, action: 'guardar la meta');
      notifyListeners();
    }
  }

  Future<void> deleteGoal(String goalId) async {
    curSpace.goals.removeWhere((g) => g.id == goalId);
    await _saveLocalCache();
    notifyListeners();
    if (session == null) return;
    try {
      await _cloud.deleteGoal(goalId);
    } catch (e) {
      await _enqueuePendingOp(
        PendingSyncOp(
          kind: 'delete_goal',
          entityId: goalId,
          payload: const {},
          queuedAt: DateTime.now().toIso8601String(),
        ),
      );
      syncError = _formatSyncFailure(e, action: 'eliminar la meta');
      notifyListeners();
    }
  }

  Future<void> saveMovement(MovementModel mv, {bool saveAsFrequent = false, int? freqDay}) async {
    final idx = movements.indexWhere((x) => x.id == mv.id);
    if (idx >= 0) {
      if (mv.autoBank != null) mv.autoReviewed = true;
      movements[idx] = mv;
    } else {
      movements.add(mv);
      if (saveAsFrequent && mv.type == 'expense' && mv.desc.isNotEmpty) {
        final exists = curSpace.frequents.any((f) => normText(f.desc) == normText(mv.desc));
        if (!exists) {
          curSpace.frequents.add(
            FrequentItem(
              id: genId('fq'),
              desc: mv.desc,
              category: mv.category ?? 'Otros',
              amount: mv.amount,
              account: mv.account ?? curSpace.accounts.first,
              day: freqDay,
              startYm: freqDay != null ? currentYm() : null,
            ),
          );
          await pushSpace(curSpace);
        }
      }
    }
    await _saveLocalCache();
    notifyListeners();
    if (session == null) return;
    final row = mv.toRow();
    row['user_id'] = session!.user.id;
    row['updated_at'] = DateTime.now().toIso8601String();
    try {
      await _cloud.upsertMovement(row);
    } catch (e) {
      await _enqueuePendingOp(
        PendingSyncOp(
          kind: 'upsert_movement',
          entityId: mv.id,
          payload: row,
          queuedAt: DateTime.now().toIso8601String(),
        ),
      );
      syncError = _formatSyncFailure(e, action: 'guardar el movimiento');
      notifyListeners();
    }
  }

  Future<void> deleteMovement(String id) async {
    final idx = movements.indexWhere((x) => x.id == id);
    if (idx < 0) return;
    lastDeletedMovement = movements.removeAt(idx);
    await _saveLocalCache();
    notifyListeners();
    if (session == null) return;
    try {
      await _cloud.deleteMovement(id);
    } catch (e) {
      await _enqueuePendingOp(
        PendingSyncOp(
          kind: 'delete_movement',
          entityId: id,
          payload: const {},
          queuedAt: DateTime.now().toIso8601String(),
        ),
      );
      syncError = _formatSyncFailure(e, action: 'eliminar el movimiento');
      notifyListeners();
    }
  }

  Future<void> undoDeleteMovement() async {
    final mv = lastDeletedMovement;
    if (mv == null) return;
    lastDeletedMovement = null;
    await saveMovement(mv);
  }

  Future<void> confirmAutoBank(String id) async {
    final idx = movements.indexWhere((x) => x.id == id);
    if (idx < 0) return;
    movements[idx].autoReviewed = true;
    await saveMovement(movements[idx]);
  }

  Future<void> confirmAllAutoBank() async {
    for (final m in unreviewedBankMovements) {
      m.autoReviewed = true;
      await saveMovement(m);
    }
  }

  Future<MovementModel?> ingestBankNotification({
    required String rawText,
    String rawTitle = '',
    String rawApp = '',
  }) async {
    final parsed = BankNotificationParser.parse(
      rawText: rawText,
      rawTitle: rawTitle,
      rawApp: rawApp,
      space: curSpace,
      fxRate: fxRate,
    );
    if (!parsed.ok) return null;

    final today = todayIso();
    final dup = spaceMovements.where(
      (m) =>
          m.date == today &&
          m.amount == parsed.amount &&
          m.autoRaw != null &&
          m.autoRaw == parsed.raw,
    );
    if (dup.isNotEmpty) return dup.first;

    final mv = MovementModel(
      id: genId('ab'),
      space: curSpace.id,
      date: today,
      type: 'expense',
      desc: parsed.desc,
      amount: parsed.amount,
      category: parsed.category,
      account: parsed.account,
      status: 'paid',
      fx: parsed.fx,
      autoBank: parsed.bank,
      autoRaw: parsed.raw,
      autoReviewed: false,
    );

    if (parsed.accountAdded) {
      await pushSpace(curSpace);
    }
    await saveMovement(mv);
    return mv;
  }

  MovementModel parseQuickEntry(String text) {
    final sp = curSpace;
    final tokens = text.trim().split(RegExp(r'\s+'));
    final norm = tokens.map(normText).toList();
    final used = List<bool>.filled(tokens.length, false);

    var type = 'expense';
    var amount = 0;
    String? category;
    String? account;
    String? source;
    String? goalId;

    for (var i = 0; i < norm.length; i++) {
      final w = norm[i];
      if (['ingreso', 'pagaron', 'recibi', 'salario', 'sueldo', 'nomina'].contains(w)) {
        type = 'income';
        used[i] = true;
        break;
      }
      if (['ahorro', 'ahorre', 'meta', 'abono'].contains(w)) {
        type = 'saving';
        used[i] = true;
        break;
      }
    }

    for (var i = 0; i < norm.length; i++) {
      if (used[i]) continue;
      final m = RegExp(r'^(\d+(?:[.,]\d+)*)(k|mil|m|millon|millones)?$').firstMatch(norm[i]);
      if (m != null) {
        final rawNum = m.group(1)!.replaceAll('.', '').replaceAll(',', '.');
        var val = double.tryParse(rawNum) ?? 0;
        final suf = m.group(2);
        if (suf == 'k' || suf == 'mil') val *= 1000;
        if (suf == 'm' || suf == 'millon' || suf == 'millones') val *= 1000000;
        if (i + 1 < norm.length && ['mil', 'k'].contains(norm[i + 1])) {
          val *= 1000;
          used[i + 1] = true;
        }
        amount = val.round();
        used[i] = true;
        break;
      }
    }

    for (var i = 0; i < tokens.length; i++) {
      if (used[i] || norm[i].length < 3) continue;
      for (final c in sp.categories) {
        if (normText(c.name).startsWith(norm[i])) {
          category = c.name;
          used[i] = true;
          break;
        }
      }
      if (category != null) break;
    }

    for (var i = 0; i < tokens.length; i++) {
      if (used[i] || norm[i].length < 2) continue;
      for (final a in sp.accounts) {
        if (normText(a).startsWith(norm[i])) {
          account = a;
          used[i] = true;
          break;
        }
      }
      if (account != null) break;
    }

    final stopWords = {
      'en',
      'con',
      'desde',
      'de',
      'a',
      'el',
      'la',
      'los',
      'las',
      'un',
      'una',
      'por',
      'del',
      'mi',
      'me',
      'y',
    };
    final rest = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      if (!used[i] && !stopWords.contains(norm[i])) rest.add(tokens[i]);
    }
    final descStr = rest.join(' ').trim();
    final finalDesc = descStr.isNotEmpty
        ? '${descStr[0].toUpperCase()}${descStr.substring(1)}'
        : (category ?? 'Movimiento');

    return MovementModel(
      id: genId('mv'),
      space: sp.id,
      date: todayIso(),
      type: type,
      desc: finalDesc,
      amount: amount,
      category: category ?? (sp.categories.isNotEmpty ? sp.categories.first.name : 'Otros'),
      account: account ?? (sp.accounts.isNotEmpty ? sp.accounts.first : 'Efectivo'),
      source: source ?? (sp.sources.isNotEmpty ? sp.sources.first : 'Salario'),
      goalId: goalId ?? (sp.goals.isNotEmpty ? sp.goals.first.id : null),
    );
  }

  // ── Per-user API Keys (for REST API & MCP Agents) ─────────────────────────

  static const String apiDocsUrl = 'https://goldvault-api.santiago-jv.workers.dev/docs';

  List<ApiKeyItem> apiKeys = [];
  bool loadingApiKeys = false;
  String? apiKeysError;

  String _generateRawApiKey() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-';
    final rng = Random.secure();
    final token = List.generate(40, (_) => alphabet[rng.nextInt(alphabet.length)]).join();
    return 'gv_live_$token';
  }

  String _hashApiKey(String rawKey) {
    return sha256.convert(utf8.encode(rawKey)).toString();
  }

  Future<void> loadApiKeys() async {
    if (session == null || !_supabaseReady) return;
    loadingApiKeys = true;
    apiKeysError = null;
    notifyListeners();
    try {
      final rows = await Supabase.instance.client
          .from('api_keys')
          .select('id,name,key_prefix,scopes,expires_at,revoked_at,last_used_at,created_at')
          .eq('user_id', session!.user.id)
          .order('created_at', ascending: false);
      apiKeys = (rows as List)
          .map((e) => ApiKeyItem.fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      apiKeysError = 'No se pudieron cargar tus API Keys ($e)';
    } finally {
      loadingApiKeys = false;
      notifyListeners();
    }
  }

  /// Creates a new per-user API key. Returns the plaintext secret ONCE (never persisted).
  Future<String?> createApiKey({required String name, int? expiresInDays}) async {
    if (session == null || !_supabaseReady) return null;
    final cleanName = name.trim().isEmpty ? 'Agente IA' : name.trim();
    final rawKey = _generateRawApiKey();
    final keyHash = _hashApiKey(rawKey);
    final keyPrefix = rawKey.substring(0, 16);
    final expiresAt = expiresInDays != null && expiresInDays > 0
        ? DateTime.now().toUtc().add(Duration(days: expiresInDays)).toIso8601String()
        : null;

    await Supabase.instance.client.from('api_keys').insert({
      'user_id': session!.user.id,
      'name': cleanName,
      'key_prefix': keyPrefix,
      'key_hash': keyHash,
      'scopes': const ['read', 'write'],
      'expires_at': expiresAt,
    });
    await loadApiKeys();
    return rawKey;
  }

  /// Atomically rotates an existing API key by replacing its SHA-256 hash and prefix.
  Future<String?> rotateApiKey(String keyId) async {
    if (session == null || !_supabaseReady) return null;
    final rawKey = _generateRawApiKey();
    final keyHash = _hashApiKey(rawKey);
    final keyPrefix = rawKey.substring(0, 16);

    await Supabase.instance.client
        .from('api_keys')
        .update({'key_prefix': keyPrefix, 'key_hash': keyHash, 'revoked_at': null})
        .eq('id', keyId)
        .eq('user_id', session!.user.id);
    await loadApiKeys();
    return rawKey;
  }

  Future<void> revokeApiKey(String keyId) async {
    if (session == null || !_supabaseReady) return;
    await Supabase.instance.client
        .from('api_keys')
        .update({'revoked_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', keyId)
        .eq('user_id', session!.user.id);
    await loadApiKeys();
  }

  Future<void> deleteApiKey(String keyId) async {
    if (session == null || !_supabaseReady) return;
    await Supabase.instance.client
        .from('api_keys')
        .delete()
        .eq('id', keyId)
        .eq('user_id', session!.user.id);
    await loadApiKeys();
  }
}
