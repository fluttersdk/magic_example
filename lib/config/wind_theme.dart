import 'package:magic/magic.dart';

import 'wind_theme.g.dart';

/// The app's Wind theme, assembled in ONE place.
///
/// A function rather than a `WindThemeData` built inline in `main()`, so that
/// anything which needs to ask the theme a question can get the same answer the
/// running app gets. The token guard in `test/config/` is the reason it exists:
/// a test cannot call `main()` to find out which aliases resolve, and a second
/// copy of the assembly would drift from this one and certify the wrong map.
///
/// Everything here comes from `wind_theme.g.dart`, which `design:sync`
/// regenerates from DESIGN.md. Hand-authored supplements, when a project needs
/// tokens `design:sync` does not emit, belong in their own file and are merged
/// in here rather than in `main()`.
WindThemeData buildWindTheme() {
  return WindThemeData(
    colors: designColors,
    aliases: <String, String>{...designAliases, ...supplementAliases},
  );
}

/// Tokens `design:sync` does not emit, hand-authored and merged above.
///
/// Kept beside the generated map rather than inside it, because `design:sync`
/// overwrites `wind_theme.g.dart` wholesale: anything added there is lost on
/// the next regeneration, silently, in a file nobody re-reads.
///
/// Every entry needs a REASON, and the reason is always the same shape: a role
/// DESIGN.md defines, in a prefix the generator does not produce for it. Wind
/// resolves an unknown token to nothing without complaining, so the absence
/// shows up as a colour that never appears rather than as an error.
const Map<String, String> supplementAliases = <String, String>{
  // text-destructive: the destructive role as a FOREGROUND. `design:sync` emits
  // `bg-destructive` and `text-on-destructive` (the colour that sits ON the
  // solid), but no `text-` peer, so a destructive-coloured glyph or line of
  // text resolved to nothing and rendered in the inherited colour. Same hexes
  // as `bg-destructive`, which is what the role means.
  'text-destructive': 'text-[#DC2626] dark:text-[#EF4444]',
};
