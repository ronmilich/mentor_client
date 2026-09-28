import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routing/app_router.dart';
import 'config/api_config.dart';
import 'data/services/api_client.dart';
import 'data/repositories/levels_repository.dart';
import 'data/repositories/productivity_repository.dart';
import 'ui/core/app_theme.dart';

class MentorApp extends StatefulWidget {
  const MentorApp({super.key, this.levelsRepository});
  final LevelsRepository? levelsRepository;

  @override
  State<MentorApp> createState() => _MentorAppState();
}

class _MentorAppState extends State<MentorApp> {
  late final ApiClient? _api = widget.levelsRepository == null
      ? ApiClient(baseUrl: ApiConfig.baseUrl)
      : null;
  late final LevelsRepository _repository =
      widget.levelsRepository ?? LevelsRepository(_api!);
  late final _productivity = ProductivityRepository(_repository.api);
  late final GoRouter _router = createAppRouter(
    levelsRepository: _repository,
    productivityRepository: _productivity,
  );

  @override
  void dispose() {
    _router.dispose();
    _productivity.dispose();
    if (widget.levelsRepository == null) _repository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mentor',
      debugShowCheckedModeBanner: false,
      theme: mentorTheme(Brightness.light),
      darkTheme: mentorTheme(Brightness.dark),
      routerConfig: _router,
    );
  }
}
