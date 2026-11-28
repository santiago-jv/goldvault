import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../theme/gold_theme.dart';
import '../widgets/gv_components.dart';
import 'api_keys_sheet.dart';
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

        // 1. Appearance
        GVCard(
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GVSectionHeader(title: 'Apariencia'),
              const SizedBox(height: 12),
              GVSegmentedControl<String>(
                value: state.themePref,
                items: const [('auto', 'Automático'), ('light', 'Claro'), ('dark', 'Oscuro')],
                onChanged: state.setThemePref,
              ),
            ],
          ),
        ),

        // 2. Account & Sync
        GVCard(
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GVSquircleIcon(
                    size: 44,
                    radius: 22,
                    child: Text(
                      state.userDisplayName.isNotEmpty
                          ? state.userDisplayName[0].toUpperCase()
                          : 'G',
                      style: GVTxt.h3(c),
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
                    label: 'Salir',
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
                          ? 'Sincronizando…'
                          : (state.syncError ??
                                (state.hasPendingSync
                                    ? '${state.pendingSyncCount} cambio(s) pendiente(s)'
                                    : 'Sincronizado')),
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
                        style: GVTxt.xs(c, color: c.blue, weight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. Bank Automation (concise per platform)
        GVCard(
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GVSectionHeader(
                title: 'Bancos automáticos',
                trailing: GVPillBadge(
                  label: state.supportsBankNotifications ? 'Android' : 'Atajos iOS',
                  color: state.supportsBankNotifications ? c.green : c.blue,
                ),
              ),
              const SizedBox(height: 6),
              Text('Compatible con Nequi, Nu, Lulo, ARQ y Morse.', style: GVTxt.sm(c)),
              const SizedBox(height: 14),
              if (state.supportsBankNotifications)
                _buildAndroidNativePanel(c)
              else
                _buildShortcutsPanel(context, c, webhookUrl),
            ],
          ),
        ),

        // 4. AI Agents (API Keys & MCP Docs)
        GVCard(
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GVSectionHeader(
                title: 'Agentes IA (API y MCP)',
                trailing: GVPillBadge(label: 'API Key', color: c.blue),
              ),
              const SizedBox(height: 6),
              Text(
                'Conecta Claude, Antigravity o Cursor a tu bóveda para registrar y consultar movimientos.',
                style: GVTxt.sm(c),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GVPillButton(
                      label: 'API Keys',
                      compact: true,
                      leading: Icon(Icons.vpn_key_outlined, size: 16, color: c.ink),
                      onPressed: () => showApiKeysSheet(context, state),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GVPillButton(
                      label: 'Documentación',
                      variant: GVPillButtonVariant.secondary,
                      compact: true,
                      leading: Icon(Icons.menu_book_outlined, size: 16, color: c.txt),
                      onPressed: () => launchUrl(
                        Uri.parse(GoldVaultState.apiDocsUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 5. Space Structure
        GVCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GVSectionHeader(title: 'Espacio y categorías'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GVPillButton(
                      label: 'Personalizar',
                      compact: true,
                      onPressed: () => showCustomizeSpaceSheet(context, state),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GVPillButton(
                      label: 'Espacios',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              state.androidPermissionGranted
                  ? Icons.check_circle_rounded
                  : Icons.notifications_none_rounded,
              color: state.androidPermissionGranted ? c.green : c.amber,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.androidPermissionGranted
                    ? 'Lectura activa en segundo plano'
                    : 'Permiso de notificaciones pendiente',
                style: GVTxt.body(c, weight: FontWeight.w600),
              ),
            ),
            if (state.androidPermissionGranted)
              Switch(
                value: state.androidListenerToggleOn,
                activeThumbColor: c.green,
                onChanged: state.setAndroidListenerToggle,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (!state.androidPermissionGranted) ...[
          Text(
            'En Android 13+: abre Info de App → ⋮ → «Permitir ajustes restringidos» y luego activa el permiso.',
            style: GVTxt.xs(c),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GVPillButton(
                  label: '1. Info de App',
                  variant: GVPillButtonVariant.secondary,
                  compact: true,
                  onPressed: () => state.openAndroidAppDetailsSettings(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GVPillButton(
                  label: '2. Activar permiso',
                  compact: true,
                  onPressed: () => state.openAndroidNotificationSettings(),
                ),
              ),
            ],
          ),
        ] else
          GVPillButton(
            label: 'Configurar permiso en Android',
            variant: GVPillButtonVariant.secondary,
            compact: true,
            onPressed: () => state.openAndroidNotificationSettings(),
          ),
      ],
    );
  }

  Widget _buildShortcutsPanel(BuildContext context, GVColors c, String webhookUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!state.isNativeIos) ...[
          GVPillButton(
            label: 'Descargar App Android (.APK)',
            compact: true,
            leading: Icon(Icons.android_rounded, color: c.ink, size: 17),
            onPressed: () => launchUrl(
              Uri.parse('https://github.com/santiago-jv/goldvault/releases/latest'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'En iPhone (Atajos → Automatización de Wallet), usa tu enlace personal:',
          style: GVTxt.xs(c),
        ),
        const SizedBox(height: 8),
        GVPillButton(
          label: 'Copiar enlace para Atajos iOS',
          variant: GVPillButtonVariant.secondary,
          compact: true,
          leading: Icon(Icons.copy_rounded, color: c.txt, size: 15),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: webhookUrl));
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Enlace copiado al portapapeles')));
          },
        ),
      ],
    );
  }
}
