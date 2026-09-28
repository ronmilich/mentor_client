import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../config/api_config.dart';
import '../../../data/repositories/levels_repository.dart';
import '../view_models/levels_view_models.dart';
import 'level_widgets.dart';

class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key, required this.repository});
  final LevelsRepository repository;

  @override
  Widget build(BuildContext context) => ViewModelBuilder<LevelsViewModel>(
    create: () => LevelsViewModel(repository, selectedUserId: ApiConfig.userId),
    load: (model) => model.load(),
    builder: (context, model) {
      Future<void> open(String path) async {
        await context.push(path);
        if (context.mounted) await model.load();
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Levels'),
          actions: [
            IconButton(
              tooltip: 'Refresh levels',
              onPressed: model.busy ? null : model.load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: model.selectedUserId.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: model.busy
                    ? null
                    : () =>
                          open('/levels/create?userId=${model.selectedUserId}'),
                icon: const Icon(Icons.add),
                label: const Text('Create level'),
              ),
        body: LoadState(
          model: model,
          retry: model.load,
          hasData: model.users.isNotEmpty || model.levels.isNotEmpty,
          child: RefreshIndicator(
            onRefresh: () async {
              await model.load();
            },
            child: ContentList(
              children: [
                Text(
                  'Build your next chapter',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Define what to do and what to avoid. Track each attempt, one day at a time.',
                ),
                const SizedBox(height: 24),
                if (model.users.isNotEmpty)
                  DropdownButtonFormField<String>(
                    key: ValueKey(model.selectedUserId),
                    initialValue:
                        model.users.any(
                          (user) => user.id == model.selectedUserId,
                        )
                        ? model.selectedUserId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Profile',
                      border: OutlineInputBorder(),
                    ),
                    items: model.users
                        .map(
                          (user) => DropdownMenuItem(
                            value: user.id,
                            child: Text(user.name),
                          ),
                        )
                        .toList(),
                    onChanged: model.busy
                        ? null
                        : (value) {
                            if (value != null) model.selectUser(value);
                          },
                  ),
                const SizedBox(height: 16),
                if (!model.busy &&
                    model.error == null &&
                    model.users.isEmpty &&
                    model.selectedUserId.isEmpty)
                  const EmptyMessage(
                    title: 'No profiles yet',
                    message: 'Create a user in the local backend to begin.',
                  ),
                if (!model.busy &&
                    model.error == null &&
                    model.selectedUserId.isEmpty &&
                    model.users.isNotEmpty)
                  const EmptyMessage(
                    title: 'Choose a profile',
                    message: 'Select whose levels you want to view.',
                  ),
                if (!model.busy &&
                    model.error == null &&
                    model.selectedUserId.isNotEmpty &&
                    model.levels.isEmpty)
                  const EmptyMessage(
                    title: 'Your first level starts here',
                    message: 'Tap Create level to set your daily requirements.',
                  ),
                for (final level in model.levels)
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(child: Text('${level.number}')),
                      title: Text(statusLabel(level.status)),
                      subtitle: Text(
                        'Day ${level.currentDayNumber} / ${level.attemptRequiredDays}'
                        ' · Attempt ${level.currentAttemptNumber} / ${level.maxFailedAttempts}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => open('/levels/${level.id}'),
                    ),
                  ),
                const SizedBox(height: 88),
              ],
            ),
          ),
        ),
      );
    },
  );
}
