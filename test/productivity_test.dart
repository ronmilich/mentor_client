import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentor_client/data/services/api_client.dart';
import 'package:mentor_client/data/repositories/productivity_repository.dart';
import 'package:mentor_client/models/level.dart';
import 'package:mentor_client/ui/core/app_theme.dart';
import 'package:mentor_client/ui/core/sign_in_gate.dart';
import 'package:mentor_client/ui/journal/views/journal_screen.dart';
import 'package:mentor_client/ui/tasks/views/tasks_screen.dart';
import 'package:mentor_client/ui/tasks/views/task_editor.dart';
import 'package:mentor_client/ui/tasks/views/task_catalog.dart';
import 'package:mentor_client/ui/levels/views/level_widgets.dart';
import 'package:mentor_client/ui/journal/views/journal_calendar.dart';

http.Response response(Object? data, [int code = 200]) => http.Response(
  jsonEncode(data),
  code,
  headers: {'content-type': 'application/json'},
);
ProductivityRepository repository(
  Future<http.Response> Function(http.Request) handler,
) {
  final api = ApiClient(baseUrl: 'http://test', client: MockClient(handler))
    ..accessToken = 'test-token';
  final repo = ProductivityRepository(api)..userId = 'user-1';
  addTearDown(() {
    repo.dispose();
    api.close();
  });
  return repo;
}

