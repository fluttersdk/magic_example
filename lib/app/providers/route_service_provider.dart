import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:magic/magic.dart';
import 'package:magic_devtools/preview.dart';

import '../kernel.dart';
import '../../routes/app.dart';
import '../../preview/_previews.g.dart';
import 'package:magic_starter/magic_starter.dart';

/// Route Service Provider.
///
/// Registers the HTTP kernel and application routes.
class RouteServiceProvider extends ServiceProvider {
  RouteServiceProvider(super.app);

  @override
  void register() {
    // Register middleware kernel — runs synchronously during bootstrap.
    registerKernel();
  }

  @override
  Future<void> boot() async {
    // Register application route definitions.
    registerMagicStarterAuthRoutes();
    registerMagicStarterProfileRoutes();
    registerMagicStarterTeamRoutes();
    registerAppRoutes();

    // Dev-only component preview catalog. Registered here, in boot(), so it
    // lands BEFORE MagicRouter first builds its routerConfig (the router locks
    // its route table on first access). The kDebugMode guard lets the optimizer
    // prove the whole catalog dead in release; registerRoutes() folds itself
    // out behind kReleaseMode + PREVIEW_ENABLED as a second line of defence.
    if (kDebugMode) {
      MagicPreview.register(previewEntries());
      MagicPreview.registerRoutes();
    }
  }
}
