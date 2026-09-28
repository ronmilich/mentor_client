import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import '../../core/app_theme.dart';
import '../../levels/views/level_widgets.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Today')),
    body: ContentList(
      children: [
        FeatureBanner(
          title: 'One day. A little better.',
          subtitle: MaterialLocalizations.of(
            context,
          ).formatFullDate(DateTime.now()),
          icon: Icons.wb_sunny_outlined,
        ),
        Text(
          'Your daily rhythm',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final item in [
          (
            Icons.layers_outlined,
            'Show up for your level',
            'Check your daily requirements and progress.',
            '/levels',
            const Color(0xff5260c7),
          ),
          (
            Icons.check_circle_outline,
            'Give your day direction',
            'Choose a task and take the next small step.',
            '/tasks',
            const Color(0xffb26b00),
          ),
          (
            Icons.auto_stories_outlined,
            'Pause and reflect',
            'Capture what worked and how you feel.',
            '/journal',
            const Color(0xff167d87),
          ),
        ])
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: CircleAvatar(
                backgroundColor: item.$5.withValues(alpha: .13),
                child: Icon(item.$1, color: item.$5),
              ),
              title: Text(
                item.$2,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(item.$3),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(item.$4),
            ),
          ),
      ],
    ),
  );
}
