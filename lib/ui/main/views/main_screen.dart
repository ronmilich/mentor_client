import 'package:flutter/material.dart';

import '../../../models/app_tab.dart';
import '../view_models/main_view_model.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.viewModel, required this.child});

  final MainViewModel viewModel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: viewModel.selectedIndex,
          onDestinationSelected: viewModel.selectTab,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final tab in viewModel.tabs)
              NavigationDestination(
                key: ValueKey(tab),
                icon: Icon(_iconFor(tab)),
                selectedIcon: Icon(_iconFor(tab, selected: true)),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AppTab tab, {bool selected = false}) => switch (tab) {
    AppTab.today => selected ? Icons.today : Icons.today_outlined,
    AppTab.levels => selected ? Icons.layers : Icons.layers_outlined,
    AppTab.tasks => selected ? Icons.check_circle : Icons.check_circle_outline,
    AppTab.journal => selected ? Icons.book : Icons.book_outlined,
    AppTab.more => Icons.more_horiz,
  };
}
