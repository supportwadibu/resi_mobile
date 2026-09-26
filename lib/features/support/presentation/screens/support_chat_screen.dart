import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../core/config/app_config.dart';

/// Chat d'assistance Tawk.to, affiché dans l'application.
///
/// Le widget est chargé dans une vue web plutôt qu'ouvert dans le navigateur :
/// l'utilisateur ne quitte pas Resi, et le visiteur peut être identifié —
/// sans quoi chaque conversation arriverait anonyme côté support.
@RoutePage()
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key, this.visitorName, this.visitorEmail});

  /// Identité transmise au support. Les deux champs sont facultatifs : un
  /// dossier propriétaire incomplet ne doit pas empêcher de demander de l'aide.
  final String? visitorName;
  final String? visitorEmail;

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  InAppWebViewController? _controller;

  bool _isLoading = true;
  bool _hasFailed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Aide & support'),
      body: SafeArea(child: _hasFailed ? _errorView() : _chatView()),
    );
  }

  Widget _chatView() {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(AppConfig.tawkChatUrl)),
          initialSettings: InAppWebViewSettings(
            // Le widget Tawk.to est une page JavaScript : sans cela, l'écran
            // resterait blanc.
            javaScriptEnabled: true,
            // Le dépôt d'une pièce jointe passe par un input fichier.
            allowFileAccess: true,
            transparentBackground: true,
          ),
          onWebViewCreated: (controller) => _controller = controller,
          onLoadStop: (controller, url) async {
            await _identifyVisitor(controller);
            if (mounted) setState(() => _isLoading = false);
          },
          onReceivedError: (controller, request, error) {
            // Seule l'échec du document principal condamne l'écran : une
            // ressource secondaire manquante laisse le chat utilisable.
            if (request.isForMainFrame != true) return;
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasFailed = true;
              });
            }
          },
        ),

        if (_isLoading)
          ColoredBox(
            color: context.tokens.background,
            child: const Center(child: AppLoader()),
          ),
      ],
    );
  }

  /// Renseigne le visiteur auprès de Tawk.to.
  ///
  /// L'API `setAttributes` n'existe qu'une fois le widget initialisé, d'où
  /// l'appel après le chargement. Les valeurs sont injectées via `JSON.stringify`
  /// afin qu'un nom contenant une apostrophe — courant — ne casse pas le script.
  Future<void> _identifyVisitor(InAppWebViewController controller) async {
    final name = widget.visitorName?.trim();
    final email = widget.visitorEmail?.trim();

    if ((name == null || name.isEmpty) && (email == null || email.isEmpty)) {
      return;
    }

    final attributes = <String, String>{
      if (name != null && name.isNotEmpty) 'name': name,
      if (email != null && email.isNotEmpty) 'email': email,
    };

    final payload = attributes.entries
        .map((e) => '${_jsString(e.key)}: ${_jsString(e.value)}')
        .join(', ');

    await controller.evaluateJavascript(
      source:
          '''
      (function () {
        if (window.Tawk_API && typeof window.Tawk_API.setAttributes === 'function') {
          window.Tawk_API.setAttributes({ $payload }, function () {});
        }
      })();
      ''',
    );
  }

  /// Échappe une valeur pour l'insérer sans risque dans du JavaScript.
  static String _jsString(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n');
    return '"$escaped"';
  }

  Widget _errorView() {
    return ErrorState(
      message: 'Le support est injoignable. Vérifiez votre connexion, puis '
          'réessayez.',
      onRetry: () {
        setState(() {
          _hasFailed = false;
          _isLoading = true;
        });
        _controller?.loadUrl(
          urlRequest: URLRequest(url: WebUri(AppConfig.tawkChatUrl)),
        );
      },
    );
  }
}
