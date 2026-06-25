class AppRouteInfo {
  const AppRouteInfo({required this.name, required this.path});

  final String name;
  final String path;
}

class AppRoutes {
  const AppRoutes._();

  static const home = AppRouteInfo(name: 'home', path: '/');
  static const caseDetails = AppRouteInfo(
    name: 'caseDetails',
    path: '/case/:caseId',
  );
  static const setupGame = AppRouteInfo(
    name: 'setupGame',
    path: '/case/:caseId/setup',
  );
  static const roleReveal = AppRouteInfo(
    name: 'roleReveal',
    path: '/game/:sessionId/reveal',
  );
  static const hostDashboard = AppRouteInfo(
    name: 'hostDashboard',
    path: '/game/:sessionId/dashboard',
  );
  static const stage = AppRouteInfo(
    name: 'stage',
    path: '/game/:sessionId/stage/:stageNumber',
  );
  static const voting = AppRouteInfo(
    name: 'voting',
    path: '/game/:sessionId/voting/:stageNumber',
  );
  static const finalReveal = AppRouteInfo(
    name: 'finalReveal',
    path: '/game/:sessionId/final',
  );
  static const hostChecklist = AppRouteInfo(
    name: 'hostChecklist',
    path: '/game/:sessionId/checklist',
  );
}
