import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/gold_theme.dart';
import '../widgets/gv_components.dart';

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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: GVCard(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GVSquircleIcon(
                      size: 56,
                      radius: 16,
                      backgroundColor: c.amber.withValues(alpha: 0.12),
                      borderColor: c.amber.withValues(alpha: 0.28),
                      child: Icon(Icons.cloud_off_rounded, size: 28, color: c.amber),
                    ),
                    const SizedBox(height: 18),
                    Text('Sin conexión a internet', style: GVTxt.h2(c), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'GoldVault requiere conexión activa para mantener tus cuentas, movimientos y bancos sincronizados sin errores.',
                      style: GVTxt.sm(c),
                      textAlign: TextAlign.center,
                    ),
                    if (state.hasPendingSync) ...[
                      const SizedBox(height: 12),
                      GVPillBadge(
                        label: '${state.pendingSyncCount} cambio(s) pendiente(s) a salvo',
                        color: c.acc,
                      ),
                    ],
                    const SizedBox(height: 24),
                    GVPillButton(
                      label: 'Reintentar conexión',
                      onPressed: () => state.checkOnlineStatus(manual: true),
                    ),
                  ],
                ),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: GVCard(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GVSquircleIcon(
                      size: 56,
                      radius: 16,
                      backgroundColor: c.amber.withValues(alpha: 0.12),
                      borderColor: c.amber.withValues(alpha: 0.28),
                      child: Icon(Icons.sync_problem_rounded, size: 28, color: c.amber),
                    ),
                    const SizedBox(height: 18),
                    Text('Error al sincronizar', style: GVTxt.h2(c), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      state.syncError ??
                          'No pudimos cargar tus cuentas desde la nube. Reintenta para evitar perder información.',
                      style: GVTxt.sm(c),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GVPillButton(
                      label: state.loadingCloud ? 'Reintentando…' : 'Reintentar sincronización',
                      onPressed: state.loadingCloud ? null : () => state.retrySync(),
                    ),
                    const SizedBox(height: 10),
                    GVPillButton(
                      label: 'Cerrar sesión',
                      variant: GVPillButtonVariant.secondary,
                      onPressed: () => state.logout(),
                    ),
                  ],
                ),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: GVCard(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GoldVaultLogo(fontSize: GVTxt.fsH1),
                    const SizedBox(height: 14),
                    Text(
                      'Claridad sobre tu dinero.',
                      style: GVTxt.h3(c),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tus cuentas, movimientos y metas en un solo lugar.',
                      style: GVTxt.sm(c),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    GVPillButton(
                      label: 'Continuar con Google',
                      variant: GVPillButtonVariant.dark,
                      leading: const Icon(Icons.g_mobiledata_rounded, size: 26, color: Color(0xFF4285F4)),
                      onPressed: () => state.googleLogin(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sincroniza tus finanzas entre tus dispositivos.',
                      style: GVTxt.xs(c),
                      textAlign: TextAlign.center,
                    ),
                    if (state.authError != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        state.authError!,
                        style: GVTxt.xs(c, color: c.amber, weight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  final GoldVaultState state;
  const OnboardingScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GoldVaultLogo(fontSize: GVTxt.fsH1),
                  const SizedBox(height: 28),
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
                  const SizedBox(height: 8),
                  Text(
                    'Puedes cambiar categorías, cuentas y metas cuando quieras.',
                    style: GVTxt.sm(c),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _templateCard(
                    c: c,
                    icon: Icons.auto_awesome_rounded,
                    badge: 'Recomendado',
                    title: 'Configuración recomendada',
                    desc: 'Categorías, cuentas (Nequi, Nu, Lulo, ARQ, Morse) y metas listas. Empieza de inmediato.',
                    highlighted: true,
                    onTap: () => state.createSpaceFromOnboarding('complete'),
                  ),
                  const SizedBox(height: 14),
                  _templateCard(
                    c: c,
                    icon: Icons.layers_outlined,
                    title: 'Desde cero',
                    desc: 'Define tu propia estructura: cada categoría, cuenta y meta.',
                    onTap: () => state.createSpaceFromOnboarding('zero'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _templateCard({
    required GVColors c,
    required IconData icon,
    required String title,
    required String desc,
    String? badge,
    bool highlighted = false,
    required VoidCallback onTap,
  }) {
    return GVCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      borderColor: highlighted ? c.acc.withValues(alpha: 0.45) : c.line,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GVSquircleIcon(
            size: 46,
            radius: 14,
            backgroundColor: highlighted ? c.acc.withValues(alpha: 0.14) : c.card2,
            borderColor: highlighted ? c.acc.withValues(alpha: 0.3) : c.line,
            child: Icon(icon, color: highlighted ? c.acc : c.txt, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null) ...[
                  GVPillBadge(label: badge, color: c.acc),
                  const SizedBox(height: 6),
                ],
                Text(title, style: GVTxt.h3(c)),
                const SizedBox(height: 4),
                Text(desc, style: GVTxt.sm(c)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Icon(Icons.chevron_right_rounded, color: c.tertiary, size: 20),
          ),
        ],
      ),
    );
  }
}
