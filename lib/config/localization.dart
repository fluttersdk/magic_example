import 'package:magic/magic.dart';

/// Localization configuration.
///
/// Wires `LocalizationServiceProvider`, which reads only `localization.*` (see
/// its own docblock). Without this file every key the provider reads falls
/// through to its built-in default of `en`, and `assets/lang/tr.json` is never
/// loaded even though `magic_starter.supported_locales` already lists `tr`
/// (see `lib/config/magic_starter.dart`); this file is what makes that list
/// true. See: https://magic.fluttersdk.com/docs/localization
Map<String, dynamic> get localizationConfig => {
  'localization': {
    /// The default locale for the application.
    'locale': env('APP_LOCALE', 'en'),

    /// The fallback locale when a translation is not found. magic's
    /// `Translator` REPLACES its sentence map on load rather than merging it
    /// with the fallback, so a partial `tr.json` would surface as raw keys
    /// (`profile.settings`) rather than English prose; `tr.json` is kept a
    /// complete mirror of `en.json`'s key set for exactly this reason.
    'fallback_locale': 'en',

    /// List of supported locales. Add a locale here only once its JSON file
    /// under `assets/lang/` covers every key `en.json` does; the translator's
    /// replace-not-merge behavior above makes a partial file worse than
    /// leaving the locale out.
    'supported_locales': ['en', 'tr'],

    /// Auto-detect locale from device/browser on app start.
    ///
    /// Off, deliberately, and not because auto-detection is wrong: a device
    /// set to a locale this boilerplate does not ship (`de_DE`, `fr_FR`) has
    /// no tested path here, and the translator's replace-not-merge sentence
    /// map is exactly the mechanism that turns an untested locale into raw
    /// keys on every screen. Flip this on once a fork's `supported_locales`
    /// covers every locale its users actually have.
    'auto_detect_locale': false,

    /// Path to translation JSON files, matching the `assets:` entry in
    /// `pubspec.yaml`.
    'path': 'assets/lang',

    /// Default IANA timezone for date operations, used when detection is
    /// disabled or fails.
    'timezone': 'UTC',

    /// Auto-detect timezone from device on app start. Magic reads the real
    /// platform IANA identifier (through `flutter_timezone`) and its
    /// `LocalizationServiceProvider` boots `DateManager` itself, so nothing
    /// needs feeding in by hand. When no valid zone resolves, the `timezone`
    /// above stays in effect rather than a guess.
    'auto_detect_timezone': true,

    /// Default date format pattern.
    'date_format': 'MMMM do yyyy',
  },
};
