import 'package:flutter/widgets.dart';

import '../resources/views/dashboard_view.dart';
import 'preview_mock_harness.dart';
import 'screen_preview_scaffold.dart';

/// Navigation preview: the authenticated app shell on its MOBILE layout, the
/// bottom navigation bar + drawer, rendered in a phone-width frame and wrapping
/// a sample screen.
class BottomMenuPreview extends StatelessWidget {
  /// Creates the bottom-menu navigation preview.
  const BottomMenuPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenPreviewScaffold(
      state: PreviewState.success,
      chrome: PreviewChrome.appMobile,
      builder: _build,
    );
  }

  static Widget _build(BuildContext context) => const DashboardView();
}
