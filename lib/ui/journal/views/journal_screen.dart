import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/productivity_repository.dart';
import '../../../models/level.dart';
import '../../core/app_theme.dart';
import '../../core/sign_in_gate.dart';
import '../../levels/views/level_widgets.dart';
import 'journal_calendar.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key, required this.repository});
  final ProductivityRepository repository;
  @override
  Widget build(BuildContext context) => SignInGate(
    repository: repository,
    title: 'Journal',
    child: JournalEditor(repository: repository),
  );
}

class JournalEditor extends StatefulWidget {
  const JournalEditor({super.key, required this.repository});
  final ProductivityRepository repository;
  @override
  State<JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends State<JournalEditor> {
  static const sections = {
    'wins': 'Wins',
    'obstacles': 'Obstacles',
    'boosters': 'Boosters',
    'conclusions': 'Conclusions',
  };
  static const metrics = {
    'mood': 'Mood',
    'energy': 'Energy',
    'stress': 'Stress',
    'focus': 'Focus',
    'sleepQuality': 'Sleep quality',
  };
  final controllers = {
    for (final key in ['text', ...sections.keys]) key: TextEditingController(),
  };
  final changes = <String, dynamic>{};
  Json values = {};
  Json? entry;
  DateTime date = DateUtils.dateOnly(DateTime.now());
  bool full = false, busy = true, loaded = false;
  String? error, draftError;
  late final String owner = widget.repository.userId!;
  Future<void> draftWrites = Future.value();
  String get dateKey => calendarDate(date);
  String get storageKey => 'journal-draft:$owner:$dateKey';
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void changed(String key, dynamic value) {
    setState(() {
      changes[key] = value;
      values[key] = value;
    });
    final keyToSave = storageKey, snapshot = jsonEncode(changes);
    draftWrites = draftWrites
        .then((_) async {
          final prefs = await SharedPreferences.getInstance();
          final ok = await prefs.setString(keyToSave, snapshot);
          if (!ok) throw StateError('Draft not stored');
        })
        .catchError((Object _) {
          if (mounted) {
            setState(
              () => draftError =
                  'Local draft could not be stored. Save before leaving.',
            );
          }
        });
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      loaded = false;
      error = null;
    });
    String? draft;
    try {
      await draftWrites;
      final prefs = await SharedPreferences.getInstance();
      draft = prefs.getString(storageKey);
      final saved = await widget.repository.journal(dateKey);
      if (!mounted) return;
      changes.clear();
      if (draft != null) changes.addAll(jsonDecode(draft) as Json);
      entry = saved;
      values = {...?saved, ...changes};
      for (final field in controllers.entries) {
        field.value.text = values[field.key] as String? ?? '';
      }
      loaded = true;
    } catch (e) {
      if (mounted) {
        error = e.toString();
        if (draft != null) {
          changes.clear();
          changes.addAll(jsonDecode(draft) as Json);
          entry = null;
          values = Map.of(changes);
          for (final field in controllers.entries) {
            field.value.text = values[field.key] as String? ?? '';
          }
          loaded = true;
        }
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final saved =
          await widget.repository.request(
                'PATCH',
                '/journals/$dateKey',
                body: Map.of(changes),
              )
              as Json;
      await draftWrites;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(storageKey);
      if (!mounted) return;
      setState(() {
        entry = saved;
        changes.clear();
        draftError = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Journal saved')));
    } catch (e) {
      if (mounted) error = e.toString();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> selectDate([DateTime? chosen]) async {
    final next =
        chosen ??
        await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
    if (next == null || !mounted || next == date) return;
    await draftWrites;
    if (!mounted) return;
    setState(() => date = DateUtils.dateOnly(next));
    await load();
  }

  Future<void> history() async {
    final selected = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (_) => SessionPage(
          repository: widget.repository,
          child: JournalHistory(repository: widget.repository),
        ),
      ),
    );
    if (selected != null && mounted) await selectDate(selected);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Journal'),
      actions: [
        IconButton(
          tooltip: 'Journal history',
          onPressed: busy ? null : history,
          icon: const Icon(Icons.history),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: busy ? null : widget.repository.signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: ContentList(
      keepChildrenMounted: true,
      children: [
        const FeatureBanner(
          title: 'Make space for yourself.',
          subtitle: 'Notice the wins. Learn from the hard parts.',
          icon: Icons.auto_stories_outlined,
          color: Color(0xff167d87),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : () => selectDate(),
          icon: const Icon(Icons.calendar_month),
          label: Text(MaterialLocalizations.of(context).formatFullDate(date)),
        ),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Quick reflection')),
            ButtonSegment(value: true, label: Text('Full journal')),
          ],
          selected: {full},
          onSelectionChanged: (v) => setState(() => full = v.single),
        ),
        const SizedBox(height: 20),
        if (busy) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                if (!loaded)
                  TextButton(
                    onPressed: busy ? null : load,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        if (loaded)
          AbsorbPointer(
            absorbing: busy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (full)
                  TextField(
                    controller: controllers['text'],
                    minLines: 12,
                    maxLines: 24,
                    maxLength: 100000,
                    decoration: const InputDecoration(
                      labelText: 'Your journal',
                      hintText: 'Today I noticed that…',
                      alignLabelWithHint: true,
                    ),
                    onChanged: (v) => changed('text', v),
                  )
                else ...[
                  for (final metric in metrics.entries)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metric.value,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                for (var rating = 1; rating <= 5; rating++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: Semantics(
                                        label: '${metric.value} $rating of 5',
                                        selected: values[metric.key] == rating,
                                        child: ChoiceChip(
                                          label: Text('$rating'),
                                          padding: EdgeInsets.zero,
                                          showCheckmark: false,
                                          selected:
                                              values[metric.key] == rating,
                                          onSelected: (selected) => changed(
                                            metric.key,
                                            selected ? rating : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              metric.key == 'stress'
                                  ? '1 · Low stress / 5 · High stress'
                                  : '1 · Low / 5 · High',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  for (final field in sections.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: controllers[field.key],
                        minLines: 2,
                        maxLines: 5,
                        maxLength: 20000,
                        decoration: InputDecoration(
                          labelText: field.value,
                          hintText: 'Optional',
                          counterText: '',
                        ),
                        onChanged: (v) =>
                            changed(field.key, v.isEmpty ? null : v),
                      ),
                    ),
                ],
                if (entry?['isEdited'] == true) const Text('Edited entry'),
                if (entry?['editedAfterSubmission'] == true)
                  const Text('Edited after daily submission'),
                if (entry?['levelDayId'] != null)
                  const Text('Connected to your level day'),
                if (entry?['updatedAt'] != null)
                  Text(
                    'Last saved: ${DateTime.parse(entry!['updatedAt'] as String).toLocal()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (changes.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Unsaved changes · draft kept on this device'),
                  ),
                if (draftError != null)
                  Text(
                    draftError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: busy || changes.isEmpty ? null : save,
                  icon: const Icon(Icons.check),
                  label: Text(
                    busy
                        ? 'Saving…'
                        : full
                        ? 'Save journal'
                        : 'Save reflection',
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 32),
      ],
    ),
  );
}

class JournalHistory extends StatefulWidget {
  const JournalHistory({super.key, required this.repository});
  final ProductivityRepository repository;
  @override
  State<JournalHistory> createState() => _JournalHistoryState();
}

class _JournalHistoryState extends State<JournalHistory> {
  late Future<List<Json>> entries = widget.repository.all('/journals');
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Journal history')),
    body: FutureBuilder<List<Json>>(
      future: entries,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${snapshot.error}'),
                TextButton(
                  onPressed: () => setState(
                    () => entries = widget.repository.all('/journals'),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return ContentList(
          children: [
            JournalCalendar(
              dates: data.map((e) => e['date'] as String).toSet(),
              onSelected: (date) => Navigator.pop(context, date),
            ),
            Text(
              'Recent entries · ${data.length}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (data.isEmpty)
              const EmptyMessage(
                title: 'Your story starts here',
                message: 'Save a reflection to see it in your history.',
              ),
            for (final entry in data)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: Text(entry['date'] as String),
                  subtitle: Text(
                    'Mood ${entry['mood'] ?? '—'} · Energy ${entry['energy'] ?? '—'}\n${entry['text'] == '' ? entry['wins'] ?? 'Daily reflection' : entry['text'] ?? 'Daily reflection'}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(
                    context,
                    DateTime.parse(entry['date'] as String),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
