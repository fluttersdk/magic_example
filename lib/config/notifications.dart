import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:magic/magic.dart';

/// Notifications configuration.
///
/// Wires `magic_notifications`' `NotificationServiceProvider`, which reads
/// only `notifications.*` (see its own docblock). An absent push driver or
/// app id is a supported build (push stays quiet, the database channel still
/// works), so both read through [env] with an empty-string fallback rather
/// than requiring a `.env` entry.
/// See: https://magic.fluttersdk.com/docs/notifications
Map<String, dynamic> get notificationsConfig => {
  'notifications': {
    'push': {
      // The only driver `magic_notifications` ships. Read through [env]
      // rather than hardcoded so a consumer that registers a driver of its
      // own with `Notify.extend` can select it without a code change here.
      'driver': env('NOTIFICATIONS_PUSH_DRIVER', 'onesignal'),

      // Public by design: the Web SDK needs this client-side to open its own
      // socket, and it carries no send capability. The OneSignal REST API
      // key that CAN send notifications is server-only and never belongs in
      // a bundled `.env`. Empty by default; a fork adds its own app id.
      'app_id': env('ONESIGNAL_APP_ID', ''),

      'notify_button_enabled': false,

      // ----------------------------------------------------------------------
      // The permission posture: ask once where a gesture already justifies it,
      // never spend the one-shot browser prompt on an unprompted page load.
      // ----------------------------------------------------------------------

      // Ask on login, but only where the ask is a dialog somebody expects.
      //
      // The package raises the OS request once per launch when an identity is
      // declared, and on mobile that is honest: a person signing in expects to
      // be asked, and the platform renders the dialog directly behind the
      // sign-in that explains what it is for.
      //
      // On the web the same call either does nothing or does harm. MDN's
      // "Using the Notifications API" guide: browsers disallow a permission
      // request that is not triggered by a user gesture, so an automatic
      // request at login either goes nowhere (Firefox, Safari) or shows a
      // system prompt the operator did not ask for (Chrome), and a dismissal
      // there pushes the origin toward being blocked outright. `denied` is a
      // state no code can recover, so this stays off on web and leans on the
      // in-app reminder below, whose button is a real gesture instead.
      'auto_request_on_login': !kIsWeb,

      // How often the in-app reminder may re-ask a device that declined.
      //
      // `0` and an absent key both mean NEVER, which is a real default rather
      // than a neutral one: a device that never gets asked again never comes
      // back. 20 rather than 24 walks the reminder across the day instead of
      // pinning it to the moment the user was already busy enough to decline.
      'reprompt_after_hours': 20,

      // Keep the route back on a device the OS prompt is spent on. Doubles as
      // `canOpenPlatformSettings`, turning a blocked permission into a control
      // on iOS and Android rather than a dead end.
      'fallback_to_settings': true,
    },
    'database': {
      'enabled': true,
      'polling_interval': 30, // seconds
    },
    'soft_prompt': {
      // The app's own reminder, and on the web the ONLY thing that ever asks:
      // `auto_request_on_login` is off there, so switching this off would mean
      // a browser is never asked for push at all.
      'enabled': true,
    },
  },
};
