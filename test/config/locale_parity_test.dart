import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the invariant that every shipped locale carries the SAME key set.
///
/// magic's `Translator` REPLACES its sentence map on load rather than merging
/// it with the fallback, so a key present in `en.json` and missing from
/// `tr.json` does not fall back to English: it renders the raw key path
/// (`magic_starter.titles.login`) on screen. That failure is silent at build
/// time and only visible by driving the app in the missing locale, which is
/// why it gets a test rather than a review habit.
///
/// The check is exact equality, not a subset, because the reverse direction is
/// just as wrong: a key only `tr.json` has is dead weight that no English
/// screen can ever reach, and it usually means a translation was copied from a
/// product app that has a feature this one does not.
void main() {
  Set<String> flatten(Map<String, dynamic> node, [String prefix = '']) {
    final Set<String> keys = <String>{};
    node.forEach((String key, dynamic value) {
      keys.add('$prefix$key');
      if (value is Map<String, dynamic>) {
        keys.addAll(flatten(value, '$prefix$key.'));
      }
    });
    return keys;
  }

  Set<String> keysOf(String locale) {
    final File file = File('assets/lang/$locale.json');
    return flatten(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
  }

  test('every supported locale carries the same key set as en', () {
    // Mirrors `localization.supported_locales` in lib/config/localization.dart.
    // Adding a locale there without adding it here leaves the new file
    // unguarded, which is the state this test exists to end.
    const List<String> locales = <String>['tr'];

    final Set<String> english = keysOf('en');
    expect(english, isNotEmpty, reason: 'assets/lang/en.json parsed empty');

    for (final String locale in locales) {
      final Set<String> translated = keysOf(locale);
      expect(
        translated.difference(english),
        isEmpty,
        reason: '$locale.json has keys en.json does not',
      );
      expect(
        english.difference(translated),
        isEmpty,
        reason: '$locale.json is missing keys, which render as raw key paths',
      );
    }
  });
}
