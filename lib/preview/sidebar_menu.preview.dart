import 'package:flutter/widgets.dart';

import '../resources/views/dashboard_view.dart';
import 'preview_mock_harness.dart';
import 'screen_preview_scaffold.dart';

/// Navigation preview: the authenticated app shell on its DESKTOP layout, the
/// sidebar navigation rail + header + user menu, wrapping a sample screen.
class SidebarMenuPreview extends StatelessWidget {
  /// Creates the sidebar-menu navigation preview.
  const SidebarMenuPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPreviewScaffold(
      state: PreviewState.success,
      chrome: PreviewChrome.appDesktop,
      builder: _build,
    );
  }

  static Widget _build(BuildContext context) => const DashboardView();
}
