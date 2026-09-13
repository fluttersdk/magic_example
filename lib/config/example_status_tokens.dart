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
/// and merged in `lib/config/wind_theme.dart` (not `lib/main.dart`, so the
/// token guard in `test/config/` can ask the same theme the app runs on).
///
/// ### Every foreground here flips by mode, and that is not a style choice
///
/// The generated fills do not keep a constant lightness across modes:
/// `bg-success` goes `#15803D` light to the LIGHTER `#16A34A` dark, while
/// `bg-warning` goes `#D97706` light to the DARKER `#B45309` dark. So the
/// foreground that clears WCAG AA (4.5:1 for normal text) is white on one side
/// and near-black on the other, in opposite directions for the two roles. A
/// single foreground for both modes fails AA on one of them every time, which
/// is what the first version of this file shipped: white on `#16A34A` measures
/// 3.30 and near-black on `#B45309` measures 3.53.
///
/// Measured ratios, all against the fills actually in play:
///
///     text-on-info     #FFFFFF on #0369A1  5.93   #111827 on #0EA5E9  6.40
///     text-on-success  #FFFFFF on #15803D  5.02   #111827 on #16A34A  5.38
///     text-on-warning  #111827 on #D97706  5.57   #FFFFFF on #B45309  5.02
///
/// Recompute these before changing any hex here or any `success`/`warning`
/// entry in DESIGN.md; the two files are coupled through these pairs and
/// `design:sync` regenerates one of them. See
/// `docs/design-culture/accessibility-wcag.md`.
const Map<String, String> exampleStatusAliases = <String, String>{
  // bg-info: an informational tone. DESIGN.md's `colors` block defines no
  // `info` role at all, so `design:sync` has nothing to emit for it. Sky blue,
  // distinct from both the violet brand and the indigo accent so an info
  // banner does not read as a brand action. The light fill is sky-700 rather
  // than sky-600 because white on sky-600 measures 4.10 and misses AA.
  'bg-info': 'bg-[#0369A1] dark:bg-[#0EA5E9]',

  // text-on-info: the foreground that sits ON the solid `bg-info` fill, the
  // same role `text-on-primary`/`text-on-destructive` carry for their own
  // backgrounds. White on the dark light-mode fill, near-black on the lighter
  // dark-mode one.
  'text-on-info': 'text-[#FFFFFF] dark:text-[#111827]',

  // text-on-success: `design:sync` emits `bg-success` but no foreground peer
  // for it (unlike `bg-destructive`, which gets `text-on-destructive`). The
  // dark-mode fill `#16A34A` is the LIGHTER of the two, so it takes the dark
  // foreground.
  'text-on-success': 'text-[#FFFFFF] dark:text-[#111827]',

  // text-on-warning: the same gap as `success`, flipped. Amber `#D97706` is
  // too light for white, and the dark-mode `#B45309` is dark enough that white
  // is the only one of the two that clears AA there.
  'text-on-warning': 'text-[#111827] dark:text-[#FFFFFF]',
};
