import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/gold_theme.dart';
import '../widgets/charts.dart';

class OfflineGuardScreen extends StatelessWidget {
  final GoldVaultState state;
  const OfflineGuardScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 44, color: c.amber),
                const SizedBox(height: 14),
                Text('Sin conexión a internet', style: GVTxt.h2(c), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'GoldVault requiere conexión activa a internet para mantener tus cuentas, movimientos y bancos sincronizados sin errores.',
                  style: GVTxt.sm(c),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.acc,
                      foregroundColor: c.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    onPressed: () => state.checkOnlineStatus(manual: true),
                    child: Text('Reintentar conexión', style: GVTxt.body(c, weight: FontWeight.w800, color: c.ink)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GoogleLoginScreen extends StatelessWidget {
  final GoldVaultState state;
  const GoogleLoginScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GoldVaultLogo(fontSize: GVTxt.fsH1),
                const SizedBox(height: 12),
                Text(
                  'Inicia sesión con tu cuenta de Google para sincronizar tus espacios, metas y lectura automática de bancos en tiempo real.',
                  style: GVTxt.sm(c),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1F2937),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                        side: BorderSide(color: c.line),
                      ),
                    ),
                    onPressed: () => state.googleLogin(),
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28, color: Color(0xFF4285F4)),
                    label: Text(
                      'Continuar con Google',
                      style: GVTxt.body(c, weight: FontWeight.w800, color: const Color(0xFF1F2937)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'El inicio de sesión con Google y la conexión a internet son obligatorios.',
                  style: GVTxt.xs(c),
                  textAlign: TextAlign.center,
                ),
                if (state.authError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.authError!,
                    style: GVTxt.sm(c, color: c.amber, weight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  final GoldVaultState state;
  const OnboardingScreen({super.key, required this.state});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;

  static const _slides = [
    (
      icon: Icons.account_balance_wallet_outlined,
      title1: 'Claridad sobre ',
      title2: 'tu dinero',
      desc: 'Registra cada movimiento y entiende con precisión a dónde va tu plata cada mes.'
    ),
    (
      icon: Icons.bolt_rounded,
      title1: 'Lectura ',
      title2: 'automática',
      desc: 'Detecta notificaciones de Nequi, Nu Bank, Lulo Bank, ARQ y Morse para registrar tus gastos al instante.'
    ),
    (
      icon: Icons.track_changes_rounded,
      title1: 'Metas que ',
      title2: 'sí cumples',
      desc: 'Crea metas de ahorro, sigue tu avance y celebra cuando llegues al 100%.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final isLast = step == _slides.length;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const GoldVaultLogo(fontSize: GVTxt.fsH3),
                      if (!isLast)
                        TextButton(
                          onPressed: () => setState(() => step = _slides.length),
                          child: Text('Saltar', style: GVTxt.sm(c, weight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  Expanded(
                    child: isLast ? _buildTemplateChoice(c) : _buildSlide(c, _slides[step]),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length + 1, (i) {
                      final on = i == step;
                      return GestureDetector(
                        onTap: () => setState(() => step = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: on ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: on ? c.acc : c.line,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  if (!isLast)
                    Row(
                      children: [
                        if (step > 0) ...[
                          TextButton(
                            onPressed: () => setState(() => step--),
                            child: Text('‹ Atrás', style: GVTxt.sm(c, weight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.acc,
                              foregroundColor: c.ink,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                            ),
                            onPressed: () => setState(() => step++),
                            child: Text(
                              step == _slides.length - 1 ? 'Empezar' : 'Siguiente',
                              style: GVTxt.body(c, weight: FontWeight.w800, color: c.ink),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(GVColors c, dynamic s) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(s.icon as IconData, size: 58, color: c.acc),
        const SizedBox(height: 24),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GVTxt.h1(c),
            children: [
              TextSpan(text: s.title1 as String),
              TextSpan(text: s.title2 as String, style: TextStyle(color: c.acc)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            s.desc as String,
            style: GVTxt.body(c, weight: FontWeight.w500, color: c.mut),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateChoice(GVColors c) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.auto_awesome_outlined, size: 54, color: c.acc),
        const SizedBox(height: 20),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GVTxt.h1(c),
            children: [
              const TextSpan(text: '¿Cómo quieres '),
              TextSpan(text: 'empezar?', style: TextStyle(color: c.acc)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _tplCard(
          c: c,
          icon: Icons.auto_awesome_rounded,
          title: 'Configuración recomendada',
          desc: 'Categorías, cuentas (Nequi, Nu, Lulo, ARQ, Morse) y metas listas. Empieza de inmediato.',
          onTap: () => widget.state.createSpaceFromOnboarding('complete'),
        ),
        const SizedBox(height: 12),
        _tplCard(
          c: c,
          icon: Icons.layers_outlined,
          title: 'Desde cero',
          desc: 'Define tu propia estructura: cada categoría, cuenta y meta.',
          onTap: () => widget.state.createSpaceFromOnboarding('zero'),
        ),
      ],
    );
  }

  Widget _tplCard({
    required GVColors c,
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.acc.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.acc.withValues(alpha: 0.24)),
              ),
              child: Icon(icon, color: c.acc, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GVTxt.body(c, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(desc, style: GVTxt.sm(c)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoldVaultShell extends StatefulWidget {
  final GoldVaultState state;
  const GoldVaultShell({super.key, required this.state});

  @override
  State<GoldVaultShell> createState() => _GoldVaultShellState();
}

class _GoldVaultShellState extends State<GoldVaultShell> with WidgetsBindingObserver {
  int tabIndex = 0;
  final TextEditingController _quickCtrl = TextEditingController();
  final TextEditingController _customBankCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _quickCtrl.dispose();
    _customBankCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.state.refreshAndroidPermission();
      widget.state.syncAll();
    }
  }

  void _openMovementSheet({MovementModel? editing, MovementModel? prefilled}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MovementSheet(
        state: widget.state,
        editing: editing,
        prefilled: prefilled,
      ),
    );
  }

  void _submitQuickEntry() {
    final raw = _quickCtrl.text.trim();
    if (raw.isEmpty) {
      _openMovementSheet();
      return;
    }
    final pre = widget.state.parseQuickEntry(raw);
    _quickCtrl.clear();
    _openMovementSheet(prefilled: pre);
  }

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final st = widget.state;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: switch (tabIndex) {
              0 => _buildHomeView(c, st),
              1 => _buildMovementsView(c, st),
              2 => _buildGoalsView(c, st),
              _ => _buildSettingsView(c, st),
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(c),
    );
  }

  Widget _buildBottomNav(GVColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.bg.withValues(alpha: 0.92),
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              height: 68,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navBtn(c, 0, Icons.home_outlined, 'Inicio'),
                  _navBtn(c, 1, Icons.format_list_bulleted_rounded, 'Movs'),
                  GestureDetector(
                    onTap: () => _openMovementSheet(),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [c.acc, c.acc2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: c.acc.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(Icons.add_rounded, color: c.ink, size: 28),
                    ),
                  ),
                  _navBtn(c, 2, Icons.track_changes_rounded, 'Metas'),
                  _navBtn(c, 3, Icons.settings_outlined, 'Ajustes'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navBtn(GVColors c, int idx, IconData icon, String label) {
    final on = tabIndex == idx;
    return InkWell(
      onTap: () => setState(() => tabIndex = idx),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: on ? c.txt : c.mut),
            const SizedBox(height: 3),
            Text(
              label,
              style: GVTxt.xs2(c, color: on ? c.txt : c.mut, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNav(GVColors c, GoldVaultState st) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => st.shiftMonth(-1),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.chevron_left_rounded, size: 18, color: c.mut),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              monthShortLabel(st.ym),
              style: GVTxt.sm(c, weight: FontWeight.w700, color: c.txt),
            ),
          ),
          InkWell(
            onTap: () => st.shiftMonth(1),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.chevron_right_rounded, size: 18, color: c.mut),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HOME VIEW ====================
  Widget _buildHomeView(GVColors c, GoldVaultState st) {
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Top Header
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
                      onTap: () => _showSpacesDialog(c, st),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.line),
                        ),
                        child: Text(st.curSpace.emoji, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildMonthNav(c, st),
            ],
          ),
          const SizedBox(height: 14),

          // Hero Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.acc.withValues(alpha: 0.14), c.card],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISPONIBLE ESTE MES',
                  style: GVTxt.xs(c, weight: FontWeight.w700, letterSpacing: 0.9),
                ),
                const SizedBox(height: 6),
                Text(formatMoney(st.monthAvailable), style: GVTxt.display(c)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _heroPill(c, 'INGRESOS', st.monthIncome),
                    const SizedBox(width: 8),
                    _heroPill(c, 'GASTOS', st.monthExpense),
                    const SizedBox(width: 8),
                    _heroPill(c, 'AHORRO', st.monthSaving),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick Entry Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.line),
                  ),
                  child: TextField(
                    controller: _quickCtrl,
                    style: GVTxt.body(c),
                    onSubmitted: (_) => _submitQuickEntry(),
                    decoration: InputDecoration(
                      hintText: 'Ej: 20 mil almuerzo en nequi',
                      hintStyle: GVTxt.sm(c, color: c.placeholder),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _submitQuickEntry,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [c.acc, c.acc2]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.north_east_rounded, color: c.ink, size: 19),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Frequent Chips
          if (st.curSpace.frequents.isNotEmpty) ...[
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: st.curSpace.frequents.length,
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
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registrado: ${f.desc} ${formatMoney(f.amount)}')),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.line),
                      ),
                      child: Row(
                        children: [
                          Text(st.curSpace.iconForCategory(f.category)),
                          const SizedBox(width: 6),
                          Text(f.desc, style: GVTxt.sm(c, weight: FontWeight.w600, color: c.txt)),
                          const SizedBox(width: 6),
                          Text(formatMoney(f.amount), style: GVTxt.xs(c, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Auto-Detected Bank Payments Card
          if (unrev.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.acc.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 17, color: c.acc),
                          const SizedBox(width: 7),
                          Text('Pagos detectados', style: GVTxt.h3(c)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => st.confirmAllAutoBank(),
                        child: Text('Confirmar todos', style: GVTxt.xs(c, weight: FontWeight.w700, color: c.acc)),
                      ),
                    ],
                  ),
                  Text(
                    'Registrados automáticamente desde tus notificaciones bancarias como gasto pagado. Toca la categoría para cambiarla.',
                    style: GVTxt.sm(c),
                  ),
                  const SizedBox(height: 8),
                  ...unrev.take(8).map((x) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: c.line)),
                        ),
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
                                          style: GVTxt.body(c, weight: FontWeight.w700),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '− ${formatMoney(x.amount)}',
                                        style: GVTxt.body(c, weight: FontWeight.w800, color: c.red),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      _bankBadge(c, x.autoBank ?? 'Banco'),
                                      InkWell(
                                        onTap: () => _openMovementSheet(editing: x),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: c.card2,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: c.line),
                                          ),
                                          child: Text(
                                            '${st.curSpace.iconForCategory(x.category)} ${x.category ?? 'Otros'} ✎',
                                            style: GVTxt.xs(c, weight: FontWeight.w700, color: c.txt),
                                          ),
                                        ),
                                      ),
                                      if (x.fx != null)
                                        Text('US\$${x.fx!.amount}', style: GVTxt.xs(c)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => st.confirmAutoBank(x.id),
                              icon: Icon(Icons.check_rounded, color: c.green, size: 20),
                              tooltip: 'Confirmar',
                            ),
                            IconButton(
                              onPressed: () => st.deleteMovement(x.id),
                              icon: Icon(Icons.delete_outline_rounded, color: c.red, size: 19),
                              tooltip: 'Descartar',
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

          // Pending Movements Card
          if (pend.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 16, color: c.amber),
                          const SizedBox(width: 6),
                          Text('Pendiente por pagar', style: GVTxt.h3(c)),
                        ],
                      ),
                      Text(
                        formatMoney(pend.fold(0, (a, x) => a + x.amount)),
                        style: GVTxt.xs(c, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...pend.take(5).map((m) => _movementTile(c, st, m)),
                ],
              ),
            ),

          // Trend Card
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Tendencia', style: GVTxt.h3(c))),
                    const SizedBox(width: 8),
                    Text('últimos 6 meses', style: GVTxt.xs(c)),
                  ],
                ),
                const SizedBox(height: 10),
                TrendChartWidget(
                  spaceMovements: st.spaceMovements,
                  currentYm: st.ym,
                ),
              ],
            ),
          ),

          // Category Distribution Card
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Distribución por categoría', style: GVTxt.h3(c))),
                    if (catEntries.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(formatMoney(st.monthExpense), style: GVTxt.xs(c)),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                DonutChartWidget(byCat: byCat, totalExpense: st.monthExpense),
                if (catEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Sin gastos registrados este mes.', style: GVTxt.sm(c)),
                    ),
                  )
                else
                  ...catEntries.map((e) {
                    final cap = st.curSpace.budgets[e.key];
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
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.card2,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: c.line),
                            ),
                            child: Text(
                              st.curSpace.iconForCategory(e.key),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: GVTxt.sm(c, weight: FontWeight.w600, color: c.txt)),
                                    Text(
                                      cap != null
                                          ? '${formatMoney(e.value)} / ${formatMoney(cap)}'
                                          : formatMoney(e.value),
                                      style: GVTxt.sm(c, weight: FontWeight.w700, color: c.txt),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 6,
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

          // Accounts Grid Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pagos por cuenta', style: GVTxt.h3(c)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: st.curSpace.accounts.map((acc) {
                    return Container(
                      width: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.card2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(acc, style: GVTxt.xs(c, weight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(formatMoney(byAcct[acc] ?? 0), style: GVTxt.h3(c).copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPill(GVColors c, String label, int amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: c.txt.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GVTxt.xs2(c, letterSpacing: 0.6)),
            const SizedBox(height: 4),
            Text(
              formatMoney(amount),
              style: GVTxt.body(c, weight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankBadge(GVColors c, String bankName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.acc.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '⚡ $bankName',
        style: GVTxt.xs2(c, color: c.acc, weight: FontWeight.w800),
      ),
    );
  }

  Widget _movementTile(GVColors c, GoldVaultState st, MovementModel x) {
    final isInc = x.type == 'income';
    final isSav = x.type == 'saving';
    final amtColor = isInc ? c.green : (isSav ? c.acc2 : c.red);
    final sign = isInc ? '+' : '−';
    final sub = isInc
        ? (x.source ?? 'Ingreso')
        : (isSav ? st.goalName(x.goalId) : (x.category ?? 'Otros'));

    return InkWell(
      onTap: () => _openMovementSheet(editing: x),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.card2,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: c.line),
              ),
              child: isInc
                  ? Icon(Icons.south_west_rounded, size: 18, color: c.green)
                  : isSav
                      ? Icon(Icons.account_balance_rounded, size: 18, color: c.acc)
                      : Text(st.curSpace.iconForCategory(x.category), style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    x.desc.isNotEmpty ? x.desc : sub,
                    style: GVTxt.body(c, weight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '$sub${x.account != null ? ' · ${x.account}' : ''}${x.fx != null ? ' · US\$${x.fx!.amount}' : ''}',
                        style: GVTxt.xs(c),
                      ),
                      if (x.autoBank != null && x.autoBank!.isNotEmpty)
                        _bankBadge(c, x.autoBank!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign ${formatMoney(x.amount)}',
                  style: GVTxt.body(c, weight: FontWeight.w800, color: amtColor),
                ),
                if (!isInc) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (x.status == 'paid' ? c.green : c.amber).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      x.status == 'paid' ? 'Pagado' : 'Pendiente',
                      style: GVTxt.xs2(
                        c,
                        color: x.status == 'paid' ? c.green : c.amber,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MOVEMENTS VIEW ====================
  Widget _buildMovementsView(GVColors c, GoldVaultState st) {
    var list = st.monthMovements.toList()..sort((a, b) => b.date.compareTo(a.date));
    if (st.movFilter != 'all') {
      list = list.where((x) => st.movFilter == 'pending' ? x.status == 'pending' : x.type == st.movFilter).toList();
    }
    if (st.movQuery.trim().isNotEmpty) {
      final nq = normText(st.movQuery);
      list = list.where((x) {
        final hay = normText('${x.desc} ${x.category ?? ''} ${x.account ?? ''} ${x.amount}');
        return hay.contains(nq);
      }).toList();
    }

    final grouped = <String, List<MovementModel>>{};
    for (final m in list) {
      grouped.putIfAbsent(m.date, () => []).add(m);
    }

    final filters = [
      ('all', 'Todos'),
      ('expense', 'Gastos'),
      ('saving', 'Ahorros'),
      ('income', 'Ingresos'),
      ('pending', 'Pendientes'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Movimientos', style: GVTxt.h2(c))),
            const SizedBox(width: 8),
            _buildMonthNav(c, st),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.line),
          ),
          child: TextField(
            style: GVTxt.body(c),
            onChanged: st.setMovQuery,
            decoration: InputDecoration(
              hintText: 'Buscar por descripción, categoría, cuenta, monto…',
              hintStyle: GVTxt.sm(c, color: c.placeholder),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = filters[i];
              final on = st.movFilter == f.$1;
              return InkWell(
                onTap: () => st.setMovFilter(f.$1),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: on ? c.acc.withValues(alpha: 0.14) : c.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: on ? c.acc : c.line),
                  ),
                  child: Text(f.$2, style: GVTxt.sm(c, weight: FontWeight.w600, color: c.txt)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (grouped.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                st.movQuery.isNotEmpty ? 'Nada coincide con tu búsqueda.' : 'Sin movimientos en este periodo.',
                style: GVTxt.sm(c),
              ),
            ),
          )
        else
          ...grouped.entries.map((entry) {
            final dt = DateTime.tryParse(entry.key) ?? DateTime.now();
            final dayTitle = '${dt.day} DE ${kMonthsEs[dt.month - 1].toUpperCase()}';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 4),
                  child: Text(dayTitle, style: GVTxt.xs(c, weight: FontWeight.w700, letterSpacing: 0.6)),
                ),
                ...entry.value.map((m) => _movementTile(c, st, m)),
              ],
            );
          }),
      ],
    );
  }

  // ==================== GOALS VIEW ====================
  Widget _buildGoalsView(GVColors c, GoldVaultState st) {
    final goals = st.curSpace.goals;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        RichText(
          text: TextSpan(
            style: GVTxt.h2(c),
            children: [
              const TextSpan(text: 'Metas de '),
              TextSpan(text: 'ahorro', style: TextStyle(color: c.acc)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (goals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Aún no has definido metas de ahorro.', style: GVTxt.sm(c)),
            ),
          )
        else
          ...goals.map((g) {
            final saved = st.goalSaved(g.id);
            final pct = g.target > 0 ? ((saved / g.target) * 100).clamp(0.0, 100.0) : 0.0;
            final done = pct >= 100;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: done ? c.acc : c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${done ? '🏆 ' : ''}${g.name}',
                          style: GVTxt.h3(c).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text('${pct.toStringAsFixed(0)}%', style: GVTxt.body(c, weight: FontWeight.w800, color: c.acc)),
                      IconButton(
                        onPressed: () => st.deleteGoal(g.id),
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: c.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (pct / 100.0).clamp(0.02, 1.0),
                      minHeight: 8,
                      backgroundColor: c.card2,
                      valueColor: AlwaysStoppedAnimation<Color>(c.acc),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${formatMoney(saved)} ahorrado',
                          style: GVTxt.xs(c),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Meta: ${formatMoney(g.target)}',
                          style: GVTxt.xs(c, weight: FontWeight.w700, color: c.txt),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 6),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            side: BorderSide(color: c.line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => _showAddGoalDialog(c, st),
          child: Text('＋ Nueva meta', style: GVTxt.sm(c, weight: FontWeight.w700, color: c.txt)),
        ),
      ],
    );
  }

  // ==================== SETTINGS VIEW ====================
  Widget _buildSettingsView(GVColors c, GoldVaultState st) {
    final webhookUrl = '${GoldVaultState.prodWebUrl}/api/bank?token=${Uri.encodeComponent(st.webhookToken)}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text('Ajustes', style: GVTxt.h2(c)),
        const SizedBox(height: 14),

        // Apariencia
        _settingsCard(
          c: c,
          title: 'Apariencia',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _themeBtn(c, st, 'auto', 'Automático'),
                  const SizedBox(width: 6),
                  _themeBtn(c, st, 'light', 'Claro'),
                  const SizedBox(width: 6),
                  _themeBtn(c, st, 'dark', 'Oscuro'),
                ],
              ),
              const SizedBox(height: 8),
              Text('Automático sigue el tema de tu dispositivo.', style: GVTxt.xs(c)),
            ],
          ),
        ),

        // Perfil y Sincronización Google
        _settingsCard(
          c: c,
          title: 'Cuenta de Google y Sincronización',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: c.card2,
                    child: Text(
                      st.userDisplayName.isNotEmpty ? st.userDisplayName[0].toUpperCase() : 'G',
                      style: GVTxt.h2(c).copyWith(color: c.acc),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(st.userDisplayName, style: GVTxt.h3(c)),
                        Text(st.session?.user.email ?? '', style: GVTxt.xs(c)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => st.logout(),
                    child: Text('Cerrar sesión', style: GVTxt.xs(c, weight: FontWeight.w700, color: c.txt)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Lectura Automática Nativa de Bancos (Nequi, Nu, Lulo, ARQ, Morse)
        _settingsCard(
          c: c,
          title: 'Lectura automática de bancos',
          trailing: _bankBadge(c, kIsWeb ? 'Web / iOS' : 'Android Nativo'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detecta notificaciones de pagos realizados en Nequi, Nu Bank, Lulo Bank, ARQ y Morse para registrarlos automáticamente como gasto pagado.',
                style: GVTxt.sm(c),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _bankBadge(c, 'Nequi'),
                  _bankBadge(c, 'Nu Bank'),
                  _bankBadge(c, 'Lulo Bank'),
                  _bankBadge(c, 'ARQ (COP/USD)'),
                  _bankBadge(c, 'Morse'),
                ],
              ),
              const SizedBox(height: 14),

              // Si está en la App Nativa de Android (!kIsWeb): control nativo 100% sin MacroDroid
              if (!kIsWeb) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.card2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: st.androidPermissionGranted ? c.green.withValues(alpha: 0.5) : c.amber.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            st.androidPermissionGranted ? Icons.verified_rounded : Icons.notifications_active_outlined,
                            color: st.androidPermissionGranted ? c.green : c.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              st.androidPermissionGranted
                                  ? 'Servicio Nativo de Android Activo (24/7)'
                                  : 'Permiso de lectura de notificaciones pendiente',
                              style: GVTxt.body(c, weight: FontWeight.w700),
                            ),
                          ),
                          if (st.androidPermissionGranted)
                            Switch(
                              value: st.androidListenerToggleOn,
                              activeThumbColor: c.acc,
                              onChanged: (v) => st.setAndroidListenerToggle(v),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        st.androidPermissionGranted
                            ? 'GoldVault escucha directamente a Nequi, Nu Bank, Lulo Bank, ARQ y Morse en segundo plano sin usar aplicaciones externas.'
                            : 'Activa el permiso oficial de Android para que GoldVault detecte tus pagos bancarios directamente sin apps externas.',
                        style: GVTxt.xs(c),
                      ),
                      const SizedBox(height: 10),
                      if (!st.androidPermissionGranted) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'En Android 13 / 14 / 15 ("Ajuste restringido"):',
                                style: GVTxt.xs(c, weight: FontWeight.w700, color: c.acc),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '1. Toca el botón «Paso 1: Abrir Info de App», toca los 3 puntos (⋮) arriba a la derecha y selecciona «Permitir ajustes restringidos».\n2. Luego toca «Paso 2: Activar permiso de notificaciones» y enciende el interruptor de GoldVault.',
                                style: GVTxt.xs(c),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              side: BorderSide(color: c.acc),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => st.openAndroidAppDetailsSettings(),
                            icon: Icon(Icons.security_rounded, color: c.acc, size: 17),
                            label: Text(
                              'Paso 1: Abrir Info de App (⋮ → Ajustes restringidos)',
                              style: GVTxt.xs(c, weight: FontWeight.w700, color: c.acc),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.acc,
                            foregroundColor: c.ink,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => st.openAndroidNotificationSettings(),
                          child: Text(
                            st.androidPermissionGranted
                                ? 'Configurar permiso en Android'
                                : 'Paso 2: Activar permiso de notificaciones',
                            style: GVTxt.sm(c, weight: FontWeight.w800, color: c.ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // En Web (iOS / Desktop): Botón de descarga de la App Nativa de Android (.APK) + Atajos iOS
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.card2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🤖 En Android (App 100% Nativa sin apps externas)', style: GVTxt.body(c, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'Instala la App Nativa de GoldVault para Android (.APK) que incluye el servicio nativo del sistema para leer notificaciones de Nequi, Nu, Lulo, ARQ y Morse directamente.',
                        style: GVTxt.xs(c),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.acc,
                            foregroundColor: c.ink,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => launchUrl(
                            Uri.parse('https://github.com/santiago-jv/goldvault/releases/latest'),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: Icon(Icons.android_rounded, color: c.ink, size: 18),
                          label: Text(
                            'Descargar GoldVault Nativo (.APK)',
                            style: GVTxt.sm(c, weight: FontWeight.w800, color: c.ink),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('🍎 En iPhone (Atajos nativos de iOS / Apple Pay)', style: GVTxt.body(c, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'En Atajos de iOS → Automatización (Transacción de Wallet o Mensaje del banco), usa «Obtener contenido de URL» con tu enlace personal:',
                        style: GVTxt.xs(c),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c.line),
                        ),
                        child: SelectableText(
                          '$webhookUrl&app=Wallet&text=Pagaste%20[Monto]%20en%20[Comercio]',
                          style: GVTxt.xs(c, color: c.txt),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: webhookUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enlace copiado al portapapeles')),
                            );
                          },
                          child: Text('Copiar enlace personal para iOS', style: GVTxt.xs(c, weight: FontWeight.w700, color: c.txt)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Text(
                'PROBAR LECTURA AUTOMÁTICA AHORA',
                style: GVTxt.xs(c, weight: FontWeight.w700, letterSpacing: 0.7),
              ),
              const SizedBox(height: 4),
              Text('Toca un banco para simular una notificación real o pega el texto de un pago:', style: GVTxt.xs(c)),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kBankSamples.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final s = kBankSamples[i];
                    return InkWell(
                      onTap: () async {
                        final mv = await st.ingestBankNotification(
                          rawText: s.text,
                          rawTitle: s.title,
                          rawApp: s.pkg,
                        );
                        if (mv != null && mounted) {
                          setState(() => tabIndex = 0);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('⚡ ${s.bank}: ${mv.desc} (${formatMoney(mv.amount)}) registrado')),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: c.card2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c.line),
                        ),
                        child: Text('⚡ ${s.bank}', style: GVTxt.sm(c, weight: FontWeight.w600, color: c.txt)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.card2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.line),
                      ),
                      child: TextField(
                        controller: _customBankCtrl,
                        style: GVTxt.body(c),
                        decoration: InputDecoration(
                          hintText: 'Pega una notificación (ej: Pagaste \$25.000 en EXITO con Nequi)',
                          hintStyle: GVTxt.sm(c, color: c.placeholder),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.acc,
                      foregroundColor: c.ink,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final txt = _customBankCtrl.text.trim();
                      if (txt.isEmpty) return;
                      final mv = await st.ingestBankNotification(rawText: txt);
                      if (mv != null && mounted) {
                        _customBankCtrl.clear();
                        setState(() => tabIndex = 0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('⚡ ${mv.autoBank}: ${mv.desc} (${formatMoney(mv.amount)}) registrado')),
                        );
                      }
                    },
                    child: Text('Detectar', style: GVTxt.sm(c, weight: FontWeight.w800, color: c.ink)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Personalización de Espacios y Categorías
        _settingsCard(
          c: c,
          title: 'Personalización',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Categorías, cuentas y espacios separados.', style: GVTxt.sm(c)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.acc,
                        foregroundColor: c.ink,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showCustomizeDialog(c, st),
                      child: Text('Personalizar espacio', style: GVTxt.sm(c, weight: FontWeight.w800, color: c.ink)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showSpacesDialog(c, st),
                      child: Text('Gestionar espacios', style: GVTxt.sm(c, weight: FontWeight.w700, color: c.txt)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsCard({
    required GVColors c,
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: GVTxt.h3(c))),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _themeBtn(GVColors c, GoldVaultState st, String key, String label) {
    final on = st.themePref == key;
    return Expanded(
      child: InkWell(
        onTap: () => st.setThemePref(key),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? c.acc : c.card2,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: GVTxt.xs(c, weight: FontWeight.w800, color: on ? c.ink : c.mut),
          ),
        ),
      ),
    );
  }

  void _showSpacesDialog(GVColors c, GoldVaultState st) {
    final nameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tus espacios', style: GVTxt.h3(c)),
            const SizedBox(height: 10),
            ...st.spaces.values.map((sp) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(sp.emoji, style: const TextStyle(fontSize: 22)),
                  title: Text(sp.name, style: GVTxt.body(c, weight: FontWeight.w700)),
                  trailing: sp.id == st.curSpace.id
                      ? Text('Actual', style: GVTxt.xs(c, color: c.acc, weight: FontWeight.w700))
                      : null,
                  onTap: () {
                    st.switchSpace(sp.id);
                    Navigator.pop(ctx);
                  },
                )),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameCtrl,
                    style: GVTxt.body(c),
                    decoration: InputDecoration(
                      hintText: 'Nuevo espacio (ej: Negocio, Viaje)',
                      hintStyle: GVTxt.sm(c, color: c.placeholder),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: c.acc, foregroundColor: c.ink),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    st.createNewSpace(nameCtrl.text.trim(), '💼');
                    Navigator.pop(ctx);
                  },
                  child: const Text('Crear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog(GVColors c, GoldVaultState st) {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card2,
        title: Text('Nueva meta de ahorro', style: GVTxt.h3(c)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: GVTxt.body(c),
              decoration: InputDecoration(hintText: 'Nombre (ej: Viaje, Moto)', hintStyle: GVTxt.sm(c)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              style: GVTxt.body(c),
              decoration: InputDecoration(hintText: 'Monto objetivo en COP', hintStyle: GVTxt.sm(c)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: c.acc, foregroundColor: c.ink),
            onPressed: () {
              final nm = nameCtrl.text.trim();
              final tg = int.tryParse(targetCtrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
              if (nm.isEmpty || tg <= 0) return;
              final g = GoalItem(id: genId('goal'), name: nm, target: tg);
              st.curSpace.goals.add(g);
              st.pushGoal(g, st.curSpace.id);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showCustomizeDialog(GVColors c, GoldVaultState st) {
    final catCtrl = TextEditingController();
    final acctCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Personalizar — ${st.curSpace.name}', style: GVTxt.h3(c)),
                const SizedBox(height: 12),
                Text('CATEGORÍAS', style: GVTxt.xs(c, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: st.curSpace.categories
                      .map((cat) => Chip(
                            backgroundColor: c.card,
                            label: Text('${cat.icon} ${cat.name}', style: GVTxt.sm(c, color: c.txt)),
                            onDeleted: st.curSpace.categories.length > 1
                                ? () {
                                    st.curSpace.categories.remove(cat);
                                    st.pushSpace(st.curSpace);
                                    setModal(() {});
                                  }
                                : null,
                          ))
                      .toList(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: catCtrl,
                        style: GVTxt.body(c),
                        decoration: InputDecoration(hintText: 'Nueva categoría', hintStyle: GVTxt.sm(c)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (catCtrl.text.trim().isEmpty) return;
                        st.curSpace.categories.add(CategoryItem(name: catCtrl.text.trim(), icon: '🏷️'));
                        catCtrl.clear();
                        st.pushSpace(st.curSpace);
                        setModal(() {});
                      },
                      child: const Text('＋ Añadir'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('CUENTAS', style: GVTxt.xs(c, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: st.curSpace.accounts
                      .map((a) => Chip(
                            backgroundColor: c.card,
                            label: Text(a, style: GVTxt.sm(c, color: c.txt)),
                            onDeleted: st.curSpace.accounts.length > 1
                                ? () {
                                    st.curSpace.accounts.remove(a);
                                    st.pushSpace(st.curSpace);
                                    setModal(() {});
                                  }
                                : null,
                          ))
                      .toList(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: acctCtrl,
                        style: GVTxt.body(c),
                        decoration: InputDecoration(hintText: 'Nueva cuenta', hintStyle: GVTxt.sm(c)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (acctCtrl.text.trim().isEmpty) return;
                        st.curSpace.accounts.add(acctCtrl.text.trim());
                        acctCtrl.clear();
                        st.pushSpace(st.curSpace);
                        setModal(() {});
                      },
                      child: const Text('＋ Añadir'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
                childAspectRatio: 1.15,
                children: sp.categories.map((cat) {
                  final on = category == cat.name;
                  return InkWell(
                    onTap: () => setState(() => category = cat.name),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: on ? c.acc.withValues(alpha: 0.14) : c.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: on ? c.acc : c.line),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(
                            cat.name,
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
