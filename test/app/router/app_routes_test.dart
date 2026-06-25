import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/app/router/app_routes.dart';

void main() {
  test('defines all Phase 1 skeleton route names and path shapes', () {
    expect(AppRoutes.home.name, 'home');
    expect(AppRoutes.home.path, '/');
    expect(AppRoutes.caseDetails.path, '/case/:caseId');
    expect(AppRoutes.setupGame.path, '/case/:caseId/setup');
    expect(AppRoutes.roleReveal.path, '/game/:sessionId/reveal');
    expect(AppRoutes.hostDashboard.path, '/game/:sessionId/dashboard');
    expect(AppRoutes.stage.path, '/game/:sessionId/stage/:stageNumber');
    expect(AppRoutes.voting.path, '/game/:sessionId/voting/:stageNumber');
    expect(AppRoutes.finalReveal.path, '/game/:sessionId/final');
  });
}
