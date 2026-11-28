import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/gold_theme.dart';
import '../widgets/gv_components.dart';
import '../widgets/gv_motion.dart';

Future<void> showApiKeysSheet(BuildContext context, GoldVaultState state) {
  state.loadApiKeys();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ApiKeysSheet(state: state),
  );
}

class _ApiKeysSheet extends StatefulWidget {
  final GoldVaultState state;

  const _ApiKeysSheet({required this.state});

  @override
  State<_ApiKeysSheet> createState() => _ApiKeysSheetState();
}

class _ApiKeysSheetState extends State<_ApiKeysSheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  int? _expiresInDays = 90;
  String? _revealedSecret;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    setState(() => _submitting = true);
    try {
      final secret = await widget.state.createApiKey(
        name: _nameCtrl.text,
        expiresInDays: _expiresInDays,
      );
      if (mounted && secret != null) {
        _nameCtrl.clear();
        setState(() => _revealedSecret = secret);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo crear la API Key: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleRotate(ApiKeyItem item) async {
    setState(() => _submitting = true);
    try {
      final secret = await widget.state.rotateApiKey(item.id);
      if (mounted && secret != null) {
        setState(() => _revealedSecret = secret);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GVColors.of(context);
    final st = widget.state;

    return ListenableBuilder(
      listenable: st,
      builder: (context, _) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Container(
          constraints: BoxConstraints(
            maxWidth: 540,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 24),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: c.lineStrong,
                      borderRadius: BorderRadius.circular(GVRadius.pill),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('API Keys (API y MCP)', style: GVTxt.h2(c)),
                    InkWell(
                      onTap: () => launchUrl(
                        Uri.parse(GoldVaultState.apiDocsUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      borderRadius: BorderRadius.circular(GVRadius.pill),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Ver docs ↗',
                          style: GVTxt.xs(c, weight: FontWeight.w600, color: c.blue),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Crea llaves privadas para conectar tu agente de IA por MCP o REST API. Solo tú puedes verlas o rotarlas.',
                  style: GVTxt.xs(c),
                ),
                const SizedBox(height: 16),

                // One-time secret reveal banner
                if (_revealedSecret != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(GVRadius.control),
                      border: Border.all(color: c.green.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.vpn_key_rounded, size: 16, color: c.green),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Cópiala ahora — no se volverá a mostrar',
                                style: GVTxt.xs(c, weight: FontWeight.w700, color: c.green),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _revealedSecret!,
                          style: GVTxt.xs(c, weight: FontWeight.w600, color: c.txt),
                        ),
                        const SizedBox(height: 10),
                        GVPillButton(
                          label: 'Copiar API Key',
                          compact: true,
                          leading: Icon(Icons.copy_rounded, size: 15, color: c.ink),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _revealedSecret!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('API Key copiada al portapapeles')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Create new API key form
                Text(
                  'NUEVA API KEY',
                  style: GVTxt.xs2(
                    c,
                    color: c.tertiary,
                    weight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 8),
                GVTextField(
                  controller: _nameCtrl,
                  hintText: 'Nombre (ej: Claude Desktop, Antigravity)',
                  prefixIcon: Icons.label_outline_rounded,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _expiryChip(c, '30 días', 30),
                    _expiryChip(c, '90 días', 90),
                    _expiryChip(c, '1 año', 365),
                    _expiryChip(c, 'Sin expiración', null),
                  ],
                ),
                const SizedBox(height: 12),
                GVPillButton(
                  label: _submitting ? 'Generando…' : 'Crear API Key',
                  compact: true,
                  onPressed: _submitting ? null : _handleCreate,
                ),
                const SizedBox(height: 20),
                Divider(height: 1, color: c.line),
                const SizedBox(height: 16),

                // Existing keys list
                Text(
                  'TUS LLAVES (${st.apiKeys.length})',
                  style: GVTxt.xs2(
                    c,
                    color: c.tertiary,
                    weight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 10),
                if (st.loadingApiKeys)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (st.apiKeysError != null)
                  Text(st.apiKeysError!, style: GVTxt.xs(c, color: c.red))
                else if (st.apiKeys.isEmpty)
                  Text('Aún no tienes API Keys creadas.', style: GVTxt.xs(c))
                else
                  ...st.apiKeys.map((item) => _buildKeyTile(c, st, item)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _expiryChip(GVColors c, String label, int? days) {
    final on = _expiresInDays == days;
    return GVSpringTap(
      onTap: () => setState(() => _expiresInDays = days),
      pressedScale: 0.95,
      haptic: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: on ? c.acc : c.card2,
          borderRadius: BorderRadius.circular(GVRadius.pill),
          border: Border.all(color: on ? c.acc : c.line),
        ),
        child: Text(
          label,
          style: GVTxt.xs(
            c,
            weight: on ? FontWeight.w700 : FontWeight.w500,
            color: on ? c.ink : c.txt,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyTile(GVColors c, GoldVaultState st, ApiKeyItem item) {
    final statusLabel = item.isRevoked ? 'Revocada' : (item.isExpired ? 'Expirada' : 'Activa');
    final statusColor = item.isActive ? c.green : c.red;
    final expLabel = item.expiresAt != null
        ? 'Expira: ${item.expiresAt!.toIso8601String().substring(0, 10)}'
        : 'Sin expiración';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.card2,
        borderRadius: BorderRadius.circular(GVRadius.control),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: GVTxt.body(c, weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GVPillBadge(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 4),
          Text('${item.keyPrefix}•••••••• · $expLabel', style: GVTxt.xs(c)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GVPillButton(
                  label: 'Rotar',
                  variant: GVPillButtonVariant.secondary,
                  compact: true,
                  onPressed: _submitting ? null : () => _handleRotate(item),
                ),
              ),
              const SizedBox(width: 8),
              if (item.isActive)
                Expanded(
                  child: GVPillButton(
                    label: 'Revocar',
                    variant: GVPillButtonVariant.danger,
                    compact: true,
                    onPressed: _submitting ? null : () => st.revokeApiKey(item.id),
                  ),
                )
              else
                Expanded(
                  child: GVPillButton(
                    label: 'Eliminar',
                    variant: GVPillButtonVariant.danger,
                    compact: true,
                    onPressed: _submitting ? null : () => st.deleteApiKey(item.id),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
