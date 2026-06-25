import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/game_session_entity.dart';
import '../../domain/entities/session_player_entity.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';

class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen>
    with WidgetsBindingObserver {
  late final GameCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<GameCubit>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _cubit.handleAppLifecycleChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          final session = state.activeSession;
          final player = session?.currentPlayer;

          if (session == null || player == null) {
            return _InvalidRoleRevealState(
              onReturnHome: () => context.goNamed(AppRoutes.home.name),
            );
          }

          final playerNumber = session.revealIndex + 1;
          final isLastPlayer = playerNumber == session.players.length;

          return Stack(
            children: [
              _RoleRevealBackdrop(player: player),
              ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  MediaQuery.of(context).padding.top + 76,
                  AppSpacing.lg,
                  132,
                ),
                children: [
                  _RoleDossierCard(
                    key: ValueKey(player.playerId),
                    session: session,
                    player: player,
                    playerNumber: playerNumber,
                    isRevealed: state.isCurrentRoleVisible,
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _RevealErrorBanner(message: state.errorMessage!),
                  ],
                ],
              ),
              const _RevealAppBar(),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _RoleRevealActionBar(
                  isRoleVisible: state.isCurrentRoleVisible,
                  isLastPlayer: isLastPlayer,
                  canGoBack: session.revealIndex > 0,
                  onReveal: () => _cubit.revealCurrentRole(),
                  onHide: () => _cubit.hideCurrentRole(),
                  onBack: () => _cubit.previousRoleReveal(),
                  onContinue: () => _continue(context, isLastPlayer),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _continue(BuildContext context, bool isLastPlayer) async {
    final completed = await _cubit.advanceRoleReveal();
    if (!context.mounted || !completed) {
      return;
    }

    context.goNamed(
      AppRoutes.hostDashboard.name,
      pathParameters: {'sessionId': widget.sessionId},
    );
  }
}

class _RoleRevealBackdrop extends StatelessWidget {
  final SessionPlayerEntity player;

  const _RoleRevealBackdrop({required this.player});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            image: DecorationImage(
              image: AssetImage(player.portraitAssetPath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: const SizedBox.expand(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF070709).withValues(alpha: 0.72),
                AppColors.deepCrimson.withValues(alpha: 0.38),
                const Color(0xFF070709),
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _RevealAppBar extends StatelessWidget {
  const _RevealAppBar();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: Row(
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Material(
                color: const Color(0xFF070709).withValues(alpha: 0.42),
                shape: CircleBorder(
                  side: BorderSide(
                    color: AppColors.crimson.withValues(alpha: 0.24),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    context.goNamed(AppRoutes.home.name);
                  },
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SizedBox(
              height: 46,
              child: Center(
                child: Text(
                  AppText.roleRevealTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.red.shade900.withValues(alpha: 0.68),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 46 + AppSpacing.sm),
        ],
      ),
    );
  }
}

class _RevealProgressDots extends StatelessWidget {
  final int total;
  final int currentIndex;

  const _RevealProgressDots({required this.total, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < total; index += 1) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: index == currentIndex ? 28 : 10,
            height: 6,
            decoration: BoxDecoration(
              color: index <= currentIndex
                  ? AppColors.crimson
                  : Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
              boxShadow: index == currentIndex
                  ? [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.34),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
          ),
          if (index != total - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _RoleDossierCard extends StatelessWidget {
  final GameSessionEntity session;
  final SessionPlayerEntity player;
  final int playerNumber;
  final bool isRevealed;

  const _RoleDossierCard({
    super.key,
    required this.session,
    required this.player,
    required this.playerNumber,
    required this.isRevealed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: const Color(0xFF070709).withValues(alpha: 0.68),
        border: Border.all(
          color: AppColors.crimson.withValues(alpha: isRevealed ? 0.58 : 0.3),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.62),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
          if (isRevealed)
            BoxShadow(
              color: AppColors.crimson.withValues(alpha: 0.2),
              blurRadius: 34,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: isRevealed
                ? _RevealedRoleFace(
                    key: const ValueKey('revealed'),
                    session: session,
                    player: player,
                    playerNumber: playerNumber,
                  )
                : _SealedRolePhotoFace(
                    key: const ValueKey('sealed'),
                    session: session,
                    player: player,
                    playerNumber: playerNumber,
                  ),
          ),
        ),
      ),
    );
  }
}

class _RevealIdentityBlock extends StatelessWidget {
  final GameSessionEntity session;
  final SessionPlayerEntity player;
  final int playerNumber;

  const _RevealIdentityBlock({
    required this.session,
    required this.player,
    required this.playerNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            player.displayName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heroSignatureTitle(context).copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: Colors.red.shade900.withValues(alpha: 0.66),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppText.currentPlayerLabel} $playerNumber/${session.players.length}',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: Colors.white70, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          _RevealProgressDots(
            total: session.players.length,
            currentIndex: session.revealIndex,
          ),
        ],
      ),
    );
  }
}

class _SealedRolePhotoFace extends StatelessWidget {
  final GameSessionEntity session;
  final SessionPlayerEntity player;
  final int playerNumber;

  const _SealedRolePhotoFace({
    super.key,
    required this.session,
    required this.player,
    required this.playerNumber,
  });

  @override
  Widget build(BuildContext context) {
    final cardHeight =
        MediaQuery.of(context).size.height.clamp(560.0, 820.0) * 0.58;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: SizedBox(
        height: cardHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                player.portraitAssetPath,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.cardDark),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF070709).withValues(alpha: 0.96),
                      const Color(0xFF070709).withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.44, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.displayName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heroSignatureTitle(context).copyWith(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: Colors.red.shade900.withValues(alpha: 0.74),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppText.currentPlayerLabel} $playerNumber/${session.players.length}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _RevealProgressDots(
                      total: session.players.length,
                      currentIndex: session.revealIndex,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _SealedRoleFace extends StatelessWidget {
  final GameSessionEntity session;
  final SessionPlayerEntity player;
  final int playerNumber;

  const _SealedRoleFace({
    required this.session,
    required this.player,
    required this.playerNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RevealIdentityBlock(
            session: session,
            player: player,
            playerNumber: playerNumber,
          ),
          const SizedBox(height: AppSpacing.md),
          _ClassifiedStrip(label: 'CLASSIFIED ROLE'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height:
                MediaQuery.of(context).size.height.clamp(620.0, 860.0) * 0.34,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    player.portraitAssetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.cardDark),
                  ),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 78,
                    height: 78,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.deepCrimson.withValues(alpha: 0.82),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.crimson.withValues(alpha: 0.32),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _PrivacyChip(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'سلّم الجهاز للاعب فقط',
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionAmiriTitle(context).copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppText.roleRevealInstruction,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary(
              context,
            ).copyWith(color: Colors.white70, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RevealedRoleFace extends StatelessWidget {
  final GameSessionEntity session;
  final SessionPlayerEntity player;
  final int playerNumber;

  const _RevealedRoleFace({
    super.key,
    required this.session,
    required this.player,
    required this.playerNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RevealIdentityBlock(
            session: session,
            player: player,
            playerNumber: playerNumber,
          ),
          const SizedBox(height: AppSpacing.md),
          _ClassifiedStrip(label: 'ROLE UNSEALED'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  player.portraitAssetPath,
                  width: 96,
                  height: 118,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 96,
                    height: 118,
                    color: AppColors.cardDark,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.characterName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((player.characterTitle ?? '').trim().isNotEmpty)
                      Text(
                        player.characterTitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          color: Colors.white60,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _RoleInfoTile(
            label: AppText.roleLabel,
            value: player.localizedRoleName,
          ),
          _RoleInfoTile(
            label: AppText.teamLabel,
            value: player.localizedTeamName,
          ),
          if (player.mafiaIntelLine(session.players) != null)
            _RoleInfoTile(
              label: 'معلومات فريق المافيا',
              value: player.mafiaIntelLine(session.players)!,
            ),
          _RoleInfoTile(
            label: AppText.publicInfoLabel,
            value: player.publicInfo,
          ),
          for (final section in player.privateSections)
            _RoleInfoTile(
              label: _sectionLabel(section.key),
              value: section.value,
            ),
        ],
      ),
    );
  }

  String _sectionLabel(String key) {
    switch (key) {
      case 'secret':
        return AppText.secretLabel;
      case 'secretMeaning':
        return AppText.secretMeaningLabel;
      case 'goal':
        return AppText.goalLabel;
      case 'tasks':
        return AppText.tasksLabel;
      case 'specialAbility':
        return AppText.specialAbilityLabel;
      case 'mustNotSay':
        return AppText.mustNotSayLabel;
      default:
        return key;
    }
  }
}

class _PrivacyChip extends StatelessWidget {
  const _PrivacyChip();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          border: Border.all(color: AppColors.crimson.withValues(alpha: 0.32)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.privacy_tip_rounded,
              color: AppColors.crimson,
              size: 16,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'تأكد إن اللاعب ماسك الجهاز لوحده',
                style: AppTextStyles.caption(context).copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _RoleInfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: AppColors.crimson, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyPrimary(context).copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassifiedStrip extends StatelessWidget {
  final String label;

  const _ClassifiedStrip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.deepCrimson.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleRevealActionBar extends StatelessWidget {
  final bool isRoleVisible;
  final bool isLastPlayer;
  final bool canGoBack;
  final VoidCallback onReveal;
  final VoidCallback onHide;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _RoleRevealActionBar({
    required this.isRoleVisible,
    required this.isLastPlayer,
    required this.canGoBack,
    required this.onReveal,
    required this.onHide,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF070709).withValues(alpha: 0.88),
            const Color(0xFF070709),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RevealPrimaryButton(
              label: isRoleVisible
                  ? AppText.hideRoleAction
                  : AppText.revealRoleAction,
              icon: isRoleVisible
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              isPrimary: true,
              onPressed: isRoleVisible ? onHide : onReveal,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              textDirection: TextDirection.ltr,
              children: [
                if (canGoBack) ...[
                  _RevealSquareButton(
                    icon: Icons.arrow_forward_rounded,
                    onPressed: isRoleVisible ? null : onBack,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  flex: 3,
                  child: _RevealPrimaryButton(
                    label: isLastPlayer
                        ? AppText.finishRoleRevealAction
                        : AppText.nextPlayerAction,
                    icon: isLastPlayer
                        ? Icons.dashboard_customize_rounded
                        : Icons.arrow_back_rounded,
                    isPrimary: false,
                    onPressed: isRoleVisible ? null : onContinue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealSquareButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _RevealSquareButton({required this.icon, required this.onPressed});

  @override
  State<_RevealSquareButton> createState() => _RevealSquareButtonState();
}

class _RevealSquareButtonState extends State<_RevealSquareButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 140),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFF151012) : AppColors.disabled,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.18 : 0.08),
            ),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _RevealPrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _RevealPrimaryButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_RevealPrimaryButton> createState() => _RevealPrimaryButtonState();
}

class _RevealPrimaryButtonState extends State<_RevealPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 54,
          decoration: BoxDecoration(
            color: !enabled
                ? AppColors.disabled
                : widget.isPrimary
                ? AppColors.deepCrimson
                : const Color(0xFF151012),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.18 : 0.08),
            ),
            boxShadow: enabled && widget.isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.crimson.withValues(
                        alpha: _isPressed ? 0.42 : 0.28,
                      ),
                      blurRadius: _isPressed ? 28 : 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: AppTextStyles.buttonLabel(context).copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevealErrorBanner extends StatelessWidget {
  final String message;

  const _RevealErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.deepCrimson.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.38)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySecondary(context).copyWith(
          color: Colors.white.withValues(alpha: 0.82),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InvalidRoleRevealState extends StatelessWidget {
  final VoidCallback onReturnHome;

  const _InvalidRoleRevealState({required this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepCrimson.withValues(alpha: 0.22),
            const Color(0xFF070709),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.crimson,
                size: 46,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppText.sessionFailClosedMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyPrimary(
                  context,
                ).copyWith(color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.lg),
              _RevealPrimaryButton(
                label: AppText.returnHome,
                icon: Icons.home_rounded,
                isPrimary: true,
                onPressed: onReturnHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
