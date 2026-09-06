# magic_example

The batteries-included reference app for the `fluttersdk` `magic` ecosystem: a
working Flutter application built on `magic`, `magic_starter`, and the
Wind design-first component system, meant to be forked into a new product
rather than read as a tutorial.

The committed `pubspec.yaml` is a clean hosted dependency set: every sibling
package (`magic`, `magic_deeplink`, `magic_notifications`, `magic_social_auth`,
`magic_starter`, `magic_devtools`, `fluttersdk_dusk`, `fluttersdk_telescope`,
`fluttersdk_artisan`) is a normal `^` caret constraint pointing at pub.dev, not
a path dependency. That is deliberate: a fork copied outside this workspace
must resolve on its own. Local, in-workspace development instead uses the
gitignored `pubspec_overrides.yaml`, which redirects those same packages to
the sibling checkouts under `../magic`, `../magic_starter`, and so on; it
never ships and is not part of the fork.

## Forking this app

Run the rename command first, it rewrites every platform identity site the
app carries. Then finish the handful of things it deliberately leaves for you.

### 1. Rename the app

    dart run bin/dispatcher.dart app:rename --name=<snake_case> --org=<reverse.dns> --display="<Display Name>"

Add `--dry-run` first to list every file it would touch without writing
anything. It refuses to run while writing against a dirty worktree, and
running it twice with the same arguments is a no-op.

It owns every identity site measured in this app: the Dart package name and
every `import 'package:magic_example/...'` site under `lib/`, `test/` and
`bin/`; the Android namespace,
`applicationId`, display name, and the Kotlin package directory move
(`android/app/src/main/kotlin/com/fluttersdk/magic_example/` moves to the new
package path); the iOS bundle identifier and display name in `project.pbxproj`
and `Info.plist`; the macOS bundle identifier and display name across
`AppInfo.xcconfig`, `project.pbxproj`, and `Runner.xcscheme`, plus the
`TEST_HOST` the macOS `RunnerTests` target launches against (macOS's own
`Info.plist` needs no edit, it reads `$(PRODUCT_BUNDLE_IDENTIFIER)` and
`$(PRODUCT_NAME)`; three product-reference labels in
`macos/.../project.pbxproj` keep the old name and are cosmetic, Xcode
regenerates them); the Windows `CMakeLists.txt`, `Runner.rc`, and `main.cpp`;
the Linux `CMakeLists.txt` and `my_application.cc`; the web `manifest.json`
and `index.html` title; the `APP_NAME` key in `.env` (not its values, see step
2); `lib/main.dart`; the app name reference in `DESIGN.md` (not its tokens,
see step 4); and `.github/dependabot.yml`.

### 2. Edit `.env` values

`app:rename` only rewrites the `APP_NAME` key; it does not touch `API_URL` or
any other value. Point `API_URL` at the new backend, then run
`dart run bin/dispatcher.dart key:generate` if the app uses the `Crypt` facade. `.env` is COMMITTED
here and bundled as a Flutter asset in `pubspec.yaml`, which is deliberate on
both counts: `flutter_dotenv` can only load it on web when it is a bundled
asset, and a bundled asset that does not exist fails `flutter build`, so
gitignoring it would make every fresh clone of this template unbuildable. It
holds public client values only. A Flutter bundle ships to every user's
device and can be read out of it, so real secrets belong on the backend,
never here. `.env.example` stays as the key list.

### 3. Replace the launcher icons

`app:rename` does not generate icons. Replace them under
`android/app/src/main/res/mipmap-*` and
`ios/Runner/Assets.xcassets/AppIcon.appiconset/`.

### 4. Edit `DESIGN.md`, then regenerate the theme

`app:rename` only updates the app name reference in `DESIGN.md`; it does not
touch the design tokens. Edit the colors, typography, spacing, and radii,
then run `dart run bin/dispatcher.dart design:sync`. This rewrites
`lib/config/wind_theme.g.dart`; never hand-edit that file.

### 5. Delete `pubspec_overrides.yaml`

It exists only to wire this app to sibling packages under active development
inside the `fluttersdk` workspace; a fork living outside that workspace has no
sibling checkouts to point at and must resolve every `magic` package from
pub.dev via the plain `pubspec.yaml` constraints. Deleting it (it is
gitignored, so it was never committed) is what makes `flutter pub get`
resolve purely hosted. `bin/check` guards that file for the workspace case, so
once it is gone run the gate as `CHECK_ALLOW_HOSTED=1 bin/check`, which is the
supported way to say "hosted is what I meant".

### 6. Refresh the preview catalog

`dart run bin/dispatcher.dart previews:refresh`.

After these steps, `flutter pub get` should resolve against pub.dev alone,
`flutter analyze` and `flutter test` should stay clean, and `/preview` in a
debug build should reflect the new `DESIGN.md`.

## Running it

- `flutter run -d chrome`, or drive it through `fluttersdk_dusk` for
  agent/CI-style E2E.
- Component and design tooling runs through `bin/dispatcher.dart`: `make:component`,
  `design:sync`, `design:lint`, `previews:refresh`. See `CLAUDE.md` for the
  full command list and `.claude/rules/design.md` for the component contract.

## Learn more about Flutter

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
