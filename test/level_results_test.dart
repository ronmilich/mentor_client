import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mentor_client/models/level.dart';
import 'package:mentor_client/routing/app_router.dart';
import 'package:mentor_client/ui/levels/views/level_detail_screen.dart';

import 'levels_test.dart' show tapVisible;
import 'support/test_repository.dart';

void main() {
  test(
    'card progress uses the active or latest attempt and its day snapshot',
    () {
      final old = {
        ...attemptJson(),
        'id': 'old',
        'status': 'FAILED',
        'startedAt': '2026-09-20T00:00:00Z',
      };
      final current = {
        ...attemptJson(),
        'requiredDays': 8,
        'days': [
          {...dayJson(), 'dayNumber': 3},
          {...dayJson(), 'dayNumber': 1},
        ],
      };
      final level = Level.fromJson(levelJson(attempts: [old, current]));
      expect(level.status, 'IN_PROGRESS');
      expect(level.currentDayNumber, 3);
      expect(level.attemptRequiredDays, 8);
      expect(level.currentAttemptNumber, 2);
      final finished = Level.fromJson(
        levelJson(
          attempts: [
            old,
            {...current, 'status': 'COMPLETED'},
          ],
        ),
      );
      expect(finished.status, 'COMPLETED');
      final unstarted = Level.fromJson(levelJson());
      expect(unstarted.status, 'NOT_STARTED');
      expect(unstarted.currentDayNumber, 0);
      expect(unstarted.currentAttemptNumber, 0);
    },
  );

  testWidgets('level card shows status, current day and attempt count', (
    tester,
  ) async {
    final repository = testRepository(
      handler: (request) async => http.Response(
        jsonEncode(
          request.url.path == '/users'
              ? [
                  {'id': userId, 'name': 'Test profile'},
                ]
              : [
                  levelJson(attempts: [attemptJson()]),
                ],
        ),
        200,
      ),
    );
    addTearDown(repository.close);
    final router = createAppRouter(
      initialLocation: '/levels',
      levelsRepository: repository,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Day 1 / 10 · Attempt 1 / 3'), findsOneWidget);
  });

  testWidgets(
    'results stay editable until explicit finalization and refresh the level',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var day = dayJson();
      var attempt = attemptJson();
      final writes = <http.Request>[];
      final repository = testRepository(
        handler: (request) async {
          dynamic data;
          if (request.method == 'PATCH') {
            writes.add(request);
            final result = {
              ...(day['itemResults'] as List).single as Map<String, dynamic>,
              ...jsonDecode(request.body) as Map<String, dynamic>,
            };
            day = {
              ...day,
              'itemResults': [result],
            };
            data = result;
          } else if (request.method == 'POST') {
            writes.add(request);
            day = {...day, 'status': 'FAILED'};
            attempt = {...attempt, 'status': 'FAILED', 'failedOnDay': 1};
            data = day;
          } else {
            data = levelJson(
              items: [itemJson()],
              attempts: [
                {
                  ...attempt,
                  'days': [day],
                },
              ],
            );
          }
          return http.Response(jsonEncode(data), 200);
        },
      );
      addTearDown(repository.close);
      await tester.pumpWidget(
        MaterialApp(
          home: LevelDetailScreen(repository: repository, levelId: levelId),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> select(String label) async {
        await tapVisible(tester, find.byKey(const ValueKey('result-1')));
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }

      await select('Failed');
      expect(writes.single.method, 'PATCH');
      expect(
        writes.single.url.path,
        '/levels/$levelId/attempts/$attemptId/days/$dayId/items/result-1',
      );
      expect(find.byKey(const ValueKey('result-1')), findsOneWidget);
      await select('Passed');
      await select('Pending');
      await tester.scrollUntilVisible(find.text('Finalize day'), 150);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Finalize day'),
            )
            .onPressed,
        isNull,
      );
      await select('Failed');
      expect(writes.where((r) => r.method == 'POST'), isEmpty);
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Finalize day'),
      );
      expect(
        writes.last.url.path,
        '/levels/$levelId/attempts/$attemptId/days/$dayId/finalize',
      );
      expect(find.byKey(const ValueKey('result-1')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a failed save preserves the saved result and shows the server error',
    (tester) async {
      final response = Completer<http.Response>();
      var writes = 0;
      final repository = testRepository(
        handler: (request) async {
          if (request.method == 'PATCH') {
            writes++;
            return response.future;
          }
          return http.Response(
            jsonEncode(levelJson(attempts: [attemptJson()])),
            200,
          );
        },
      );
      addTearDown(repository.close);
      await tester.pumpWidget(
        MaterialApp(
          home: LevelDetailScreen(repository: repository, levelId: levelId),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('result-1')));
      await tester.tap(find.text('Passed').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.byKey(const ValueKey('result-1')),
            )
            .onChanged,
        isNull,
      );
      response.complete(
        http.Response(
          jsonEncode({'message': 'This day has already been finalized.'}),
          409,
        ),
      );
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(find.text('This day has already been finalized.'), findsOneWidget);
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.byKey(const ValueKey('result-1')),
            )
            .value,
        'PENDING',
      );
    },
  );
}
