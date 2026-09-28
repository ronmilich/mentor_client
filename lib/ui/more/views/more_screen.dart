import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import '../../core/app_theme.dart';
import '../../levels/views/level_widgets.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('More')),
    body: ContentList(
      children: [
        const FeatureBanner(
          title: 'Build a practice that lasts.',
          subtitle: 'Your plans, progress, and reflections in one place.',
          icon: Icons.spa_outlined,
          color: Color(0xff7647b8),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Lists & tags'),
            subtitle: const Text('Open Tasks → menu to organize your work.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/tasks'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Journal history'),
            subtitle: const Text('Open Journal → history to revisit a day.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/journal'),
          ),
        ),
        const SizedBox(height: 24),
        Text('Mentor', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Build yourself, one level at a time.'),
      ],
    ),
  );
}
