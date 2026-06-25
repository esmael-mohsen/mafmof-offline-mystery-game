import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../../core/performance/performance_monitor.dart';
import '../../features/game/presentation/cubit/game_cubit.dart';
import '../../features/game/presentation/screens/case_details_screen.dart';
import '../../features/game/presentation/screens/final_reveal_screen.dart';
import '../../features/game/presentation/screens/home_screen.dart';
import '../../features/game/presentation/screens/host_dashboard_screen.dart';
import '../../features/game/presentation/screens/host_checklist_screen.dart';
import '../../features/game/presentation/screens/invalid_placeholder_screen.dart';
import '../../features/game/presentation/screens/role_reveal_screen.dart';
import '../../features/game/presentation/screens/setup_screen.dart';
import '../../features/game/presentation/screens/stage_screen.dart';
import '../../features/game/presentation/screens/voting_screen.dart';
import 'app_routes.dart';

@lazySingleton
class AppRouter {
  AppRouter();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home.path,
    routes: [
      GoRoute(
        name: AppRoutes.home.name,
        path: AppRoutes.home.path,
        pageBuilder: (context, state) => _buildFadeTransitionPage(
          child: const HomeScreen(),
          state: state,
        ),
      ),
      GoRoute(
        name: AppRoutes.caseDetails.name,
        path: AppRoutes.caseDetails.path,
        pageBuilder: (context, state) {
          final caseId = state.pathParameters['caseId'];
          if (_isBlank(caseId)) {
            return _buildFadeTransitionPage(
              child: const InvalidPlaceholderScreen(),
              state: state,
            );
          }
          return _buildFadeTransitionPage(
            child: CaseDetailsScreen(caseId: caseId!),
            state: state,
          );
        },
        routes: [
          GoRoute(
            name: AppRoutes.setupGame.name,
            path: 'setup',
            pageBuilder: (context, state) {
              final caseId = state.pathParameters['caseId'];
              if (_isBlank(caseId)) {
                return _buildFadeTransitionPage(
                  child: const InvalidPlaceholderScreen(),
                  state: state,
                );
              }
              return _buildSlideTransitionPage(
                child: SetupScreen(caseId: caseId!),
                state: state,
              );
            },
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.roleReveal.name,
        path: AppRoutes.roleReveal.path,
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId'];
          if (_isBlank(sessionId) ||
              !context.read<GameCubit>().canAccessRoleReveal(sessionId!)) {
            return _buildFadeTransitionPage(
              child: const InvalidPlaceholderScreen(),
              state: state,
            );
          }
          return _buildSlideTransitionPage(
            child: RoleRevealScreen(sessionId: sessionId),
            state: state,
          );
        },
      ),
      GoRoute(
        name: AppRoutes.hostDashboard.name,
        path: AppRoutes.hostDashboard.path,
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId'];
          if (_isBlank(sessionId) ||
              !context.read<GameCubit>().canAccessDashboard(sessionId!)) {
            return _buildFadeTransitionPage(
              child: const InvalidPlaceholderScreen(),
              state: state,
            );
          }
          return _buildFadeTransitionPage(
            child: HostDashboardScreen(sessionId: sessionId),
            state: state,
          );
        },
      ),
      GoRoute(
        name: AppRoutes.stage.name,
        path: AppRoutes.stage.path,
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId'];
          final stageNumber = int.tryParse(
            state.pathParameters['stageNumber'] ?? '',
          );
          if (_isBlank(sessionId) ||
              stageNumber == null ||
              !context
                  .read<GameCubit>()
                  .canAccessStage(sessionId!, stageNumber)) {
            return _buildFadeTransitionPage(
              child: const InvalidPlaceholderScreen(),
              state: state,
            );
          }
          return _buildSlideTransitionPage(
            child: StageScreen(sessionId: sessionId, stageNumber: stageNumber),
            state: state,
          );
        },
      ),
      GoRoute(
        name: AppRoutes.voting.name,
        path: AppRoutes.voting.path,
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId'];
          final stageNumber = int.tryParse(
            state.pathParameters['stageNumber'] ?? '',
          );
          if (_isBlank(sessionId) ||
              stageNumber == null ||
              !context
                  .read<GameCubit>()
                  .canAccessVoting(sessionId!, stageNumber)) {
            return _buildFadeTransitionPage(
              child: const InvalidPlaceholderScreen(),
              state: state,
            );
          }
          return _buildSlideTransitionPage(
            child: VotingScreen(sessionId: sessionId, stageNumber: stageNumber),
            state: state,
          );
        },
      ),
      GoRoute(
        name: AppRoutes.finalReveal.name,
        path: AppRoutes.finalReveal.path,
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId'];
          if (_isBlank(sessionId) ||
              !context.read<GameCubit>().canAccessFinalReveal(sessionId!)) {
            return _buildFadeTransitionPage(
              child: const InvalidPlaceholderScreen(),
              state: state,
            );
          }
          return _buildSlideTransitionPage(
            child: FinalRevealScreen(sessionId: sessionId),
            state: state,
          );
        },
      ),
      GoRoute(
        name: AppRoutes.hostChecklist.name,
        path: AppRoutes.hostChecklist.path,
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId'];
          if (_isBlank(sessionId)) {
            return _buildFadeTransitionPage(
              child: const InvalidPlaceholderScreen(),
              state: state,
            );
          }
          return _buildFadeTransitionPage(
            child: HostChecklistScreen(sessionId: sessionId!),
            state: state,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => const InvalidPlaceholderScreen(),
  );

  CustomTransitionPage _buildFadeTransitionPage({
    required Widget child,
    required GoRouterState state,
  }) {
    _markRoute(state);
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  CustomTransitionPage _buildSlideTransitionPage({
    required Widget child,
    required GoRouterState state,
  }) {
    _markRoute(state);
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(slideAnimation),
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  void _markRoute(GoRouterState state) {
    PerformanceMonitor.instance.markRoute(
      state.name ?? state.fullPath ?? state.uri.path,
    );
  }
}
