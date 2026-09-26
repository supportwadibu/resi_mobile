import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

@RoutePage()
class SuccessScreen extends StatefulWidget {
  const SuccessScreen({
    super.key,
    this.title = 'Félicitations !',
    this.subtitle = 'Votre bien a été enregistré avec succès',
    this.buttonText = 'Voir mes biens',
    this.secondaryButtonText = 'Ajouter un autre bien',
    this.autoRedirectDuration = 5,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  final String title;
  final String subtitle;
  final String buttonText;
  final String secondaryButtonText;
  final int autoRedirectDuration;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  /// Une seule entrée, fondu et léger glissement, sans rebond : l'écran
  /// confirme une action, il n'a pas à la célébrer.
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(_fade);

  /// Le décompte et le bouton mènent à la même sortie : sans ce garde, les
  /// deux pourraient se déclencher et dépiler deux écrans.
  bool _hasLeft = false;

  /// Quitte l'écran, une seule fois.
  void _leave() {
    if (_hasLeft || !mounted) return;
    _hasLeft = true;

    final action = widget.onPrimaryAction;
    if (action != null) {
      action();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Sortie par l'action secondaire, soumise au même garde.
  void _leaveSecondary() {
    if (_hasLeft || !mounted) return;
    _hasLeft = true;

    final action = widget.onSecondaryAction;
    if (action != null) {
      action();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: IconChip(
                        icon: LucideIcons.circleCheck,
                        accent: AppAccent.green,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.title,
                      style: context.text.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      style: context.mutedText.copyWith(height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: widget.buttonText,
                      trailingIcon: LucideIcons.arrowRight,
                      expand: true,
                      onPressed: _leave,
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: widget.secondaryButtonText,
                      icon: LucideIcons.plus,
                      variant: AppButtonVariant.secondary,
                      expand: true,
                      onPressed: _leaveSecondary,
                    ),
                    const SizedBox(height: 24),
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: widget.autoRedirectDuration.toDouble(),
                        end: 0,
                      ),
                      duration: Duration(seconds: widget.autoRedirectDuration),
                      builder: (context, value, child) => Text(
                        'Redirection automatique dans ${value.ceil()} s',
                        textAlign: TextAlign.center,
                        style: context.text.bodySmall,
                      ),
                      onEnd: _leave,
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
