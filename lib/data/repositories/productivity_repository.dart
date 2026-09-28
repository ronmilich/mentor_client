import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/level.dart';
import '../services/api_client.dart';

String calendarDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class ProductivityRepository extends ChangeNotifier {
  ProductivityRepository(this.api);
  final ApiClient api;
  String? userId;
  bool get signedIn => api.accessToken != null;

  Future<void> signIn(String email, String password) async {
    final data = await api.request(
      'POST',
      '/auth/sign-in',
      body: {'email': email.trim(), 'password': password},
    );
    final token = data['accessToken'] as String;
    final payload =
        jsonDecode(
              utf8.decode(
                base64Url.decode(base64Url.normalize(token.split('.')[1])),
              ),
            )
            as Json;
    userId = payload['sub'] as String;
    api.accessToken = token;
    notifyListeners();
  }

  void signOut() {
    api.accessToken = null;
    userId = null;
    notifyListeners();
  }

  Future<dynamic> request(String method, String path, {Json? body}) async {
    try {
      return await api.request(method, path, body: body);
    } on ApiException catch (e) {
      if (e.statusCode == 401) signOut();
      rethrow;
    }
  }

  Future<List<Json>> all(String path) async {
    final items = <Json>[];
    while (true) {
      final page =
          await request(
                'GET',
                '$path${path.contains('?') ? '&' : '?'}limit=100&offset=${items.length}',
              )
              as Json;
      final batch = (page['items'] as List).cast<Json>();
      items.addAll(batch);
      if (batch.isEmpty || items.length >= (page['total'] as int)) return items;
    }
  }

  Future<Json?> journal(String date) async {
    try {
      return await request('GET', '/journals/$date') as Json;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
