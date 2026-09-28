import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routing/app_router.dart';
import 'config/api_config.dart';
import 'data/services/api_client.dart';
import 'data/repositories/levels_repository.dart';

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
  late final GoRouter _router = createAppRouter(levelsRepository: _repository);

  @override
  void dispose() {
    _router.dispose();
    if (widget.levelsRepository == null) _repository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mentor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: _router,
    );
  }
}
