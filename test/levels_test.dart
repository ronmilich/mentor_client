import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mentor_client/data/services/api_client.dart';
import 'package:mentor_client/routing/app_router.dart';
import 'package:mentor_client/ui/levels/view_models/levels_view_models.dart';
import 'package:mentor_client/ui/levels/views/level_editor_screen.dart';

import 'support/test_repository.dart';

void main() {
  test(
    'API preserves server validation errors and does not retry writes',
    () async {
      var requests = 0;
      final api = ApiClient(
        baseUrl: 'http://test',
        client: MockClient((request) async {
          requests++;
          expect(request.headers['content-type'], contains('application/json'));
          return http.Response(
            jsonEncode({
              'message': ['number must be an integer', 'name is too long'],
            }),
            400,
          );
        }),
      );
      addTearDown(api.close);
      await expectLater(
        api.request('POST', '/levels', body: {'number': 1}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 400)
              .having(
                (e) => e.message,
                'message',
                contains('name is too long'),
              ),
        ),
      );
      expect(requests, 1);
    },
  );

  test(
    'network errors are readable and a disposed view model ignores notifications',
    () async {
      final api = ApiClient(
        baseUrl: 'http://test',
        client: MockClient((_) async {
          throw http.ClientException('offline');
        }),
      );
      addTearDown(api.close);
      await expectLater(
        api.request('GET', '/levels'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Cannot reach'),
          ),
        ),
      );
      final pending = Completer<String>();
      final model = ResourceViewModel(() => pending.future);
      final load = model.load();
      model.dispose();
      pending.complete('done');
      expect(await load, isTrue);
    },
  );

  test(
    'saving twice while a request is pending only sends one write',
    () async {
      final response = Completer<http.Response>();
      var writes = 0;
      final repository = testRepository(
        handler: (_) {
          writes++;
          return response.future;
        },
      );
      addTearDown(repository.close);
      final model = LevelEditorViewModel(repository, userId: userId);
      addTearDown(model.dispose);
      final first = model.save({'number': 1});
      expect(await model.save({'number': 1}), isFalse);
      response.complete(http.Response(jsonEncode(levelJson()), 201));
      expect(await first, isTrue);
      expect(writes, 1);
    },
  );

  final pages = {
    '/levels/$levelId': 'Level detail',
    '/levels/$levelId/edit': 'Edit level',
    '/levels/$levelId/edit/items/new': 'Add level item',
    '/levels/$levelId/start': 'Start level confirmation',
    '/levels/$levelId/restart': 'Restart level',
    '/levels/$levelId/attempts': 'Attempt history',
    '/levels/$levelId/attempts/$attemptId': 'Attempt detail',
    '/levels/$levelId/attempts/$attemptId/days/$dayId': 'Historical day detail',
  };
  for (final page in pages.entries) {
    testWidgets('${page.value} supports a direct route on a small phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = testRepository();
      addTearDown(repository.close);
      final router = createAppRouter(
        initialLocation: page.key,
        levelsRepository: repository,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text(page.value), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect(tester.takeException(), isNull);
      if (page.value == 'Historical day detail') {
        expect(find.text('Original requirement'), findsOneWidget);
        expect(find.byType(Checkbox), findsNothing);
      }
      router.pop();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, isNot(page.key));
    });
  }

  testWidgets('a failed level list can be retried', (tester) async {
    var fail = true;
    final repository = testRepository(
      handler: (request) async {
        if (fail) {
          return http.Response(
            jsonEncode({'message': 'Temporarily unavailable'}),
            503,
          );
        }
        return http.Response(
          jsonEncode(
            request.url.path == '/users'
                ? [
                    {'id': userId, 'name': 'Test profile'},
                  ]
                : [levelJson()],
          ),
          200,
        );
      },
    );
    addTearDown(repository.close);
    final router = createAppRouter(
      initialLocation: '/levels',
      levelsRepository: repository,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Temporarily unavailable'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Not started'), findsOneWidget);
    expect(find.text('Temporarily unavailable'), findsNothing);
  });

  for (final restart in [false, true]) {
    testWidgets(
      '${restart ? 'restart' : 'start'} requires confirmation and refreshes detail',
      (tester) async {
        final writes = <http.Request>[];
        var attempts = restart ? [attemptJson()] : <Map<String, dynamic>>[];
        final repository = testRepository(
          handler: (request) async {
            dynamic data;
            if (request.method == 'POST') {
              writes.add(request);
              attempts = [attemptJson()];
              data = attemptJson();
            } else if (request.url.path == '/users') {
              data = [
                {'id': userId, 'name': 'Test profile'},
              ];
            } else if (request.url.path == '/levels') {
              data = [levelJson()];
            } else {
              data = levelJson(items: [itemJson()], attempts: attempts);
            }
            return http.Response(jsonEncode(data), 200);
          },
        );
        addTearDown(repository.close);
        final router = createAppRouter(
          initialLocation: '/levels/$levelId/${restart ? 'restart' : 'start'}',
          levelsRepository: repository,
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        expect(writes, isEmpty);
        await tapVisible(
          tester,
          find.widgetWithText(
            FilledButton,
            restart ? 'Confirm restart' : 'Start level',
          ),
        );
        expect(writes, hasLength(1));
        final body = jsonDecode(writes.single.body) as Map<String, dynamic>;
        expect(body['date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
        expect(body.containsKey('attemptId'), restart);
        if (restart) expect(body['attemptId'], attemptId);
        expect(find.text('Level detail'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('View current attempt'),
          200,
          scrollable: find
              .descendant(
                of: find.byType(ListView).last,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.text('View current attempt'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'create validates empty fields even after scrolling them offscreen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var writes = 0;
      final repository = testRepository(
        handler: (request) async {
          if (request.method == 'POST') writes++;
          return http.Response(
            jsonEncode(
              request.url.path == '/users'
                  ? [
                      {'id': userId, 'name': 'Test profile'},
                    ]
                  : [],
            ),
            200,
          );
        },
      );
      addTearDown(repository.close);
      final router = createAppRouter(
        initialLocation: '/levels/create?userId=$userId',
        levelsRepository: repository,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Create level'),
      );
      expect(writes, 0);
      expect(
        find.text('Enter a whole number from 1 to 32767.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('create, add an item, and return to a refreshed level detail', (
    tester,
  ) async {
    var level = levelJson();
    final items = <Map<String, dynamic>>[];
    final repository = testRepository(
      handler: (request) async {
        dynamic data;
        if (request.url.path == '/users') {
          data = [
            {'id': userId, 'name': 'Test profile'},
          ];
        } else if (request.url.path.endsWith('/items') &&
            request.method == 'POST') {
          data = {
            ...itemJson(),
            ...jsonDecode(request.body) as Map<String, dynamic>,
          };
          items.add(data);
        } else if (request.method == 'POST' || request.method == 'PATCH') {
          level = {
            ...level,
            ...jsonDecode(request.body) as Map<String, dynamic>,
          };
          data = level;
        } else if (request.url.path == '/levels') {
          data = [level];
        } else {
          data = {...level, 'items': items};
        }
        return http.Response(jsonEncode(data), 200);
      },
    );
    addTearDown(repository.close);
    final router = createAppRouter(
      initialLocation: '/levels/create?userId=$userId',
      levelsRepository: repository,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Level number'),
      '2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name (optional)'),
      'My new level',
    );
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Create level'));
    expect(find.byType(LevelEditorScreen), findsOneWidget);
    expect(find.text('Edit level'), findsOneWidget);
    await tapVisible(tester, find.text('Add level item'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Requirement'),
      'Read a chapter',
    );
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save item'));
    expect(items.single['title'], 'Read a chapter');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save changes'));
    expect(find.text('Level detail'), findsOneWidget);
    expect(find.text('Read a chapter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
