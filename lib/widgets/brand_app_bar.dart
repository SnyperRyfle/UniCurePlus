import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The "UniCurePlus" top brand bar seen on most screens.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onBack;

  const BrandAppBar({super.key, this.showBack = false, this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brandPurple,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 14, color: AppColors.brandGold),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text('UniCurePlus'),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            ThemeController.instance.isDark
                ? Icons.light_mode
                : Icons.dark_mode,
            size: 20,
          ),
          tooltip: ThemeController.instance.isDark
              ? 'Gunakan mod terang'
              : 'Gunakan mod gelap',
          onPressed: ThemeController.instance.toggleTheme,
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(
          Icons.notifications_none,
          size: 20,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.grey300
              : AppColors.grey700,
        ),
        const SizedBox(width: AppSpacing.lg),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(2),
        child: SizedBox(
          height: 2,
          child: ColoredBox(color: AppColors.brandGold),
        ),
      ),
    );
  }
}
