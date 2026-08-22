import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

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
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

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
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icône de succès avec animation
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.1),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Cercles d'ondes
                            ...List.generate(3, (index) {
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(
                                  milliseconds: 1500 + (index * 300),
                                ),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: (1 - value) * 0.3,
                                    child: Container(
                                      width: 80 + (value * 40),
                                      height: 80 + (value * 40),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primary,
                                          width: 2 - value,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                            // Icône check
                            const FaIcon(
                              FontAwesomeIcons.circleCheck,
                              size: 50,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Titre avec animation
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sous-titre
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 1.5),
                        child: Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.grey500,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Bouton principal
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 2),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _leave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              widget.buttonText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bouton secondaire
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 2.5),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _leaveSecondary,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.black,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              side: const BorderSide(color: AppColors.grey200),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.secondaryButtonText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Compteur de redirection automatique
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: widget.autoRedirectDuration.toDouble(),
                          end: 0,
                        ),
                        duration: Duration(
                          seconds: widget.autoRedirectDuration,
                        ),
                        builder: (context, value, child) {
                          return Text(
                            'Redirection automatique dans ${value.ceil()}s',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.grey400,
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        },
                        onEnd: _leave,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
