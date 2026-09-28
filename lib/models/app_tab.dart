/// The order here is shared by the router branches and bottom navigation.
enum AppTab {
  today('Today', '/today'),
  levels('Levels', '/levels'),
  tasks('Tasks', '/tasks'),
  journal('Journal', '/journal'),
  more('More', '/more');

  const AppTab(this.label, this.path);

  final String label;
  final String path;
}
