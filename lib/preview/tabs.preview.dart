import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart' show WDiv, WText;
import 'package:magic_starter/magic_starter.dart' show Tabs;

/// Tabs preview: a live tab strip; tapping a tab swaps the panel.
class TabsPreview extends StatefulWidget {
  /// Creates the tabs preview.
  const TabsPreview({super.key});

  @override
  State<TabsPreview> createState() => _TabsPreviewState();
}

class _TabsPreviewState extends State<TabsPreview> {
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    return Tabs(
      tabs: const <String>['Overview', 'Members', 'Settings'],
      selectedIndex: _index,
      onChanged: (int i) => setState(() => _index = i),
      panelBuilder: (int index) => WDiv(
        className: 'p-4',
        child: WText('Panel ${index + 1}', className: 'text-fg text-sm'),
      ),
    );
  }
}
