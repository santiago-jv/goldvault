import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class GoldVaultState extends ChangeNotifier {
  static const String sbUrl = 'https://spjvxvmhosptezmteypm.supabase.co';
  static const String sbKey = 'sb_publishable_uXP3oxhMoUXdsMDdIv71Cg_L1SA4C6B';
  static const String prodWebUrl = 'https://goldvault-app.vercel.app';
  static const MethodChannel _bankChannel = MethodChannel('app.goldvault/bank_notifications');

  SupabaseClient get sb => Supabase.instance.client;
  Session? session;
  bool initialized = false;
  bool loadingCloud = false;
  bool isOnline = true;
  String? authError;

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

  // Estado nativo de Android (NotificationListenerService)
  bool androidPermissionGranted = false;
  bool androidListenerToggleOn = true;

  MovementModel? lastDeletedMovement;
  StreamSubscription<AuthState>? _authSub;
  Timer? _connectivityTimer;

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

  bool get needsOnboarding => session != null && !loadingCloud && spaces.isEmpty;

  List<MovementModel> get spaceMovements =>
      movements.where((m) => m.space == curSpace.id).toList();

  List<MovementModel> get monthMovements =>
      spaceMovements.where((m) => m.date.startsWith(ym)).toList();

  List<MovementModel> get activeMonthMovements =>
      monthMovements.where((m) => m.status != 'cancelled').toList();

  int get monthIncome => activeMonthMovements
      .where((m) => m.type == 'income')
      .fold(0, (a, x) => a + x.amount);

  int get monthExpense => activeMonthMovements
      .where((m) => m.type == 'expense')
      .fold(0, (a, x) => a + x.amount);

  int get monthSaving => activeMonthMovements
      .where((m) => m.type == 'saving')
      .fold(0, (a, x) => a + x.amount);

  int get monthAvailable => monthIncome - monthExpense - monthSaving;

  List<MovementModel> get pendingMovements => activeMonthMovements
      .where((m) => m.status == 'pending' && m.type != 'income')
      .toList();

  List<MovementModel> get unreviewedBankMovements => spaceMovements
      .where((m) => m.autoBank != null && m.autoBank!.isNotEmpty && !m.autoReviewed && m.status != 'cancelled')
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

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    themePref = prefs.getString('gv_theme') ?? 'auto';
    curSpaceId = prefs.getString('gv_cur_space') ?? 'space_main';
    webhookToken = prefs.getString('gv_webhook_token') ?? _generateToken();
    androidListenerToggleOn = prefs.getBool('gv_bank_listener_on') ?? true;
    await prefs.setString('gv_webhook_token', webhookToken);

    _loadLocalCache(prefs);
    session = sb.auth.currentSession;

    _authSub = sb.auth.onAuthStateChange.listen((data) {
      session = data.session;
      authError = null;
      notifyListeners();
      if (session != null) {
        syncAll();
      }
    });

    if (!kIsWeb) {
      _setupAndroidChannel();
      await refreshAndroidPermission();
    }

    await checkOnlineStatus();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 12), (_) => checkOnlineStatus());
    fetchFxRate();

    if (session != null) {
      await syncAll();
    }

    initialized = true;
    notifyListeners();
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
      }
    });
  }

  Future<void> refreshAndroidPermission() async {
    if (kIsWeb) return;
    try {
      final enabled = await _bankChannel.invokeMethod<bool>('isNotificationServiceEnabled') ?? false;
      androidPermissionGranted = enabled;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> openAndroidNotificationSettings() async {
    if (kIsWeb) return;
    try {
      await _bankChannel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  Future<void> openAndroidAppDetailsSettings() async {
    if (kIsWeb) return;
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
    try {
      final res = await http
          .get(Uri.parse('$sbUrl/rest/v1/'), headers: {'apikey': sbKey})
          .timeout(const Duration(seconds: 5));
      isOnline = res.statusCode < 500;
    } catch (_) {
      isOnline = false;
    }
    notifyListeners();
    if (isOnline && manual && session != null) {
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
    authError = null;
    notifyListeners();
    try {
      if (kIsWeb) {
        await sb.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.origin,
        );
      } else {
        await sb.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'goldvault://login-callback',
        );
      }
    } catch (e) {
      authError = 'No se pudo iniciar con Google: $e';
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await sb.auth.signOut();
    session = null;
    spaces.clear();
    movements.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gv_cache_spaces');
    await prefs.remove('gv_cache_movements');
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
          final goals = goalsRaw.map((g) => GoalItem.fromJson(Map<String, dynamic>.from(g as Map))).toList();
          return MapEntry(k, SpaceModel.fromRow(map, goals));
        });
      }
      if (mvRaw != null) {
        final list = jsonDecode(mvRaw) as List;
        movements = list.map((e) => MovementModel.fromRow(Map<String, dynamic>.from(e as Map))).toList();
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

  Future<void> syncAll() async {
    if (session == null) return;
    loadingCloud = true;
    notifyListeners();
    try {
      final resSpaces = await sb.from('spaces').select();
      final resGoals = await sb.from('goals').select();
      final resMovs = await sb.from('movements').select();
      final resProf = await sb
          .from('profiles')
          .select('display_name,avatar,webhook_token,default_space_id')
          .maybeSingle();

      final goalsBySpace = <String, List<GoalItem>>{};
      for (final g in (resGoals as List)) {
        final map = Map<String, dynamic>.from(g as Map);
        final spId = (map['space_id'] ?? 'space_main').toString();
        goalsBySpace.putIfAbsent(spId, () => []).add(GoalItem.fromJson(map));
      }

      final remoteSpaces = <String, SpaceModel>{};
      for (final s in (resSpaces as List)) {
        final map = Map<String, dynamic>.from(s as Map);
        final id = (map['id'] ?? 'space_main').toString();
        remoteSpaces[id] = SpaceModel.fromRow(map, goalsBySpace[id] ?? []);
      }

      final remoteMovs = <MovementModel>[];
      for (final m in (resMovs as List)) {
        remoteMovs.add(MovementModel.fromRow(Map<String, dynamic>.from(m as Map)));
      }

      spaces = remoteSpaces;
      movements = remoteMovs;
      if (spaces.isNotEmpty && !spaces.containsKey(curSpaceId)) {
        curSpaceId = spaces.keys.first;
      }

      if (resProf != null) {
        displayName = resProf['display_name']?.toString();
        avatarUrl = resProf['avatar']?.toString();
        final dbToken = resProf['webhook_token']?.toString();
        if (dbToken != null && dbToken.isNotEmpty) {
          webhookToken = dbToken;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('gv_webhook_token', webhookToken);
        } else {
          await pushProfile();
        }
      } else {
        await pushProfile();
      }

      await _saveLocalCache();
    } catch (_) {
    } finally {
      loadingCloud = false;
      notifyListeners();
    }
  }

  Future<void> pushProfile() async {
    if (session == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gv_webhook_token', webhookToken);
      await sb.from('profiles').upsert({
        'user_id': session!.user.id,
        'display_name': displayName ?? userDisplayName,
        'avatar': avatarUrl,
        'webhook_token': webhookToken,
        'default_space_id': spaces.isNotEmpty ? curSpace.id : 'space_main',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (_) {}
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
    try {
      final row = sp.toRow();
      row['user_id'] = session!.user.id;
      row['updated_at'] = DateTime.now().toIso8601String();
      await sb.from('spaces').upsert(row, onConflict: 'user_id,id');
    } catch (_) {}
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
    try {
      await sb.from('goals').upsert({
        'id': g.id,
        'user_id': session!.user.id,
        'space_id': spaceId,
        'name': g.name,
        'target': g.target,
        'achieved_at': g.achievedAt,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,id');
    } catch (_) {}
  }

  Future<void> deleteGoal(String goalId) async {
    curSpace.goals.removeWhere((g) => g.id == goalId);
    await _saveLocalCache();
    notifyListeners();
    if (session == null) return;
    try {
      await sb.from('goals').delete().eq('id', goalId);
    } catch (_) {}
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
          curSpace.frequents.add(FrequentItem(
            id: genId('fq'),
            desc: mv.desc,
            category: mv.category ?? 'Otros',
            amount: mv.amount,
            account: mv.account ?? curSpace.accounts.first,
            day: freqDay,
            startYm: freqDay != null ? currentYm() : null,
          ));
          await pushSpace(curSpace);
        }
      }
    }
    await _saveLocalCache();
    notifyListeners();
    if (session == null) return;
    try {
      final row = mv.toRow();
      row['user_id'] = session!.user.id;
      row['updated_at'] = DateTime.now().toIso8601String();
      await sb.from('movements').upsert(row, onConflict: 'user_id,id');
    } catch (_) {}
  }

  Future<void> deleteMovement(String id) async {
    final idx = movements.indexWhere((x) => x.id == id);
    if (idx < 0) return;
    lastDeletedMovement = movements.removeAt(idx);
    await _saveLocalCache();
    notifyListeners();
    if (session == null) return;
    try {
      await sb.from('movements').delete().eq('id', id);
    } catch (_) {}
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
    final dup = spaceMovements.where((m) =>
        m.date == today &&
        m.amount == parsed.amount &&
        m.autoRaw != null &&
        m.autoRaw == parsed.raw);
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

    final stopWords = {'en', 'con', 'desde', 'de', 'a', 'el', 'la', 'los', 'las', 'un', 'una', 'por', 'del', 'mi', 'me', 'y'};
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
}
