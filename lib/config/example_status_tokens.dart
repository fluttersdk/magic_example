/// Status-vocabulary tokens `design:sync` does not emit, merged into
/// `WindThemeData`'s alias map alongside `supplementAliases` in
/// `wind_theme.dart`.
///
/// DESIGN.md's "Custom token families (supplement)" section documents this
/// exact mechanism: `design:sync` emits `bg-success` and `bg-warning` from
/// its `colors` block, but no `info` role at all and no `text-on-*` foreground
/// for either `success` or `warning` (compare `bg-destructive`, which DOES get
/// a `text-on-destructive` peer). Those gaps are hand-authored here, in the
/// same `'<light> dark:<dark>'` className-string shape as `supplementAliases`,
/// and merged in `lib/main.dart` rather than regenerated.
const Map<String, String> exampleStatusAliases = <String, String>{
  // bg-info: an informational tone. DESIGN.md's `colors` block defines no
  // `info` role at all, so `design:sync` has nothing to emit for it. Sky
  // blue, distinct from both the violet brand and the indigo accent so an
  // info banner does not read as a brand action.
  'bg-info': 'bg-[#0284C7] dark:bg-[#0EA5E9]',

  // text-on-info: the foreground that sits ON the solid `bg-info` fill, the
  // same role `text-on-primary`/`text-on-destructive` carry for their own
  // backgrounds. White in both modes: the solid tone is dark enough at both
  // hexes for white text to clear WCAG AA.
  'text-on-info': 'text-[#FFFFFF] dark:text-[#FFFFFF]',

  // text-on-success: `design:sync` emits `bg-success` but no foreground peer
  // for it (unlike `bg-destructive`, which gets `text-on-destructive`). White
  // clears AA against both success hexes.
  'text-on-success': 'text-[#FFFFFF] dark:text-[#FFFFFF]',

  // text-on-warning: same gap as `success` above, but with a dark foreground
  // rather than white: amber is too light for white text to clear AA the way
  // the darker info/success/destructive tones do.
  'text-on-warning': 'text-[#111827] dark:text-[#111827]',
};
