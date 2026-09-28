import 'package:go_router/go_router.dart';

import '../data/repositories/levels_repository.dart';
import '../ui/levels/views/levels_screen.dart';
import '../ui/levels/views/level_detail_screen.dart';
import '../ui/levels/views/level_editor_screen.dart';
import '../ui/levels/views/level_item_editor_screen.dart';
import '../ui/levels/views/start_level_screen.dart';
import '../ui/levels/views/attempt_history_screen.dart';
import '../ui/levels/views/attempt_detail_screen.dart';
import '../ui/levels/views/historical_day_screen.dart';

GoRoute levelsRoute(LevelsRepository repository) => GoRoute(
  path: '/levels',
  name: 'levels',
  builder: (context, state) => LevelsScreen(repository: repository),
  routes: [
    GoRoute(
      path: 'create',
      name: 'create-level',
      builder: (context, state) => LevelEditorScreen(
        repository: repository,
        userId: state.uri.queryParameters['userId'] ?? '',
      ),
    ),
    GoRoute(
      path: ':levelId',
      name: 'level-detail',
      builder: (context, state) => LevelDetailScreen(
        repository: repository,
        levelId: state.pathParameters['levelId']!,
      ),
      routes: [
        GoRoute(
          path: 'edit',
          name: 'edit-level',
          builder: (context, state) => LevelEditorScreen(
            repository: repository,
            levelId: state.pathParameters['levelId']!,
          ),
          routes: [
            GoRoute(
              path: 'items/:itemId',
              name: 'level-item-editor',
              builder: (context, state) => LevelItemEditorScreen(
                repository: repository,
                levelId: state.pathParameters['levelId']!,
                itemId: state.pathParameters['itemId'] == 'new'
                    ? null
                    : state.pathParameters['itemId'],
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'start',
          name: 'start-level',
          builder: (context, state) => StartLevelScreen(
            repository: repository,
            levelId: state.pathParameters['levelId']!,
          ),
        ),
        GoRoute(
          path: 'restart',
          name: 'restart-level',
          builder: (context, state) => StartLevelScreen(
            repository: repository,
            levelId: state.pathParameters['levelId']!,
            restart: true,
          ),
        ),
        GoRoute(
          path: 'attempts',
          name: 'attempt-history',
          builder: (context, state) => AttemptHistoryScreen(
            repository: repository,
            levelId: state.pathParameters['levelId']!,
          ),
          routes: [
            GoRoute(
              path: ':attemptId',
              name: 'attempt-detail',
              builder: (context, state) => AttemptDetailScreen(
                repository: repository,
                levelId: state.pathParameters['levelId']!,
                attemptId: state.pathParameters['attemptId']!,
              ),
              routes: [
                GoRoute(
                  path: 'days/:dayId',
                  name: 'historical-day-detail',
                  builder: (context, state) => HistoricalDayScreen(
                    repository: repository,
                    levelId: state.pathParameters['levelId']!,
                    attemptId: state.pathParameters['attemptId']!,
                    dayId: state.pathParameters['dayId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
