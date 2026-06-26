import 'package:flutter/widgets.dart';

import 'preview_mock_harness.dart';

/// Shared scaffold for feature-screen previews.
///
/// Installs the [PreviewMockHarness] for the requested [state] (so the wrapped
/// controller-backed view renders backend-free), simulates a phone viewport so
/// the view renders its mobile layout, and DEFERS the view mount by one frame.
///
/// The deferral matters: the catalog builds a preview's body synchronously
/// inside its own `build()`. A magic_starter feature view is controller-backed
/// (`MagicStatefulView`), and binding its controller on mount notifies state
/// listeners; mounting it DURING the catalog build trips "setState() called
/// during build". Mounting it one frame later (after a post-frame callback)
/// moves the controller bind out of the build phase, so the preview is clean.
/// The placeholder shown for that single frame keeps the layout from jumping.
class ScreenPreviewScaffold extends StatefulWidget {
  /// Wraps [builder]'s output, installing the harness for [state] first.
  const ScreenPreviewScaffold({
    super.key,
    required this.state,
    required this.builder,
  });

  /// The state the harness should portray (success, loading, or error).
  final PreviewState state;

  /// Builds the feature view to preview.
  final WidgetBuilder builder;

  @override
  State<ScreenPreviewScaffold> createState() => _ScreenPreviewScaffoldState();
}

class _ScreenPreviewScaffoldState extends State<ScreenPreviewScaffold> {
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    // Bind the mock network + sample auth session for this state before the
    // view mounts. Idempotent per-state, so it does not churn the singleton.
    PreviewMockHarness.install(widget.state);
    // Mount the controller-backed view one frame later (see the class doc): it
    // must not build during the catalog's build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mounted = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Render the feature view at the catalog pane's natural width so it shows
    // its REAL responsive layout (the screen reflows with the browser, exactly
    // as in production). The catalog is a single full-width pane, so no
    // phone-frame / MediaQuery override is imposed; a vertical scroll keeps a
    // tall screen reachable.
    return SingleChildScrollView(
      // First frame: a sized placeholder so the column does not jump when the
      // deferred view mounts. Subsequent frames: the real view.
      child: _mounted
          ? Builder(builder: widget.builder)
          : const SizedBox(height: 320),
    );
  }
}
