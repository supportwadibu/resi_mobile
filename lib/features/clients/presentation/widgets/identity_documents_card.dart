import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/image_viewer_utils.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

import '../../data/models/client_model.dart';

/// Les deux faces de la pièce d'identité du client, consultables en grand.
///
/// Les images viennent d'URLs signées à durée limitée, régénérées à chaque
/// lecture de la fiche. `Image.network` plutôt qu'un cache disque : une pièce
/// d'identité n'a pas à rester sur le téléphone, et l'URL expirée ne
/// resservirait de toute façon pas.
class IdentityDocumentsCard extends StatelessWidget {
  const IdentityDocumentsCard({required this.client, super.key});

  final ClientModel client;

  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'client_documents.title'.tr(),
      icon: LucideIcons.idCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (client.idDocumentNumber case final number?
              when number.isNotEmpty) ...[
            Text(
              [
                client.idDocumentType?.label,
                number,
              ].whereType<String>().join(' · '),
              style: context.mutedText,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _DocumentFace(
                  label: 'client_documents.front'.tr(),
                  url: client.documentFrontUrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DocumentFace(
                  label: 'client_documents.back'.tr(),
                  url: client.documentBackUrl,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentFace extends StatelessWidget {
  const _DocumentFace({required this.label, required this.url});

  final String label;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final source = url;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.58, // format ID-1 d'une carte d'identité
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(color: t.border),
              borderRadius: AppRadius.md,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.md,
              child: source == null || source.isEmpty
                  ? _Placeholder(label: 'client_documents.missing'.tr())
                  : InkWell(
                      onTap: () =>
                          ImageViewerUtils.showFullScreenImage(context, source),
                      child: Image.network(
                        source,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                            ? child
                            : ColoredBox(
                                color: t.background,
                                child: const Center(child: AppLoader(size: 24)),
                              ),
                        errorBuilder: (_, _, _) => _Placeholder(
                          label: 'client_documents.unavailable'.tr(),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: context.text.bodySmall),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ColoredBox(
      color: t.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.idCard, color: t.muted, size: 20),
            const SizedBox(height: 4),
            Text(label, style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}
