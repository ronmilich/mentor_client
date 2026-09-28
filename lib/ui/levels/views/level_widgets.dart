import 'package:flutter/material.dart';

import '../view_models/levels_view_models.dart';

class ViewModelBuilder<T extends AsyncViewModel> extends StatefulWidget {
  const ViewModelBuilder({
    super.key,
    required this.create,
    required this.load,
    required this.builder,
  });
  final T Function() create;
  final Future<bool> Function(T) load;
  final Widget Function(BuildContext, T) builder;

  @override
  State<ViewModelBuilder<T>> createState() => _ViewModelBuilderState<T>();
}

class _ViewModelBuilderState<T extends AsyncViewModel>
    extends State<ViewModelBuilder<T>> {
  late final T model;
  @override
  void initState() {
    super.initState();
    model = widget.create();
    widget.load(model);
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => widget.builder(context, model),
  );
}

class LoadState extends StatelessWidget {
  const LoadState({
    super.key,
    required this.model,
    required this.retry,
    required this.child,
    this.hasData = true,
  });
  final AsyncViewModel model;
  final VoidCallback? retry;
  final Widget child;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    if (model.busy && !hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        if (model.busy) const LinearProgressIndicator(),
        if (model.error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  model.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                if (retry != null)
                  TextButton(
                    onPressed: model.busy ? null : retry,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}

class ContentList extends StatelessWidget {
  const ContentList({
    super.key,
    required this.children,
    this.keepChildrenMounted = false,
  });
  final List<Widget> children;

  /// Forms must validate every field, including those outside the viewport.
  final bool keepChildrenMounted;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: keepChildrenMounted
            ? [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ]
            : children,
      ),
    ),
  );
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        const Icon(Icons.layers_outlined, size: 48),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (action != null)
          Padding(padding: const EdgeInsets.only(top: 20), child: action!),
      ],
    ),
  );
}

String statusLabel(String value) => switch (value) {
  'IN_PROGRESS' => 'In progress',
  'COMPLETED' => 'Completed',
  'FAILED' => 'Failed',
  'ABANDONED' => 'Abandoned',
  'PENDING' => 'Pending',
  'PASSED' => 'Passed',
  _ => value,
};

String displayDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(statusLabel(status)),
    visualDensity: VisualDensity.compact,
  );
}

String? smallIntValidator(String? value, {int min = 1}) {
  final number = int.tryParse(value?.trim() ?? '');
  return number == null || number < min || number > 32767
      ? 'Enter a whole number from $min to 32767.'
      : null;
}
