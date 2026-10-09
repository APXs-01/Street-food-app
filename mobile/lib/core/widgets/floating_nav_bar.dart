import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class NavBarItem {
  const NavBarItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// The floating pill navigation shared by the consumer and vendor sides: the
/// active tab sits in a #00855d pill. The caller decides what each tab does.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.items, required this.currentIndex, required this.onTap});

  final List<NavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            boxShadow: const [BoxShadow(color: Color(0x1F0F172A), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(item: items[i], active: i == currentIndex, onTap: () => onTap(i)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.item, required this.active, required this.onTap});

  final NavBarItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 22, color: active ? AppColors.surface : AppColors.textMuted),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.2,
                  color: active ? AppColors.surface : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
