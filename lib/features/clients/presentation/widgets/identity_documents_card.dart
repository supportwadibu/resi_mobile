import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'client_documents.title'.tr(),
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (client.idDocumentNumber case final number?
              when number.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [
                client.idDocumentType?.label,
                number,
              ].whereType<String>().join(' · '),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final source = url;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.58, // format ID-1 d'une carte d'identité
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: source == null || source.isEmpty
                ? _Placeholder(label: 'client_documents.missing'.tr())
                : GestureDetector(
                    onTap: () => _openFullScreen(context, source, label),
                    child: Image.network(
                      source,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                      errorBuilder: (_, _, _) => _Placeholder(
                        label: 'client_documents.unavailable'.tr(),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: text.labelMedium),
      ],
    );
  }

  static void _openFullScreen(BuildContext context, String url, String label) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(label),
          ),
          body: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(child: Image.network(url, fit: BoxFit.contain)),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge_outlined, color: scheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
