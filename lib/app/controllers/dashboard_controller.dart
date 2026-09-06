import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart';

import '../models/user.dart';

/// State behind the dashboard's greeting: the display name of whoever is
/// currently authenticated.
///
/// **This is the first controller in the app, so it is the pattern the other
/// screens copy.** Its shape follows `depools`' `ProductController` and
/// `magic_starter`'s own controllers: a [MagicController] resolved once
/// through [Magic.findOrPut], and [MagicStateMixin] carrying loading/success
/// so [DashboardView] renders both from one source instead of jumping
/// straight to content.
///
/// ### Why a controller for a screen with no mutations
///
/// [DashboardView] greets the CURRENT identity, which makes it session-scoped
/// whether or not a backend sits behind it. `SessionScopeSync.attach()`
/// (`app_service_provider.dart:81`) resets every registered
/// [SessionScopedController] on login and team switch; before this class
/// nothing implemented the contract, so that call ran and had nothing to
/// reset. Without [resetForSession], a team switch would leave the previous
/// tenant's name on screen until the app restarted (see
/// [SessionScopedController]'s own docblock for why `onInit` alone cannot
/// catch this: it runs once per controller lifetime, not once per session).
///
/// ### What "loading" honestly represents here
///
/// This boilerplate ships no dashboard endpoint, so there is no network call
/// to await. The single `await` in [load] is not a `Future.delayed` standing
/// in for one: it is the same yield every other controller in this codebase
/// gets for free from its first `await Http.get(...)`, kept here so
/// [resetForSession]'s clear-then-refetch contract is real (the view actually
/// paints the cleared state before the refetch lands) rather than a same-tick
/// no-op indistinguishable from skipping the interface entirely. A fork
/// wiring a real fetch (a `/dashboard` summary, say) replaces the body of
/// [load] without touching [onInit] or [resetForSession].
class DashboardController extends MagicController
    with MagicStateMixin<String>
    implements SessionScopedController {
  /// The shared instance, resolved once and reused for the app's lifetime.
  static DashboardController get instance =>
      Magic.findOrPut(DashboardController.new);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Resolves the greeting name for the currently authenticated user.
  Future<void> load() async {
    setLoading();

    // The yield described in the class docblock above: there is no I/O to
    // await yet, only the framework-standard boundary a real fetch would
    // occupy.
    await Future<void>.value();

    final String? name = User.current.name;

    setSuccess(name != null && name.trim().isNotEmpty ? name : 'there');
  }

  /// Clears the previous session's greeting and resolves the new one.
  ///
  /// Called on login and team switch, never on logout (see
  /// [SessionScopedController.resetForSession]'s own contract: a logout only
  /// routes to the login screen, which never reads this controller). A plain
  /// [load] would leave the previous name on screen until the refetch
  /// resolves, which is exactly the wrong default across an identity change.
  @override
  Future<void> resetForSession() async {
    setState(null, status: const RxStatus.empty());
    await load();
  }
}
