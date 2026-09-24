import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/config/app_config.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/utils/launcher_helper.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';

Future<void> showSupportContactSheet(
  BuildContext context, {
  String? visitorName,
  String? visitorEmail,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _SupportContactSheet(
      visitorName: visitorName,
      visitorEmail: visitorEmail,
    ),
  );
}

class _SupportContactSheet extends StatelessWidget {
  const _SupportContactSheet({this.visitorName, this.visitorEmail});

  final String? visitorName;
  final String? visitorEmail;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _SheetHeader(),
              const SizedBox(height: 20),

              if (AppConfig.isSupportChatEnabled) ...[
                _ChannelCard(
                  icon: FontAwesomeIcons.solidComments,
                  color: AppColors.gradientStart,
                  title: 'Chat en direct',
                  subtitle: 'Réponse immédiate, sans quitter l\'application',
                  highlighted: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.router.push(
                      SupportChatRoute(
                        visitorName: visitorName,
                        visitorEmail: visitorEmail,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              _ChannelCard(
                icon: FontAwesomeIcons.whatsapp,
                color: AppColors.textSecondary,
                title: 'WhatsApp',
                subtitle: _formatPhone(AppConfig.supportWhatsApp),
                onTap: () => _run(
                  context,
                  () => LauncherHelper.openWhatsApp(
                    AppConfig.supportWhatsApp,
                    message: _whatsAppGreeting(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ChannelCard(
                icon: FontAwesomeIcons.phone,
                color: AppColors.textSecondary,
                title: 'Appeler le support',
                subtitle:
                    '${_formatPhone(AppConfig.supportPhone)} · ${AppConfig.supportHours}',
                onTap: () => _run(
                  context,
                  () => LauncherHelper.makeCall('+${AppConfig.supportPhone}'),
                ),
              ),
              const SizedBox(height: 12),
              _ChannelCard(
                icon: FontAwesomeIcons.envelope,
                color: AppColors.textSecondary,
                title: 'Envoyer un e-mail',
                subtitle: AppConfig.supportEmail,
                onTap: () => _run(
                  context,
                  () => LauncherHelper.openUrl(
                    'mailto:${AppConfig.supportEmail}'
                    '?subject=${Uri.encodeComponent('Demande d\'assistance Resi')}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ChannelCard(
                icon: FontAwesomeIcons.globe,
                color: AppColors.textSecondary,
                title: 'Site web',
                subtitle: _formatWebsite(AppConfig.supportWebsite),
                onTap: () => _run(
                  context,
                  () => LauncherHelper.openUrl(AppConfig.supportWebsite),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _whatsAppGreeting() {
    final name = visitorName?.trim();
    if (name == null || name.isEmpty) {
      return 'Bonjour, j\'ai besoin d\'aide sur Resi.';
    }
    return 'Bonjour, je suis $name. J\'ai besoin d\'aide sur Resi.';
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    Navigator.of(context).pop();
    try {
      await action();
    } on LauncherException {
      // Sans `context` : la feuille est déjà refermée quand l'échec survient,
      // le toast se pose alors sur l'`Overlay` du routeur racine.
      AppToast.error('Aucune application disponible pour ce canal.');
    }
  }

  static String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (!digits.startsWith('225') || digits.length != 13) return '+$digits';

    final local = digits.substring(3);
    final pairs = <String>[
      for (var i = 0; i < local.length; i += 2) local.substring(i, i + 2),
    ];
    return '+225 ${pairs.join(' ')}';
  }

  static String _formatWebsite(String url) => url
      .replaceFirst(RegExp(r'^https?://'), '')
      .replaceFirst(RegExp(r'/$'), '');
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            size: 24,
            color: AppColors.white,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Besoin d\'aide ?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Choisissez comment nous joindre',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final FaIconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Marque le canal recommandé d'une bordure colorée, pour guider vers la
  /// voie la plus rapide sans masquer les autres.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: highlighted
              ? color.withValues(alpha: 0.04)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlighted
                ? color.withValues(alpha: 0.35)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: FaIcon(icon, size: 18, color: color)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.grey500),
          ],
        ),
      ),
    );
  }
}
