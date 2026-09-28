import '../../../models/app_tab.dart';

/// A snapshot of router state and the commands exposed to the main view.
///
/// The router remains the source of truth for selection, including deep links.
/// Each router update supplies a new snapshot; no duplicate state is stored.
class MainViewModel {
  const MainViewModel({required this.selectedIndex, required this.onSelectTab});

  final int selectedIndex;
  final void Function(int index) onSelectTab;

  List<AppTab> get tabs => AppTab.values;

  void selectTab(int index) {
    RangeError.checkValidIndex(index, tabs);
    if (index != selectedIndex) {
      onSelectTab(index);
    }
  }
}
