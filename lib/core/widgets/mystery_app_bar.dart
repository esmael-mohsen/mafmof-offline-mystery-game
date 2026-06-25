import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../../core/constants/app_media.dart';

class MysteryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MysteryAppBar({
    super.key,
    this.title,
    this.showLogo = false,
    this.showBackButton = false,
    this.showRedLine = true,
    this.actions,
    this.onBack,
  });

  final String? title;
  final bool showLogo;
  final bool showBackButton;
  final bool showRedLine;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.appBarBackground,
        border: showRedLine
            ? const Border(
                bottom: BorderSide(color: AppColors.appBarRedLine, width: 1.5),
              )
            : null,
      ),
      child: SafeArea(
        top: true,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                if (showBackButton)
                  GestureDetector(
                    onTap: onBack ?? () => Navigator.of(context).maybePop(),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.borderRadiusMd,
                        color: AppColors.elevatedSurface.withValues(alpha: 0.5),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                if (showBackButton) const SizedBox(width: AppSpacing.sm),
                if (showLogo)
                  Expanded(
                    child: Row(
                      children: [
                        Image.asset(
                          AppMedia.logoPath,
                          height: 32,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.games,
                            color: AppColors.crimson,
                            size: 28,
                          ),
                        ),
                        if (title != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              title!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                if (actions != null)
                  Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppLogoHeader extends StatelessWidget {
  const AppLogoHeader({
    super.key,
    this.subtitle,
    this.height = 120,
  });

  final String? subtitle;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppMedia.logoPath,
            height: 48,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.games,
              color: AppColors.crimson,
              size: 48,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
