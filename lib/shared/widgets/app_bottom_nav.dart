import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.isMenuOpen,
    required this.onMenuToggle,
    super.key,
  });

  final int currentIndex;
  final void Function(int) onTap;

  final bool isMenuOpen;

  final void Function(bool) onMenuToggle;

  static const _items = [
    _NavItem(icon: FontAwesomeIcons.house, label: 'Accueil'),
    _NavItem(icon: FontAwesomeIcons.book, label: 'Réservations'),
    _NavItem(icon: FontAwesomeIcons.building, label: 'Biens'),
    _NavItem(icon: FontAwesomeIcons.chartColumn, label: 'Stats'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        _items.length,
                        (i) => _NavButton(
                          item: _items[i],
                          isActive: currentIndex == i,
                          onTap: () => onTap(i),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Bouton Add
          GestureDetector(
            onTap: () => onMenuToggle(!isMenuOpen),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isMenuOpen
                          ? AppColors.primary.withOpacity(0.9)
                          : Colors.white.withOpacity(0.65),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: AnimatedRotation(
                      turns: isMenuOpen ? 0.125 : 0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        Icons.add,
                        color: isMenuOpen ? Colors.white : AppColors.black,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final FaIconData icon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.black : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: FaIcon(
          item.icon,
          size: 20,
          color: isActive ? AppColors.white : Colors.black87,
        ),
      ),
    );
  }
}