const taskList = {'id': 'list-1', 'name': 'Work', 'status': 'ACTIVE'};
const tag = {
  'id': 'tag-1',
  'label': 'Deep work',
  'color': '#5260C7',
  'status': 'ACTIVE',
};
Json task({String status = 'NOT_STARTED'}) => {
  'id': 'task-1',
  'title': 'Write a chapter',
  'description': 'Make a start',
  'listId': 'list-1',
  'list': taskList,
  'priority': 'NORMAL',
  'status': status,
  'dueDate': '2020-01-01',
  'estimatedDurationMinutes': 30,
  'tags': [tag],
};
Widget app(Widget child) =>
    MaterialApp(theme: mentorTheme(Brightness.light), home: child);
Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);
Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sign-in sets bearer identity and pagination reads every page', () async {
    final token =
        'header.${base64Url.encode(utf8.encode(jsonEncode({'sub': 'user-1'})))}.signature';
    final offsets = <String?>[];
    final repo = repository((request) async {
      if (request.url.path == '/auth/sign-in') {
        return response({'accessToken': token});
      }
      expect(request.headers['Authorization'], 'Bearer $token');
      offsets.add(request.url.queryParameters['offset']);
      return response({
        'items': [
          {'id': offsets.length},
        ],
        'total': 2,
      });
    });
    repo.signOut();
    await repo.signIn('user@example.com', 'password');
    expect(repo.userId, 'user-1');
    expect((await repo.all('/tasks')).length, 2);
    expect(offsets, ['0', '1']);
  });

  test(
    '401 expires session; a missing journal is empty but server failures propagate',
    () async {
      var code = 404;
      final repo = repository(
        (_) async => response({'message': 'Unavailable'}, code),
      );
      expect(await repo.journal('2026-01-01'), isNull);
      code = 500;
      await expectLater(
        repo.journal('2026-01-01'),
        throwsA(isA<ApiException>()),
      );
      expect(repo.signedIn, isTrue);
      code = 401;
      await expectLater(repo.all('/tasks'), throwsA(isA<ApiException>()));
      expect(repo.signedIn, isFalse);
    },
  );

  test('task status colors are distinct', () {
    expect(
      [
        'NOT_STARTED',
        'IN_PROGRESS',
        'COMPLETED',
        'CANCELLED',
        'ARCHIVED',
      ].map(statusColor).toSet().length,
      5,
    );
  });

  testWidgets(
    'journal modes save only changed fields into the same calendar day',
    (tester) async {
      final writes = <Json>[];
      final date = calendarDate(DateTime.now());
      final stored = <String, dynamic>{
        'date': date,
        'text': 'Original journal',
        'wins': 'A small win',
        'mood': 4,
      };
      final repo = repository((request) async {
        expect(request.url.path, '/journals/$date');
        if (request.method == 'PATCH') {
          final data = jsonDecode(request.body) as Json;
          writes.add(data);
          stored.addAll(data);
        }
        return response(stored);
      });
      await tester.pumpWidget(app(JournalEditor(repository: repo)));
      await tester.pumpAndSettle();
      await tester.enterText(field('Wins'), 'Finished a chapter');
      await tapVisible(tester, find.text('Save reflection'));
      expect(writes.single, {'wins': 'Finished a chapter'});
      expect(stored['text'], 'Original journal');
      await tapVisible(tester, find.text('Full journal'));
      await tester.enterText(field('Your journal'), 'Today was good.');
      await tapVisible(tester, find.text('Save journal'));
      expect(writes.last, {'text': 'Today was good.'});
      expect(stored['wins'], 'Finished a chapter');
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed journal save preserves a draft and restores it offline', (
    tester,
  ) async {
    var offline = false;
    final repo = repository((request) async {
      if (offline || request.method == 'PATCH') {
        return response({'message': 'Connection lost'}, 503);
      }
      return response({'text': '', 'date': calendarDate(DateTime.now())});
    });
    await tester.pumpWidget(app(JournalEditor(repository: repo)));
    await tester.pumpAndSettle();
    await tester.enterText(field('Wins'), 'Keep this thought');
    await tapVisible(tester, find.text('Save reflection'));
    expect(find.text('Connection lost'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('journal-draft:user-1:${calendarDate(DateTime.now())}'),
      contains('Keep this thought'),
    );
    await tester.pumpWidget(const SizedBox());
    offline = true;
    await tester.pumpWidget(app(JournalEditor(repository: repo)));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field('Wins')).controller!.text,
      'Keep this thought',
    );
  });

  testWidgets('journal ratings can be cleared and fit a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Json? body;
    final repo = repository((request) async {
      if (request.method == 'PATCH') body = jsonDecode(request.body) as Json;
      return response({'mood': 4});
    });
    await tester.pumpWidget(app(JournalEditor(repository: repo)));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byType(ChoiceChip).at(3));
    await tapVisible(tester, find.text('Save reflection'));
    expect(body, {'mood': null});
    expect(tester.takeException(), isNull);
  });

  testWidgets('task board filters active, overdue, completed, and search', (
    tester,
  ) async {
    final repo = repository(
      (request) async => response({
        'items': switch (request.url.path) {
          '/tasks' => [
            task(),
            {
              ...task(status: 'COMPLETED'),
              'id': 'task-2',
              'title': 'Done already',
            },
          ],
          '/task-lists' => [taskList],
          _ => [tag],
        },
        'total': request.url.path == '/tasks' ? 2 : 1,
      }),
    );
    await tester.pumpWidget(app(TaskBoard(repository: repo)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Write a chapter'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Done already'), findsNothing);
    await tapVisible(tester, find.widgetWithText(FilterChip, 'Completed'));
    expect(find.text('Done already'), findsOneWidget);
    expect(find.text('Write a chapter'), findsNothing);
    await tapVisible(tester, find.widgetWithText(FilterChip, 'Overdue'));
    expect(find.text('Write a chapter'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'no match');
    await tester.pumpAndSettle();
    expect(find.text('No matching tasks'), findsOneWidget);
  });

  testWidgets(
    'task form validates and clears nullable fields without sending status',
    (tester) async {
      Json? saved;
      final repo = repository((request) async {
        saved = jsonDecode(request.body) as Json;
        return response(task());
      });
      await tester.pumpWidget(
        app(
          TaskEditor(
            repository: repo,
            lists: [taskList],
            tags: [tag],
            task: task(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(field('Title'), '');
      await tapVisible(tester, find.text('Save changes'));
      expect(saved, isNull);
      await tester.enterText(field('Title'), 'Updated task');
      await tester.enterText(field('Description'), '');
      await tester.enterText(field('Estimated duration (minutes)'), '-2');
      await tapVisible(tester, find.text('Save changes'));
      expect(saved, isNull);
      await tester.enterText(field('Estimated duration (minutes)'), '');
      await tapVisible(tester, find.byTooltip('Clear due date'));
      await tapVisible(tester, find.widgetWithText(FilterChip, 'Deep work'));
      await tapVisible(tester, find.text('Save changes'));
      expect(saved, {
        'title': 'Updated task',
        'description': null,
        'priority': 'NORMAL',
        'dueDate': null,
        'estimatedDurationMinutes': null,
        'tagIds': [],
      });
    },
  );

  testWidgets(
    'task lifecycle starts, completes, archives and reopens through the API',
    (tester) async {
      var stored = task();
      final statuses = <String>[];
      final repo = repository((request) async {
        if (request.method == 'PATCH') {
          expect(request.url.path, '/tasks/task-1/status');
          final status = jsonDecode(request.body)['status'] as String;
          statuses.add(status);
          stored = task(status: status);
        }
        return response(stored);
      });
      await tester.pumpWidget(
        app(
          TaskDetail(
            repository: repo,
            id: 'task-1',
            lists: [taskList],
            tags: [tag],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Start task'));
      await tapVisible(tester, find.text('Complete task'));
      await tapVisible(tester, find.text('Archive'));
      expect(find.byTooltip('Edit task'), findsNothing);
      await tapVisible(tester, find.text('Reopen task'));
      expect(statuses, ['IN_PROGRESS', 'COMPLETED', 'ARCHIVED', 'NOT_STARTED']);
    },
  );

  testWidgets('tag conflicts stay editable and display the server error', (
    tester,
  ) async {
    final repo = repository(
      (_) async =>
          response({'message': 'A tag with this label already exists'}, 409),
    );
    await tester.pumpWidget(
      app(Scaffold(body: CatalogEditor(repository: repo, tags: true))),
    );
    await tester.enterText(field('Label'), 'Deep work');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('A tag with this label already exists'), findsOneWidget);
    expect(
      tester.widget<TextField>(field('Label')).controller!.text,
      'Deep work',
    );
  });

  testWidgets('nested pages hide private data when the session ends', (
    tester,
  ) async {
    final repo = repository((_) async => response({}));
    await tester.pumpWidget(
      app(SessionPage(repository: repo, child: const Text('Private entry'))),
    );
    expect(find.text('Private entry'), findsOneWidget);
    repo.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Private entry'), findsNothing);
    expect(find.text('Session ended'), findsOneWidget);
  });

  testWidgets('feature screens and history fit mobile light and dark layouts', (tester) async {
    tester.view.physicalSize = const Size(390, 844); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    const font = String.fromEnvironment('PREVIEW_FONT');
    if (font.isNotEmpty) {
      final loader = FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(File(font).readAsBytesSync())));
      await loader.load();
    }
    final date = calendarDate(DateTime.now());
    final repo = repository((request) async {
      final path = request.url.path;
      if (path == '/journals/$date') return response({'text': 'Today I made time for what matters.', 'wins': 'An uninterrupted morning', 'mood': 4, 'energy': 3, 'stress': 2, 'focus': 4, 'sleepQuality': 3});
      return response({'items': switch(path) {
        '/tasks' => [task(), {...task(status: 'IN_PROGRESS'), 'id': 'task-2', 'title': 'Plan tomorrow', 'dueDate': date}],
        '/task-lists' => [taskList], '/tags' => [tag],
        _ => [{'date': date, 'text': 'Today I made time for what matters.', 'mood': 4, 'energy': 3}],
      }, 'total': path == '/tasks' ? 2 : 1});
    });
    for (final brightness in Brightness.values) {
      for (final screen in ['tasks', 'journal', 'history', 'editor']) {
        final boundary = GlobalKey();
        await tester.pumpWidget(MaterialApp(theme: mentorTheme(brightness), home: RepaintBoundary(key: boundary, child: switch(screen) {
          'tasks' => TaskBoard(repository: repo),
          'journal' => JournalEditor(repository: repo),
          'history' => JournalHistory(repository: repo),
          _ => TaskEditor(repository: repo, lists: [taskList], tags: [tag]),
        })));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$screen $brightness');
        if (screen == 'history') expect(find.byType(JournalCalendar), findsOneWidget);
        if (const bool.fromEnvironment('CAPTURE_PREVIEWS')) {
          await tester.runAsync(() async {
            final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage();
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            final output = File('.dart_tool/previews/$screen-${brightness.name}.png');
            await output.parent.create(recursive: true);
            await output.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    }
  });
}
