import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';

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
  /// The simulated phone viewport for feature-screen previews.
  static const Size _phoneViewport = Size(390, 844);

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
    // Simulate a phone viewport. Wind resolves its responsive breakpoints
    // (sm:/md:/lg:) from MediaQuery.size.width (wind_helpers.dart), NOT the
    // local box constraints. Without this override a feature screen reads the
    // full browser width, renders its DESKTOP layout, and overflows the narrow
    // side-by-side pane. A phone-sized MediaQuery makes it render its MOBILE
    // layout, which fits the constrained width with no RenderFlex overflow.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(size: _phoneViewport),
      child: WDiv(
        className: 'w-full max-w-[390px] mx-auto',
        child: SingleChildScrollView(
          // First frame: a sized placeholder so the column does not jump when
          // the deferred view mounts. Subsequent frames: the real view.
          child: _mounted
              ? Builder(builder: widget.builder)
              : const SizedBox(height: 320),
        ),
      ),
    );
  }
}
