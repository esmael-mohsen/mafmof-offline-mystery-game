import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/game_session_entity.dart';
import '../../domain/entities/session_player_entity.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';

class HostHintOverlay extends StatelessWidget {
  const HostHintOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (previous, current) =>
          previous.activeSession != current.activeSession,
      builder: (context, state) {
        final session = state.activeSession;
        final canShowHints = session != null &&
            session.roleRevealComplete &&
            !session.isCompleted &&
            session.players.any(_canAskForHint);

        return Stack(
          children: [
            child,
            if (canShowHints)
              PositionedDirectional(
                end: 14,
                bottom: 88,
                child: SafeArea(
                  child: _HostHintButton(
                    onPressed: () => _openHintSheet(session),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static bool _canAskForHint(SessionPlayerEntity player) {
    return player.localizedRoleName == 'المحقق' ||
        (player.specialAbility ?? '').toLowerCase().contains('hint');
  }

  void _openHintSheet(GameSessionEntity session) {
    final navigatorContext = AppRouter.rootNavigatorKey.currentContext;
    if (navigatorContext == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: navigatorContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.62,
            minChildSize: 0.36,
            maxChildSize: 0.86,
            builder: (context, scrollController) {
              return _HostHintSheetContent(
                session: session,
                scrollController: scrollController,
              );
            },
          ),
        );
      },
    );
  }
}

class _HostHintButton extends StatelessWidget {
  const _HostHintButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'هنت المحقق',
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.deepCrimson,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.crimson.withValues(alpha: 0.34),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const SizedBox.square(
            dimension: 44,
            child: Icon(
              Icons.psychology_alt_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

class _HostHintSheetContent extends StatelessWidget {
  const _HostHintSheetContent({
    required this.session,
    required this.scrollController,
  });

  final GameSessionEntity session;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D090B),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.crimson.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'هنت خاص للمحقق',
              textAlign: TextAlign.right,
              style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'اختار اسم اللاعب المطلوب. اقرأ الهنت للمحقق فقط بدون كشف الدور.',
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: session.players.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final player = session.players[index];
                  return _HintTargetTile(
                    player: player,
                    onTap: () => _showHint(player),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHint(SessionPlayerEntity player) {
    final navigatorContext = AppRouter.rootNavigatorKey.currentContext;
    if (navigatorContext == null) {
      return;
    }

    showDialog<void>(
      context: navigatorContext,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF111015),
            title: Text('هنت: ${player.displayName}'),
            content: Text(
              _hintFor(player),
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyPrimary(dialogContext).copyWith(
                color: Colors.white,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('تم'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _hintFor(SessionPlayerEntity player) {
    final secretMeaning = player.secretMeaning?.trim();
    if (secretMeaning != null && secretMeaning.isNotEmpty) {
      return secretMeaning;
    }
    final secret = player.secret?.trim();
    if (secret != null && secret.isNotEmpty) {
      return secret;
    }
    return 'لا يوجد هنت خاص لهذا اللاعب في بيانات القضية.';
  }
}

class _HintTargetTile extends StatelessWidget {
  const _HintTargetTile({required this.player, required this.onTap});

  final SessionPlayerEntity player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        onTap: onTap,
        leading: ClipOval(
          child: Image.asset(
            player.portraitAssetPath,
            width: 42,
            height: 42,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 42,
              height: 42,
              color: AppColors.cardDark,
            ),
          ),
        ),
        title: Text(
          player.displayName,
          textAlign: TextAlign.right,
          style: AppTextStyles.cardTitle(context).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          player.characterName,
          textAlign: TextAlign.right,
          style: AppTextStyles.caption(context).copyWith(color: Colors.white60),
        ),
        trailing: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
      ),
    );
  }
}
