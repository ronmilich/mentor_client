import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/app_tab.dart';
import '../ui/journal/views/journal_screen.dart';
import '../ui/levels/views/levels_screen.dart';
import '../ui/main/view_models/main_view_model.dart';
import '../ui/main/views/main_screen.dart';
import '../ui/more/views/more_screen.dart';
import '../ui/tasks/views/tasks_screen.dart';
import '../ui/today/views/today_screen.dart';
import '../data/repositories/levels_repository.dart';
import 'levels_routes.dart';

GoRouter createAppRouter({
  String initialLocation = '/',
  required LevelsRepository levelsRepository,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppTab.today.path),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainScreen(
          viewModel: MainViewModel(
            selectedIndex: navigationShell.currentIndex,
            onSelectTab: (index) => navigationShell.goBranch(index),
          ),
          child: navigationShell,
        ),
        branches: [
          for (final tab in AppTab.values)
            StatefulShellBranch(
              routes: [
                if (tab == AppTab.levels)
                  levelsRoute(levelsRepository)
                else
                  GoRoute(
                    path: tab.path,
                    name: tab.name,
                    builder: (context, state) =>
                        _screenFor(tab, levelsRepository),
                  ),
              ],
            ),
        ],
      ),
    ],
  );
}

Widget _screenFor(AppTab tab, LevelsRepository repository) => switch (tab) {
  AppTab.today => const TodayScreen(),
  AppTab.levels => LevelsScreen(repository: repository),
  AppTab.tasks => const TasksScreen(),
  AppTab.journal => const JournalScreen(),
  AppTab.more => const MoreScreen(),
};
