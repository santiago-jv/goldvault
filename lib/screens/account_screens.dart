part of 'home_and_shells.dart';

class OfflineGuardScreen extends StatelessWidget {
  final GoldVaultState state;
  const OfflineGuardScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                  if (state.hasPendingSync) ...[
                    const SizedBox(height: 10),
                    Text(
                      '${state.pendingSyncCount} cambio(s) guardado(s) localmente se enviarán al reconectar.',
                      style: GVTxt.xs(c, color: c.acc, weight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
      ),
    );
  }
}

class SyncErrorScreen extends StatelessWidget {
  final GoldVaultState state;
  const SyncErrorScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                  Icon(Icons.sync_problem_rounded, size: 44, color: c.amber),
                  const SizedBox(height: 14),
                  Text('Error al sincronizar', style: GVTxt.h2(c), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    state.syncError ?? 'No pudimos cargar tus cuentas desde la nube. Reintenta para evitar perder información.',
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
                      onPressed: state.loadingCloud ? null : () => state.retrySync(),
                      child: Text(
                        state.loadingCloud ? 'Reintentando…' : 'Reintentar sincronización',
                        style: GVTxt.body(c, weight: FontWeight.w800, color: c.ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: c.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      ),
                      onPressed: () => state.logout(),
                      child: Text('Cerrar sesión', style: GVTxt.sm(c, weight: FontWeight.w700, color: c.txt)),
                    ),
                  ),
                ],
              ),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                    'Tus cuentas, movimientos y metas en un solo lugar.',
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
                    'Sincroniza tus finanzas entre tus dispositivos.',
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
  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GoldVaultLogo(fontSize: GVTxt.fsH1),
                  const SizedBox(height: 32),
                  _buildTemplateChoice(c),
                ],
              ),
            ),
          ),
        ),
      ),
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
