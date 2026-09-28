import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mentor_client/app.dart';
import 'package:mentor_client/models/app_tab.dart';
import 'package:mentor_client/routing/app_router.dart';
import 'package:mentor_client/ui/tasks/views/tasks_screen.dart';
import 'package:mentor_client/ui/journal/views/journal_screen.dart';
import 'package:mentor_client/ui/more/views/more_screen.dart';
import 'package:mentor_client/ui/main/views/main_screen.dart';
import 'package:mentor_client/ui/today/views/today_screen.dart';
import 'package:mentor_client/ui/levels/views/levels_screen.dart';
import 'support/test_repository.dart';

void main() {
  testWidgets('starts on Today with all five destinations', (tester) async {
    final repository = testRepository();
    addTearDown(repository.api.close);
    await tester.pumpWidget(MentorApp(levelsRepository: repository));
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    expect(
      tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .map((destination) => destination.label),
      ['Today', 'Levels', 'Tasks', 'Journal', 'More'],
    );
    final router = GoRouter.of(tester.element(find.byType(MainScreen)));
    expect(router.routeInformationProvider.value.uri.path, '/today');
  });

  testWidgets('tab taps update both content and route on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = testRepository();
    addTearDown(repository.api.close);
    await tester.pumpWidget(MentorApp(levelsRepository: repository));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(MainScreen)));
    final todayElement = tester.element(find.byType(TodayScreen));

    for (final tab in [...AppTab.values.skip(1), AppTab.today]) {
      await tester.tap(find.byKey(ValueKey(tab)));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, tab.path);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        tab.index,
      );
      expect(
        find.byType(switch (tab) {
          AppTab.today => TodayScreen,
          AppTab.levels => LevelsScreen,
          AppTab.tasks => TasksScreen,
          AppTab.journal => JournalScreen,
          AppTab.more => MoreScreen,
        }),
        findsOneWidget,
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    // Switching away and back keeps the original branch mounted.
    expect(tester.element(find.byType(TodayScreen)), same(todayElement));
  });

  for (final tab in AppTab.values) {
    testWidgets('direct ${tab.path} route selects the matching tab', (
      tester,
    ) async {
      final repository = testRepository();
      addTearDown(repository.api.close);
      final router = createAppRouter(
        initialLocation: tab.path,
        levelsRepository: repository,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        tab.index,
      );
      expect(
        find.byType(switch (tab) {
          AppTab.today => TodayScreen,
          AppTab.levels => LevelsScreen,
          AppTab.tasks => TasksScreen,
          AppTab.journal => JournalScreen,
          AppTab.more => MoreScreen,
        }),
        findsOneWidget,
      );
      // Re-selecting the active destination keeps the current route.
      await tester.tap(find.byKey(ValueKey(tab)));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, tab.path);

      router.go('/tasks');
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        AppTab.tasks.index,
      );
    });
  }
}
