import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/levels_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../models/level.dart';

class AsyncViewModel extends ChangeNotifier {
  bool busy = false;
  String? error;
  bool _disposed = false;

  Future<bool> run(Future<void> Function() action) async {
    if (busy || _disposed) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      error = e is ApiException
          ? e.message
          : 'Something went wrong. Please try again.';
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class LevelsViewModel extends AsyncViewModel {
  LevelsViewModel(this.repository, {this.selectedUserId = ''}) {
    _subscription = repository.changes.listen((_) => load());
  }
  late final StreamSubscription<void> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  final LevelsRepository repository;
  String selectedUserId;
  List<MentorUser> users = [];
  List<Level> levels = [];

  Future<bool> load() => run(() async {
    users = await repository.users();
    if (selectedUserId.isEmpty && users.length == 1) {
      selectedUserId = users.single.id;
    }
    levels = selectedUserId.isEmpty
        ? []
        : await repository.levels(selectedUserId);
  });

  Future<bool> selectUser(String id) async {
    if (busy) return false;
    selectedUserId = id;
    levels = [];
    return load();
  }
}

class ResourceViewModel<T> extends AsyncViewModel {
  ResourceViewModel(this.loader, {Stream<void>? changes}) {
    _subscription = changes?.listen((_) => load());
  }
  StreamSubscription<void>? _subscription;
  bool _reloadPending = false;
  final Future<T> Function() loader;
  T? data;
  Future<bool> load() async {
    if (busy) {
      _reloadPending = true;
      return false;
    }
    final result = await run(() async {
      data = await loader();
    });
    if (_reloadPending) {
      _reloadPending = false;
      return load();
    }
    return result;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class LevelEditorViewModel extends AsyncViewModel {
  LevelEditorViewModel(this.repository, {this.id, required this.userId});
  final LevelsRepository repository;
  String? id;
  String userId;
  Level? level;
  Future<bool> load() => run(() async {
    if (id != null) {
      level = await repository.level(id!);
      userId = level!.userId;
    }
  });
  Future<bool> save(Json values) => run(() async {
    level = await repository.saveLevel(id, {
      ...values,
      if (id == null) 'userId': userId,
    });
    id = level!.id;
  });
}

class LevelItemEditorViewModel extends AsyncViewModel {
  LevelItemEditorViewModel(this.repository, this.levelId, this.id);
  final LevelsRepository repository;
  final String levelId;
  final String? id;
  LevelItem? item;
  Future<bool> load() => run(() async {
    if (id != null) {
      item = (await repository.level(
        levelId,
      )).items.where((e) => e.id == id).firstOrNull;
      if (item == null) {
        throw const ApiException('This requirement no longer exists.');
      }
    }
  });
  Future<bool> save(Json values) => run(() async {
    item = await repository.saveItem(levelId, id, values);
  });
}

class StartLevelViewModel extends AsyncViewModel {
  StartLevelViewModel(this.repository, this.levelId, {required this.restart});
  final LevelsRepository repository;
  final String levelId;
  final bool restart;
  Level? level;
  LevelAttempt? startedAttempt;
  Future<bool> load() => run(() async {
    level = await repository.level(levelId);
  });
  Future<bool> confirm() => run(() async {
    if (restart && level?.activeAttempt == null) {
      throw const ApiException(
        'There is no active attempt to restart. Refresh this level.',
      );
    }
    startedAttempt = await repository.start(
      levelId,
      restartAttemptId: restart ? level!.activeAttempt!.id : null,
    );
  });
}
