// Run against the local Nest server: dart run tool/verify_levels_backend.dart
// Creates an isolated test profile. The PowerShell wrapper cleans it up.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mentor_client/data/repositories/levels_repository.dart';
import 'package:mentor_client/data/services/api_client.dart';
import 'package:mentor_client/models/level.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
  stdout.writeln('PASS: $message');
}

Future<void> main() async {
  final api = ApiClient(baseUrl: 'http://localhost:3000');
  final repository = LevelsRepository(api);
  final suffix = '${DateTime.now().microsecondsSinceEpoch}';
  try {
    final user = await api.request(
      'POST',
      '/users',
      body: {
        'name': 'Levels integration test $suffix',
        'email': 'levels-test-$suffix@example.invalid',
        'password': base64Url.encode(
          List.generate(24, (_) => Random.secure().nextInt(256)),
        ),
      },
    );
    final userId = user['id'] as String;
    final receipt = File('.dart_tool/levels-smoke-receipt.json');
    await receipt.writeAsString(
      jsonEncode({'userId': userId, 'email': user['email']}),
    );
    final level = await repository.saveLevel(null, {
      'userId': userId,
      'number': 1,
      'name': 'Integration level',
      'description': 'Disposable integration test',
      'requiredDays': 10,
      'maxFailedAttempts': 3,
    });
    check(
      (await repository.levels(userId)).single.id == level.id,
      'create and list a level through the Dart repository',
    );
    await expectStatus(
      () => repository.start(level.id),
      400,
      'cannot start without active requirements',
    );
    final item = await repository.saveItem(level.id, null, {
      'title': 'Original requirement',
      'description': null,
      'type': 'DO',
      'sortOrder': 0,
      'isActive': true,
    });
    await repository.saveItem(level.id, null, {
      'title': 'Inactive requirement',
      'description': null,
      'type': 'AVOID',
      'sortOrder': 1,
      'isActive': false,
    });
    check(
      (await repository.level(level.id)).items.length == 2,
      'item creation and overview',
    );
    await expectStatus(
      () => api.request(
        'POST',
        '/levels/${level.id}/start',
        body: {'date': '2026-02-30'},
      ),
      400,
      'invalid calendar dates are rejected',
    );
    final original = await repository.start(level.id);
    check(
      original.days.single.itemResults.length == 1,
      'start snapshots only active requirements',
    );
    await expectStatus(
      () => repository.start(level.id),
      409,
      'duplicate starts are rejected',
    );
    await repository.saveItem(level.id, item.id, {
      'title': 'Updated requirement',
      'description': 'Changed',
      'type': 'AVOID',
      'sortOrder': 2,
      'isActive': true,
    });
    await repository.saveLevel(level.id, {'requiredDays': 14});
    final oldDay = await repository.day(
      level.id,
      original.id,
      original.days.single.id,
    );
    check(
      oldDay.itemResults.single.titleSnapshot == 'Original requirement',
      'historical title is preserved after editing',
    );
    check(
      (await repository.attempt(level.id, original.id)).requiredDays == 10,
      'original attempt keeps its required-days snapshot',
    );
    final restarted = await repository.start(
      level.id,
      restartAttemptId: original.id,
    );
    check(
      restarted.requiredDays == 14 && restarted.days.single.dayNumber == 1,
      'restart begins Day 1 using updated definition',
    );
    check(
      restarted.days.single.itemResults.single.titleSnapshot ==
          'Updated requirement',
      'new attempt snapshots updated requirements',
    );
    final oldAttempt = await repository.attempt(level.id, original.id);
    check(
      oldAttempt.status == 'ABANDONED' && oldAttempt.endedAt != null,
      'restart preserves and closes the original attempt',
    );
    await expectStatus(
      () => repository.start(level.id, restartAttemptId: original.id),
      409,
      'stale restart cannot abandon the new attempt',
    );
    check(
      (await repository.attempts(level.id)).length == 2,
      'attempt history includes both attempts',
    );
    final other = await repository.saveLevel(null, {
      'userId': userId,
      'number': 2,
    });
    await expectStatus(
      () => repository.attempt(other.id, original.id),
      404,
      'attempt cannot be read through the wrong level',
    );
    await expectStatus(
      () => repository.day(level.id, restarted.id, original.days.single.id),
      404,
      'day cannot be read through the wrong attempt',
    );
    await expectStatus(
      () => api.request('DELETE', '/levels/${level.id}'),
      409,
      'attempt history prevents accidental level deletion',
    );
    final day = restarted.days.single;
    final result = day.itemResults.single;
    Future<LevelAttemptItemResult> update(String status) => repository
        .updateItemResult(level.id, restarted.id, day.id, result.id, status);
    await expectStatus(
      () => repository.updateItemResult(
        level.id,
        original.id,
        oldDay.id,
        oldDay.itemResults.single.id,
        'PASSED',
      ),
      409,
      'abandoned attempts cannot be edited',
    );
    await expectStatus(
      () => repository.updateItemResult(
        level.id,
        restarted.id,
        day.id,
        oldDay.itemResults.single.id,
        'PASSED',
      ),
      404,
      'results cannot be edited through a different day',
    );
    await expectStatus(
      () => repository.finalizeDay(level.id, restarted.id, day.id),
      400,
      'pending items prevent finalization',
    );
    check(
      (await update('FAILED')).evaluatedAt != null,
      'failed result records evaluation time',
    );
    check(
      (await repository.attempt(level.id, restarted.id)).status ==
          'IN_PROGRESS',
      'failed item does not automatically end the attempt',
    );
    await update('PASSED');
    check(
      (await update('PENDING')).evaluatedAt == null,
      'resetting an item clears evaluation time',
    );
    await update('FAILED');
    await repository.finalizeDay(level.id, restarted.id, day.id);
    final failed = await repository.attempt(level.id, restarted.id);
    check(
      failed.status == 'FAILED' &&
          failed.failedOnDay == 1 &&
          failed.endedAt != null,
      'explicit finalization closes a failed attempt',
    );
    await expectStatus(
      () => update('PASSED'),
      409,
      'finalized results are read-only',
    );
    final summary = (await repository.levels(
      userId,
    )).firstWhere((entry) => entry.id == level.id);
    check(
      summary.status == 'FAILED' &&
          summary.currentDayNumber == 1 &&
          summary.currentAttemptNumber == 2,
      'levels list contains current status and progress',
    );

    await repository.saveLevel(other.id, {'requiredDays': 2});
    await repository.saveItem(other.id, null, {
      'title': 'Two-day requirement',
      'type': 'DO',
      'sortOrder': 0,
      'isActive': true,
    });
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final date =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    final successful = LevelAttempt.fromJson(
      await api.request(
        'POST',
        '/levels/${other.id}/start',
        body: {'date': date},
      ),
    );
    final first = successful.days.single;
    await repository.updateItemResult(
      other.id,
      successful.id,
      first.id,
      first.itemResults.single.id,
      'PASSED',
    );
    await repository.finalizeDay(other.id, successful.id, first.id);
    await expectStatus(
      () => repository.updateItemResult(
        other.id,
        successful.id,
        first.id,
        first.itemResults.single.id,
        'PENDING',
      ),
      409,
      'completed days cannot be edited while the attempt continues',
    );
    final next = await repository.startNextDay(other.id, successful.id);
    check(
      next.dayNumber == 2 && next.itemResults.single.status == 'PENDING',
      'next day starts with pending results',
    );
    await expectStatus(
      () => repository.startNextDay(other.id, successful.id),
      409,
      'duplicate next days are rejected',
    );
    await repository.updateItemResult(
      other.id,
      successful.id,
      next.id,
      next.itemResults.single.id,
      'PASSED',
    );
    await repository.finalizeDay(other.id, successful.id, next.id);
    check(
      (await repository.attempt(other.id, successful.id)).status == 'COMPLETED',
      'final successful day completes the attempt',
    );
    stdout.writeln('All live backend checks passed.');
  } finally {
    api.close();
  }
}

Future<void> expectStatus(
  Future<dynamic> Function() request,
  int status,
  String message,
) async {
  try {
    await request();
  } on ApiException catch (error) {
    check(error.statusCode == status, message);
    return;
  }
  throw StateError('$message: expected HTTP $status');
}
