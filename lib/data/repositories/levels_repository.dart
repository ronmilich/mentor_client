import 'dart:async';

import '../../models/level.dart';
import '../services/api_client.dart';

class LevelsRepository {
  LevelsRepository(this.api);
  final ApiClient api;
  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;

  Future<T> _write<T>(Future<T> Function() action) async {
    final result = await action();
    if (!_changes.isClosed) _changes.add(null);
    return result;
  }

  void close() {
    _changes.close();
    api.close();
  }

  Future<List<MentorUser>> users() async =>
      (await api.request('GET', '/users') as List)
          .map((e) => MentorUser.fromJson(e))
          .toList();

  Future<List<Level>> levels(String userId) async =>
      (await api.request('GET', '/levels') as List)
          .map((e) => Level.fromJson(e))
          .where((level) => level.userId == userId)
          .toList();

  Future<Level> level(String id) async =>
      Level.fromJson(await api.request('GET', '/levels/$id/overview'));

  Future<Level> saveLevel(String? id, Json values) => _write(
    () async => Level.fromJson(
      await api.request(
        id == null ? 'POST' : 'PATCH',
        id == null ? '/levels' : '/levels/$id',
        body: values,
      ),
    ),
  );

  Future<LevelItem> saveItem(String levelId, String? id, Json values) => _write(
    () async => LevelItem.fromJson(
      await api.request(
        id == null ? 'POST' : 'PATCH',
        '/levels/$levelId/items${id == null ? '' : '/$id'}',
        body: values,
      ),
    ),
  );

  Future<List<LevelAttempt>> attempts(String levelId) async =>
      (await api.request('GET', '/levels/$levelId/attempts') as List)
          .map((e) => LevelAttempt.fromJson(e))
          .toList();

  Future<LevelAttempt> attempt(String levelId, String id) async =>
      LevelAttempt.fromJson(
        await api.request('GET', '/levels/$levelId/attempts/$id'),
      );

  Future<LevelAttemptDay> day(
    String levelId,
    String attemptId,
    String dayId,
  ) async => LevelAttemptDay.fromJson(
    await api.request(
      'GET',
      '/levels/$levelId/attempts/$attemptId/days/$dayId',
    ),
  );

  static String localDate() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<LevelAttemptItemResult> updateItemResult(
    String levelId,
    String attemptId,
    String dayId,
    String resultId,
    String status,
  ) => _write(
    () async => LevelAttemptItemResult.fromJson(
      await api.request(
        'PATCH',
        '/levels/$levelId/attempts/$attemptId/days/$dayId/items/$resultId',
        body: {'status': status},
      ),
    ),
  );

  Future<LevelAttemptDay> finalizeDay(
    String levelId,
    String attemptId,
    String dayId,
  ) => _write(
    () async => LevelAttemptDay.fromJson(
      await api.request(
        'POST',
        '/levels/$levelId/attempts/$attemptId/days/$dayId/finalize',
      ),
    ),
  );

  Future<LevelAttemptDay> startNextDay(String levelId, String attemptId) =>
      _write(
        () async => LevelAttemptDay.fromJson(
          await api.request(
            'POST',
            '/levels/$levelId/attempts/$attemptId/days',
            body: {'date': localDate()},
          ),
        ),
      );

  Future<LevelAttempt> start(String levelId, {String? restartAttemptId}) async {
    return _write(
      () async => LevelAttempt.fromJson(
        await api.request(
          'POST',
          '/levels/$levelId/${restartAttemptId == null ? 'start' : 'restart'}',
          body: {'date': localDate(), 'attemptId': ?restartAttemptId},
        ),
      ),
    );
  }
}
