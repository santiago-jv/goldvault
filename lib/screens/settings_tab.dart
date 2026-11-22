import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/gold_theme.dart';
import '../widgets/gv_components.dart';
import 'space_modals.dart';

class SettingsTab extends StatelessWidget {
  final GoldVaultState state;
  final TextEditingController customBankController;
  final VoidCallback onNavigateHome;

  const SettingsTab({
    super.key,
    required this.state,
    required this.customBankController,
    required this.onNavigateHome,
  });

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final webhookUrl =
        '${GoldVaultState.prodWebUrl}/api/bank?token=${Uri.encodeComponent(state.webhookToken)}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        Text('Ajustes', style: GVTxt.h1(c)),
        const SizedBox(height: 16),

        // Appearance settings card
        GVCard(
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GVSectionHeader(eyebrow: 'Tema', title: 'Apariencia'),
              const SizedBox(height: 12),
              GVSegmentedControl<String>(
                value: state.themePref,
                items: const [
                  ('auto', 'Automático'),
                  ('light', 'Claro'),
                  ('dark', 'Oscuro'),
                ],
                onChanged: state.setThemePref,
              ),
              const SizedBox(height: 10),
              Text('Automático sigue la apariencia del sistema.', style: GVTxt.xs(c)),
            ],
          ),
        ),

        // Google account and cloud synchronization card
        GVCard(
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GVSectionHeader(
                eyebrow: 'Nube',
                title: 'Cuenta de Google y Sincronización',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  GVSquircleIcon(
                    size: 46,
                    radius: 23,
                    backgroundColor: c.acc.withValues(alpha: 0.14),
                    borderColor: c.acc.withValues(alpha: 0.3),
                    child: Text(
                      state.userDisplayName.isNotEmpty
                          ? state.userDisplayName[0].toUpperCase()
                          : 'G',
                      style: GVTxt.h2(c, color: c.acc),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.userDisplayName,
                          style: GVTxt.h3(c),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          state.session?.user.email ?? '',
                          style: GVTxt.xs(c),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GVPillButton(
                    label: 'Cerrar sesión',
                    variant: GVPillButtonVariant.secondary,
                    fullWidth: false,
                    compact: true,
                    onPressed: () => state.logout(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: c.line),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    state.syncError != null
                        ? Icons.sync_problem_rounded
                        : (state.hasPendingSync
                            ? Icons.cloud_upload_outlined
                            : Icons.cloud_done_outlined),
                    size: 17,
                    color: state.syncError != null || state.hasPendingSync ? c.amber : c.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.loadingCloud
                          ? 'Sincronizando con la nube…'
                          : (state.syncError ??
                              (state.hasPendingSync
                                  ? '${state.pendingSyncCount} cambio(s) pendiente(s) por enviar'
                                  : 'Sincronizado con la nube')),
                      style: GVTxt.xs(c),
                    ),
                  ),
                  InkWell(
                    onTap: state.loadingCloud ? null : () => state.retrySync(),
                    borderRadius: BorderRadius.circular(GVRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        'Sincronizar',
                        style: GVTxt.xs(c, color: c.acc, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Native bank notification listener / iOS Shortcuts card
        GVCard(
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GVSectionHeader(
                eyebrow: 'Automatización',
                title: 'Lectura automática de bancos',
                trailing: GVPillBadge(
                  label: state.supportsBankNotifications ? '⚡ Android' : '⚡ Atajos',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Detecta notificaciones de pagos realizados en Nequi, Nu Bank, Lulo Bank, ARQ y Morse para registrarlos automáticamente.',
                style: GVTxt.sm(c),
              ),
              const SizedBox(height: 10),
              const Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  GVPillBadge(label: 'Nequi'),
                  GVPillBadge(label: 'Nu Bank'),
                  GVPillBadge(label: 'Lulo Bank'),
                  GVPillBadge(label: 'ARQ (COP/USD)'),
                  GVPillBadge(label: 'Morse'),
                ],
              ),
              const SizedBox(height: 14),

              if (state.supportsBankNotifications)
                _buildAndroidNativePanel(c)
              else
                _buildShortcutsAndDownloadPanel(context, c, webhookUrl),

              const SizedBox(height: 18),
              Text(
                'PROBAR LECTURA AUTOMÁTICA',
                style: GVTxt.xs2(c, color: c.tertiary, weight: FontWeight.w700, letterSpacing: 0.7),
              ),
              const SizedBox(height: 4),
              Text(
                'Toca un banco para simular una notificación o pega el texto de un pago:',
                style: GVTxt.xs(c),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kBankSamples.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final s = kBankSamples[i];
                    return InkWell(
                      onTap: () async {
                        final mv = await state.ingestBankNotification(
                          rawText: s.text,
                          rawTitle: s.title,
                          rawApp: s.pkg,
                        );
                        if (mv != null && context.mounted) {
                          onNavigateHome();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('⚡ ${s.bank}: ${mv.desc} (${formatMoney(mv.amount)}) registrado'),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(GVRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: c.card2,
                          borderRadius: BorderRadius.circular(GVRadius.pill),
                          border: Border.all(color: c.line),
                        ),
                        child: Text(
                          '⚡ ${s.bank}',
                          style: GVTxt.xs(c, weight: FontWeight.w600, color: c.txt),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GVTextField(
                      controller: customBankController,
                      hintText: 'Ej: Pagaste \$25.000 en EXITO con Nequi',
                    ),
                  ),
                  const SizedBox(width: 8),
                  GVPillButton(
                    label: 'Detectar',
                    fullWidth: false,
                    compact: true,
                    onPressed: () async {
                      final txt = customBankController.text.trim();
                      if (txt.isEmpty) return;
                      final mv = await state.ingestBankNotification(rawText: txt);
                      if (mv != null && context.mounted) {
                        customBankController.clear();
                        onNavigateHome();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⚡ ${mv.autoBank}: ${mv.desc} (${formatMoney(mv.amount)}) registrado'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Space and category customization card
        GVCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GVSectionHeader(eyebrow: 'Estructura', title: 'Personalización'),
              const SizedBox(height: 6),
              Text('Categorías, cuentas y espacios separados.', style: GVTxt.sm(c)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GVPillButton(
                      label: 'Personalizar espacio',
                      compact: true,
                      onPressed: () => showCustomizeSpaceSheet(context, state),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GVPillButton(
                      label: 'Gestionar espacios',
                      variant: GVPillButtonVariant.secondary,
                      compact: true,
                      onPressed: () => showSpacesSheet(context, state),
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

  Widget _buildAndroidNativePanel(GVColors c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card2,
        borderRadius: BorderRadius.circular(GVRadius.control),
        border: Border.all(
          color: state.androidPermissionGranted
              ? c.green.withValues(alpha: 0.45)
              : c.amber.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.androidPermissionGranted
                    ? Icons.verified_rounded
                    : Icons.notifications_active_outlined,
                color: state.androidPermissionGranted ? c.green : c.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.androidPermissionGranted
                      ? 'Servicio Nativo de Android Activo (24/7)'
                      : 'Permiso de lectura de notificaciones pendiente',
                  style: GVTxt.body(c, weight: FontWeight.w600),
                ),
              ),
              if (state.androidPermissionGranted)
                Switch(
                  value: state.androidListenerToggleOn,
                  activeThumbColor: c.acc,
                  onChanged: state.setAndroidListenerToggle,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            state.androidPermissionGranted
                ? 'GoldVault escucha directamente a Nequi, Nu Bank, Lulo Bank, ARQ y Morse en segundo plano.'
                : 'Activa el permiso oficial de Android para que GoldVault detecte tus pagos bancarios directamente.',
            style: GVTxt.xs(c),
          ),
          const SizedBox(height: 12),
          if (!state.androidPermissionGranted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
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
                    '1. Toca «Paso 1: Abrir Info de App», abre los 3 puntos (⋮) arriba a la derecha y elige «Permitir ajustes restringidos».\n2. Luego toca «Paso 2: Activar permiso de notificaciones» y activa GoldVault.',
                    style: GVTxt.xs(c),
                  ),
                ],
              ),
            ),
            GVPillButton(
              label: 'Paso 1: Abrir Info de App',
              variant: GVPillButtonVariant.secondary,
              compact: true,
              leading: Icon(Icons.security_rounded, color: c.acc, size: 16),
              onPressed: () => state.openAndroidAppDetailsSettings(),
            ),
            const SizedBox(height: 8),
          ],
          GVPillButton(
            label: state.androidPermissionGranted
                ? 'Configurar permiso en Android'
                : 'Paso 2: Activar permiso de notificaciones',
            compact: true,
            onPressed: () => state.openAndroidNotificationSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutsAndDownloadPanel(BuildContext context, GVColors c, String webhookUrl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card2,
        borderRadius: BorderRadius.circular(GVRadius.control),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!state.isNativeIos) ...[
            Text('🤖 En Android (App 100% Nativa)', style: GVTxt.body(c, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Instala la App Nativa de GoldVault (.APK) para leer notificaciones de Nequi, Nu, Lulo, ARQ y Morse directamente.',
              style: GVTxt.xs(c),
            ),
            const SizedBox(height: 10),
            GVPillButton(
              label: 'Descargar GoldVault Nativo (.APK)',
              compact: true,
              leading: Icon(Icons.android_rounded, color: c.ink, size: 17),
              onPressed: () => launchUrl(
                Uri.parse('https://github.com/santiago-jv/goldvault/releases/latest'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            '🍎 En iPhone (Atajos nativos de iOS / Apple Pay)',
            style: GVTxt.body(c, weight: FontWeight.w600),
          ),
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
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.line),
            ),
            child: SelectableText(
              '$webhookUrl&app=Wallet&text=Pagaste%20[Monto]%20en%20[Comercio]',
              style: GVTxt.xs(c, color: c.txt),
            ),
          ),
          const SizedBox(height: 10),
          GVPillButton(
            label: 'Copiar enlace personal para iOS',
            variant: GVPillButtonVariant.secondary,
            compact: true,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: webhookUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enlace copiado al portapapeles')),
              );
            },
          ),
        ],
      ),
    );
  }
}
