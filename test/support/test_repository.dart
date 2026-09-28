import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mentor_client/data/repositories/levels_repository.dart';
import 'package:mentor_client/data/services/api_client.dart';

const userId = '11111111-1111-4111-8111-111111111111';
const levelId = '22222222-2222-4222-8222-222222222222';
const attemptId = '33333333-3333-4333-8333-333333333333';
const dayId = '44444444-4444-4444-8444-444444444444';

Map<String, dynamic> levelJson({
  List<dynamic> items = const [],
  List<dynamic> attempts = const [],
}) => {
  'id': levelId,
  'userId': userId,
  'number': 1,
  'name': 'Daily focus',
  'description': 'Small steps every day.',
  'requiredDays': 10,
  'maxFailedAttempts': 3,
  'items': items,
  'attempts': attempts,
};

Map<String, dynamic> itemJson() => {
  'id': '55555555-5555-4555-8555-555555555555',
  'title': 'Read for 20 minutes',
  'description': null,
  'type': 'DO',
  'sortOrder': 0,
  'isActive': true,
};

Map<String, dynamic> dayJson() => {
  'id': dayId,
  'dayNumber': 1,
  'date': '2026-09-27',
  'status': 'IN_PROGRESS',
  'itemResults': [
    {
      'id': 'result-1',
      'titleSnapshot': 'Original requirement',
      'typeSnapshot': 'DO',
      'status': 'PENDING',
    },
  ],
};

Map<String, dynamic> attemptJson() => {
  'id': attemptId,
  'levelId': levelId,
  'status': 'IN_PROGRESS',
  'requiredDays': 10,
  'startedAt': '2026-09-27T08:00:00Z',
  'endedAt': null,
  'failedOnDay': null,
  'days': [dayJson()],
};

LevelsRepository testRepository({
  Future<http.Response> Function(http.Request)? handler,
}) => LevelsRepository(
  ApiClient(
    baseUrl: 'http://test',
    client: MockClient(
      handler ??
          (request) async {
            dynamic data;
            switch (request.url.path) {
              case '/users':
                data = [
                  {'id': userId, 'name': 'Test profile'},
                ];
              case '/levels':
                data = [levelJson()];
              case '/levels/$levelId/overview':
                data = levelJson(items: [itemJson()]);
              case '/levels/$levelId/attempts':
                data = [attemptJson()];
              case '/levels/$levelId/attempts/$attemptId':
                data = attemptJson();
              case '/levels/$levelId/attempts/$attemptId/days/$dayId':
                data = dayJson();
              default:
                return http.Response(jsonEncode({'message': 'Not found'}), 404);
            }
            return http.Response(jsonEncode(data), 200);
          },
    ),
  ),
);
