import 'dart:io';

import 'package:fluttersdk_artisan/artisan.dart';

/// `app:rename` rewrites this app's identity across every platform folder.
///
/// A fork of this boilerplate carries three identity facets, each spread over a
/// different file format: the Dart package name (`magic_example`), the reverse
/// DNS organisation prefix (`com.fluttersdk`) and the human display name
/// (`Magic Example`). Doing that by hand means a Gradle Kotlin DSL string, an
/// Xcode build setting, a Windows resource file, two CMake `set()` calls, a
/// Linux C constant, a JSON manifest, an HTML meta tag and a Kotlin package
/// DIRECTORY, which is why the published `rename` and `package_rename` packages
/// do not cover it: neither rewrites Dart `package:` imports.
///
/// Every rewrite is anchored on the setting name rather than on a bare search
/// and replace, so the command is idempotent: a second run with the same
/// arguments recomputes the same value and changes nothing.
class AppRenameCommand extends ArtisanCommand {
  /// [root] is the project directory to operate on. It defaults to the process
  /// working directory, which is the project root under
  /// `dart run bin/dispatcher.dart`; tests pass a fixture directory instead.
  AppRenameCommand({Directory? root}) : _root = root ?? Directory.current;

  final Directory _root;

  /// Dart package names: a lowercase identifier. Enforced BEFORE any path is
  /// built, because this value becomes the last segment of the Kotlin package
  /// directory and an unchecked `../..` there escapes the project.
  static final RegExp _namePattern = RegExp(r'^[a-z][a-z0-9_]*$');

  /// Reverse DNS with at least two segments, each starting with a letter. Same
  /// reason as [_namePattern]: every segment becomes a directory level under
  /// `android/app/src/main/kotlin/`.
  static final RegExp _orgPattern = RegExp(
    r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$',
  );

  /// The display name lands inside XML attributes, a JSON string, an HTML
  /// title, three C string literals and a single-quoted Dart literal. The
  /// rejected characters are exactly the ones that would break out of one of
  /// those quoting contexts.
  /// `#` and a tab are here for a different reason than the quoting
  /// metacharacters: they do not break a literal, they get EATEN. The display
  /// name is written unquoted into `.env`, and `flutter_dotenv` strips
  /// `#[^'"]*$` as a trailing comment, so `--display="Acme #1"` leaves the
  /// running app reading `Acme` while this command's own re-read of `.env`
  /// still sees the whole string, which breaks idempotency silently. A tab
  /// does the same to the JSON string in `web/manifest.json`.
  static final RegExp _displayPattern = RegExp(r'''^[^"'\\<>&$#\t\r\n]+$''');

  @override
  String get signature =>
      'app:rename {--name= : New Dart package name, e.g. acme_app} '
      '{--org= : New reverse DNS prefix, e.g. com.acme} '
      '{--display= : New human display name, e.g. Acme App} '
      '{--dry-run : List every change and write nothing}';

  @override
  String get description =>
      'Rewrite the app identity (package name, bundle id, display name) '
      'across every platform.';

  @override
  CommandBoot get boot => CommandBoot.none;

  @override
  Future<int> handle(ArtisanContext ctx) async {
    final bool dryRun = ctx.input.option('dry-run') == true;

    // 1. Validate the requested values before anything reads or builds a path.
    final String? name = _stringOption(ctx, 'name');
    final String? org = _stringOption(ctx, 'org');
    final String? display = _stringOption(ctx, 'display');

    if (name == null && org == null && display == null) {
      ctx.output.error(
        'app:rename needs at least one of --name, --org or --display.',
      );
      return 1;
    }
    if (name != null && !_namePattern.hasMatch(name)) {
      ctx.output.error(
        'app:rename refused --name="$name": it must match '
        '${_namePattern.pattern} (a lowercase Dart package identifier). '
        'This value becomes a Kotlin package directory.',
      );
      return 1;
    }
    if (org != null && !_orgPattern.hasMatch(org)) {
      ctx.output.error(
        'app:rename refused --org="$org": it must match ${_orgPattern.pattern} '
        '(reverse DNS, at least two dot-separated lowercase segments). '
        'Every segment becomes a Kotlin package directory level.',
      );
      return 1;
    }
    if (display != null && !_displayPattern.hasMatch(display)) {
      ctx.output.error(
        'app:rename refused --display="$display": it may not contain any of '
        r'''" ' \ < > & $ '''
        'or a line break, because it is written into XML, JSON, HTML, C and '
        'Dart string literals.',
      );
      return 1;
    }

    // 2. Read the identity the tree currently carries. Deriving it instead of
    //    hardcoding `magic_example` is what lets the command run a second time
    //    on an already-renamed fork.
    final _Identity? current = _readCurrentIdentity(ctx);
    if (current == null) return 1;

    // The CURRENT identity is read out of the tree, so it is no more trusted
    // than the flags above: it reaches `kotlinPath`, and from there a read, a
    // write and a `deleteSync(recursive: true)`. `org` survives a hostile value
    // because `kotlinPath` splits it on `.`, but `package` is appended whole,
    // so a `pubspec.yaml` carrying `name: ../../../tmp/x` with a matching
    // gradle namespace would build a move endpoint outside the project. Held to
    // the same patterns rather than trusted for having come off disk.
    if (!_namePattern.hasMatch(current.package)) {
      ctx.output.error(
        'app:rename refused the package name it read from pubspec.yaml '
        '("${current.package}"): it must match ${_namePattern.pattern}. '
        'This value becomes a Kotlin package directory.',
      );
      return 1;
    }
    if (!_orgPattern.hasMatch(current.org)) {
      ctx.output.error(
        'app:rename refused the org it read from android/app/build.gradle.kts '
        '("${current.org}"): it must match ${_orgPattern.pattern}. '
        'Every segment becomes a Kotlin package directory level.',
      );
      return 1;
    }

    final target = _Identity(
      package: name ?? current.package,
      org: org ?? current.org,
      display: display ?? current.display,
    );

    // 3. Refuse a dirty worktree, but only when actually writing. A dry run has
    //    to stay usable in the middle of unrelated work.
    if (!dryRun) {
      final String? dirty = _dirtyWorktreeReason();
      if (dirty != null) {
        ctx.output.error(
          'app:rename refused to write: $dirty\n'
          'This command rewrites files across every platform folder and moves '
          'a Kotlin package directory; git is the only undo. Commit or stash '
          'first, or pass --dry-run.',
        );
        return 1;
      }
    }

    // 4. Build the whole plan before touching anything, so a dry run and a real
    //    run report from the same data.
    final plan = _buildPlan(current, target);

    _report(ctx, current, target, plan, dryRun: dryRun);

    if (dryRun) return 0;

    _apply(ctx, plan);
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Reading the current identity
  // ---------------------------------------------------------------------------

  /// Derives the identity from three anchored sites. Returns null and reports
  /// on stderr when the tree does not carry one; a partial guess here would
  /// silently produce a half-renamed project.
  _Identity? _readCurrentIdentity(ArtisanContext ctx) {
    final pubspec = _read('pubspec.yaml');
    if (pubspec == null) {
      ctx.output.error(
        'app:rename found no pubspec.yaml under ${_root.path}. '
        'Run it from the project root.',
      );
      return null;
    }
    final packageMatch = RegExp(
      r'^name:\s*(\S+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);
    if (packageMatch == null) {
      ctx.output.error('app:rename found no `name:` line in pubspec.yaml.');
      return null;
    }
    final package = packageMatch.group(1)!;

    final gradle = _read('android/app/build.gradle.kts');
    if (gradle == null) {
      ctx.output.error(
        'app:rename found no android/app/build.gradle.kts; it is the source '
        'for the current organisation prefix.',
      );
      return null;
    }
    final namespaceMatch = RegExp(
      r'^\s*namespace = "([^"]*)"\s*$',
      multiLine: true,
    ).firstMatch(gradle);
    if (namespaceMatch == null) {
      ctx.output.error(
        'app:rename found no `namespace = "..."` in '
        'android/app/build.gradle.kts.',
      );
      return null;
    }
    final namespace = namespaceMatch.group(1)!;
    if (!namespace.endsWith('.$package')) {
      ctx.output.error(
        'app:rename refused: the Android namespace "$namespace" does not end '
        'in ".$package", so the organisation prefix cannot be separated from '
        'the package name. Align android/app/build.gradle.kts with '
        'pubspec.yaml first.',
      );
      return null;
    }
    final org = namespace.substring(0, namespace.length - package.length - 1);

    // The display name is read from .env rather than DESIGN.md because .env is
    // the value the running app reads through `Config.get('app.name')`, and
    // pubspec.yaml declares it as a bundled asset so it is always present.
    final env = _read('.env');
    if (env == null) {
      ctx.output.error(
        'app:rename found no .env; APP_NAME there is the current display name.',
      );
      return null;
    }
    final displayMatch = RegExp(
      r'^APP_NAME=(.*)$',
      multiLine: true,
    ).firstMatch(env);
    if (displayMatch == null) {
      ctx.output.error('app:rename found no `APP_NAME=` line in .env.');
      return null;
    }

    return _Identity(
      package: package,
      org: org,
      display: displayMatch.group(1)!.trim(),
    );
  }

  // ---------------------------------------------------------------------------
  // The dirty-worktree guard
  // ---------------------------------------------------------------------------

  /// Returns a human reason when the tree holds changes a rename would bury,
  /// or null when writing is safe.
  String? _dirtyWorktreeReason() {
    final probe = Process.runSync('git', const [
      'rev-parse',
      '--is-inside-work-tree',
    ], workingDirectory: _root.path);
    // Not a git worktree at all: there is nothing for the guard to protect.
    if (probe.exitCode != 0) return null;

    final status = Process.runSync('git', const [
      'status',
      '--porcelain',
    ], workingDirectory: _root.path);
    if (status.exitCode != 0) {
      return 'git status failed (${status.stderr.toString().trim()}).';
    }

    final blocking = <String>[];
    for (final line in status.stdout.toString().split('\n')) {
      if (line.trim().isEmpty) continue;
      final code = line.substring(0, 2);
      final path = line.substring(3).trim();
      // Untracked files are not at risk: nothing this command writes replaces
      // them, and git can still restore everything it tracks.
      if (code == '??') continue;
      // pubspec.lock is tracked here and PERMANENTLY dirty by design: the index
      // holds the hosted-only resolution while a local `flutter pub get`
      // rewrites the working copy with sibling paths. Blocking on it would make
      // the command unusable in this workspace.
      if (path == 'pubspec.lock') continue;
      blocking.add(line);
    }
    if (blocking.isEmpty) return null;

    return 'the worktree has ${blocking.length} uncommitted change(s):\n'
        '${blocking.join('\n')}';
  }

  // ---------------------------------------------------------------------------
  // Planning
  // ---------------------------------------------------------------------------

  _RenamePlan _buildPlan(_Identity from, _Identity to) {
    final changed = <_PlannedFile>[];
    final unchanged = <String>[];
    final absent = <String>[];

    for (final rewrite in [
      ..._identityRewrites(from, to),
      ..._dartImportRewrites(from, to),
    ]) {
      final source = _read(rewrite.path);
      if (source == null) {
        absent.add(rewrite.path);
        continue;
      }
      var updated = source;
      for (final rule in rewrite.rules) {
        updated = updated.replaceAllMapped(rule.pattern, rule.replace);
      }
      if (updated == source) {
        unchanged.add(rewrite.path);
        continue;
      }
      changed.add(
        _PlannedFile(rewrite.path, updated, _changedLines(source, updated)),
      );
    }

    return _RenamePlan(
      changed: changed,
      unchanged: unchanged,
      absent: absent,
      move: _planKotlinMove(from, to),
    );
  }

  /// The Kotlin package is a DIRECTORY whose path mirrors the package
  /// declaration, so a rename that only rewrites the `package` line leaves
  /// Gradle looking for the old identity (flutter/flutter#55318). Moving the
  /// directory is the load-bearing half of the Android rename.
  _PlannedMove? _planKotlinMove(_Identity from, _Identity to) {
    final source = 'android/app/src/main/kotlin/${from.kotlinPath}';
    final destination = 'android/app/src/main/kotlin/${to.kotlinPath}';
    if (source == destination) return null;
    if (!Directory(_absolute(source)).existsSync()) return null;
    return _PlannedMove(source, destination);
  }

  List<_FileRewrite> _identityRewrites(_Identity from, _Identity to) {
    final oldAppleId = RegExp.escape(from.appleId);

    return <_FileRewrite>[
      _FileRewrite('pubspec.yaml', [
        _Rule(
          RegExp(r'^name:\s*\S+\s*$', multiLine: true),
          (_) => 'name: ${to.package}',
        ),
      ]),
      _FileRewrite('.env', [
        _Rule(
          RegExp(r'^APP_NAME=.*$', multiLine: true),
          (_) => 'APP_NAME=${to.display}',
        ),
      ]),
      _FileRewrite('DESIGN.md', [
        // The prose body names the app; there is no setting to anchor on, so
        // the old display name is the anchor. It runs BEFORE the frontmatter
        // rule: when the new name contains the old one ("Magic" -> "Magic
        // Example"), running it second would rewrite the already-correct
        // frontmatter into "Magic Example Example".
        _Rule(_wordBounded(from.display), (_) => to.display),
        _Rule(
          RegExp(r'^name: .*$', multiLine: true),
          (_) => 'name: ${to.display}',
        ),
      ]),
      _FileRewrite('.github/dependabot.yml', [
        _Rule(
          RegExp(r'^(# Dependabot config for [^/\s]+/)\S+$', multiLine: true),
          (m) => '${m[1]}${to.package}',
        ),
      ]),
      _FileRewrite('lib/main.dart', [
        _Rule(
          RegExp(r"(MagicApplication\(title: ')[^']*(')"),
          (m) => '${m[1]}${to.display}${m[2]}',
        ),
      ]),

      // Android.
      _FileRewrite('android/app/build.gradle.kts', [
        _Rule(
          RegExp(r'^(\s*)namespace = "[^"]*"$', multiLine: true),
          (m) => '${m[1]}namespace = "${to.androidId}"',
        ),
        _Rule(
          RegExp(r'^(\s*)applicationId = "[^"]*"$', multiLine: true),
          (m) => '${m[1]}applicationId = "${to.androidId}"',
        ),
      ]),
      _FileRewrite('android/app/src/main/AndroidManifest.xml', [
        _Rule(
          RegExp(r'android:label="[^"]*"'),
          (_) => 'android:label="${to.display}"',
        ),
      ]),
      _FileRewrite(
        'android/app/src/main/kotlin/${from.kotlinPath}/MainActivity.kt',
        [
          _Rule(
            RegExp(r'^package .*$', multiLine: true),
            (_) => 'package ${to.androidId}',
          ),
        ],
      ),

      // iOS. macos/Runner/Info.plist deliberately has no entry: it reads
      // $(PRODUCT_BUNDLE_IDENTIFIER) and $(PRODUCT_NAME) from the xcconfig.
      _FileRewrite('ios/Runner/Info.plist', [
        _Rule(
          RegExp(
            r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)',
          ),
          (m) => '${m[1]}${to.display}${m[2]}',
        ),
        _Rule(
          RegExp(r'(<key>CFBundleName</key>\s*<string>)[^<]*(</string>)'),
          (m) => '${m[1]}${to.package}${m[2]}',
        ),
      ]),
      // A pbxproj is a nested property list where the same token appears in
      // object ids, comments and build phases. Anchoring on the setting name
      // AND the current value is what keeps a rename from mangling the file;
      // the `([^;\n]*)` tail preserves suffixes such as `.RunnerTests`.
      _FileRewrite('ios/Runner.xcodeproj/project.pbxproj', [
        _Rule(
          RegExp('PRODUCT_BUNDLE_IDENTIFIER = $oldAppleId([^;\n]*);'),
          (m) => 'PRODUCT_BUNDLE_IDENTIFIER = ${to.appleId}${m[1]};',
        ),
      ]),

      // macOS.
      _FileRewrite('macos/Runner/Configs/AppInfo.xcconfig', [
        _Rule(
          RegExp(r'^PRODUCT_NAME = .*$', multiLine: true),
          (_) => 'PRODUCT_NAME = ${to.package}',
        ),
        _Rule(
          RegExp(r'^PRODUCT_BUNDLE_IDENTIFIER = .*$', multiLine: true),
          (_) => 'PRODUCT_BUNDLE_IDENTIFIER = ${to.appleId}',
        ),
        _Rule(
          RegExp(r'^PRODUCT_COPYRIGHT = .*$', multiLine: true),
          (m) => m[0]!.replaceAll(from.org, to.org),
        ),
      ]),
      _FileRewrite('macos/Runner.xcodeproj/project.pbxproj', [
        _Rule(
          RegExp('PRODUCT_BUNDLE_IDENTIFIER = $oldAppleId([^;\n]*);'),
          (m) => 'PRODUCT_BUNDLE_IDENTIFIER = ${to.appleId}${m[1]};',
        ),
        // The RunnerTests target's host application, and the one line in this
        // file that is functional rather than cosmetic: leave it and a renamed
        // fork's macOS test target cannot launch, because it looks for a bundle
        // no longer produced. Anchored on the setting name AND the current
        // value, the same shape as the bundle-id rule above, so it cannot
        // touch an object id or a comment. There is no iOS counterpart on
        // purpose: `ios/.../project.pbxproj` names `Runner.app` there, which is
        // not the package name and does not move.
        _Rule(
          RegExp(
            'TEST_HOST = "\\\$\\(BUILT_PRODUCTS_DIR\\)/'
            '${RegExp.escape(from.package)}\\.app/([^"]*)"',
          ),
          (m) =>
              'TEST_HOST = "\$(BUILT_PRODUCTS_DIR)/${to.package}.app/'
              '${m[1]!.replaceAll(from.package, to.package)}"',
        ),
      ]),
      _FileRewrite(
        'macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
        [
          _Rule(
            RegExp(r'BuildableName = "[^"]*\.app"'),
            (_) => 'BuildableName = "${to.package}.app"',
          ),
        ],
      ),

      // Windows.
      _FileRewrite('windows/CMakeLists.txt', [
        _Rule(
          RegExp(r'^project\([^\s)]+ LANGUAGES CXX\)$', multiLine: true),
          (_) => 'project(${to.package} LANGUAGES CXX)',
        ),
        _Rule(
          RegExp(r'^set\(BINARY_NAME "[^"]*"\)$', multiLine: true),
          (_) => 'set(BINARY_NAME "${to.package}")',
        ),
      ]),
      _FileRewrite('windows/runner/main.cpp', [
        _Rule(
          RegExp(r'(window\.Create\(L")[^"]*(")'),
          (m) => '${m[1]}${to.display}${m[2]}',
        ),
      ]),
      _FileRewrite('windows/runner/Runner.rc', [
        _rcValue('CompanyName', (_) => to.org),
        _rcValue('FileDescription', (_) => to.display),
        _rcValue('InternalName', (_) => to.package),
        _rcValue('LegalCopyright', (v) => v.replaceAll(from.org, to.org)),
        _rcValue('OriginalFilename', (_) => '${to.package}.exe'),
        _rcValue('ProductName', (_) => to.display),
      ]),

      // Linux.
      _FileRewrite('linux/CMakeLists.txt', [
        _Rule(
          RegExp(r'^set\(BINARY_NAME "[^"]*"\)$', multiLine: true),
          (_) => 'set(BINARY_NAME "${to.package}")',
        ),
        _Rule(
          RegExp(r'^set\(APPLICATION_ID "[^"]*"\)$', multiLine: true),
          (_) => 'set(APPLICATION_ID "${to.androidId}")',
        ),
      ]),
      _FileRewrite('linux/runner/my_application.cc', [
        _Rule(
          RegExp(r'(gtk_header_bar_set_title\(header_bar, ")[^"]*(")'),
          (m) => '${m[1]}${to.display}${m[2]}',
        ),
        _Rule(
          RegExp(r'(gtk_window_set_title\(window, ")[^"]*(")'),
          (m) => '${m[1]}${to.display}${m[2]}',
        ),
      ]),

      // Web.
      _FileRewrite('web/manifest.json', [
        _Rule(
          RegExp(r'("name":\s*")[^"]*(")'),
          (m) => '${m[1]}${to.display}${m[2]}',
        ),
        _Rule(
          RegExp(r'("short_name":\s*")[^"]*(")'),
          (m) => '${m[1]}${to.display}${m[2]}',
        ),
      ]),
      _FileRewrite('web/index.html', [
        _Rule(
          RegExp(
            r'(<meta name="apple-mobile-web-app-title" content=")[^"]*(")',
          ),
          (m) => '${m[1]}${to.display}${m[2]}',
        ),
        _Rule(
          RegExp(r'<title>[^<]*</title>'),
          (_) => '<title>${to.display}</title>',
        ),
      ]),
    ];
  }

  /// Matches [text] as a whole word so a display name that is a prefix of a
  /// longer word ("App" inside "Application") is left alone. The boundary is
  /// dropped when the name does not start and end on a word character, because
  /// `\b` next to punctuation would then never match.
  RegExp _wordBounded(String text) {
    final escaped = RegExp.escape(text);
    final wordEdge = RegExp(r'^\w.*\w$|^\w$', dotAll: true);
    return wordEdge.hasMatch(text) ? RegExp('\\b$escaped\\b') : RegExp(escaped);
  }

  /// One `VALUE "<key>", "<text>" "\0"` entry of a Windows resource file.
  _Rule _rcValue(String key, String Function(String current) value) {
    return _Rule(
      RegExp('(VALUE "$key", ")([^"]*)(")'),
      (m) => '${m[1]}${value(m[2]!)}${m[3]}',
    );
  }

  /// Dart `package:<name>/` imports. Scanned rather than listed, because a fork
  /// adds its own and a stale hardcoded list would leave the app uncompilable.
  List<_FileRewrite> _dartImportRewrites(_Identity from, _Identity to) {
    final needle = 'package:${from.package}/';
    final replacement = 'package:${to.package}/';
    final out = <_FileRewrite>[];
    for (final dir in const ['lib', 'test', 'bin']) {
      final directory = Directory(_absolute(dir));
      if (!directory.existsSync()) continue;
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (!entity.readAsStringSync().contains(needle)) continue;
        out.add(
          _FileRewrite(_relative(entity.path), [
            _Rule(RegExp(RegExp.escape(needle)), (_) => replacement),
          ]),
        );
      }
    }
    out.sort((a, b) => a.path.compareTo(b.path));
    return out;
  }

  // ---------------------------------------------------------------------------
  // Reporting and applying
  // ---------------------------------------------------------------------------

  void _report(
    ArtisanContext ctx,
    _Identity from,
    _Identity to,
    _RenamePlan plan, {
    required bool dryRun,
  }) {
    final out = ctx.output;
    out.writeln(
      dryRun ? 'app:rename (dry run, nothing is written)' : 'app:rename',
    );
    out.writeln('  package  ${from.package} -> ${to.package}');
    out.writeln('  org      ${from.org} -> ${to.org}');
    out.writeln('  display  ${from.display} -> ${to.display}');
    out.writeln('');

    out.writeln('changed (${plan.changed.length}):');
    for (final file in plan.changed) {
      out.writeln('  ${file.path}  (${file.changedLines} line(s))');
    }
    out.writeln('unchanged (${plan.unchanged.length}):');
    for (final path in plan.unchanged) {
      out.writeln('  $path');
    }
    if (plan.absent.isNotEmpty) {
      out.writeln('absent (${plan.absent.length}):');
      for (final path in plan.absent) {
        out.writeln('  $path');
      }
    }

    final move = plan.move;
    out.writeln('kotlin package directory:');
    out.writeln(
      move == null
          ? '  already at android/app/src/main/kotlin/${to.kotlinPath}'
          : '  ${move.source} -> ${move.destination}',
    );

    out.writeln('');
    out.writeln('not owned by app:rename, do these by hand:');
    out.writeln('  - launcher icons on every platform');
    out.writeln(
      '  - macos/Runner.xcodeproj/project.pbxproj still names '
      '"${from.package}.app" in its PBXFileReference and group entries, which '
      'are cosmetic labels Xcode regenerates. TEST_HOST and the bundle ids ARE '
      'rewritten, so the RunnerTests target still launches; `flutter build '
      'macos` was never affected either way, since the shell phase derives the '
      'app filename from \$PRODUCT_NAME at build time',
    );
    out.writeln('  - README.md and AGENTS.md prose');
    out.writeln(
      '  - the remaining .env values, then '
      '`dart run bin/dispatcher.dart design:sync`',
    );
  }

  void _apply(ArtisanContext ctx, _RenamePlan plan) {
    // Files first: MainActivity.kt is rewritten at its old path, then the whole
    // directory moves underneath it.
    for (final file in plan.changed) {
      File(_absolute(file.path)).writeAsStringSync(file.content);
    }

    final move = plan.move;
    if (move != null) {
      final source = Directory(_absolute(move.source));
      final destination = Directory(_absolute(move.destination));
      destination.createSync(recursive: true);
      for (final entity in source.listSync()) {
        final name = _relative(entity.path).split('/').last;
        final String into = '${destination.path}/$name';
        // Subdirectories move too. This loop used to skip every non-File and
        // the `deleteSync(recursive: true)` below then destroyed what it
        // skipped, silently. The boilerplate's own package holds only
        // MainActivity.kt so nothing here could catch it, but a fork with a
        // real Android package almost certainly has subpackages
        // (`receivers/`, `workers/`), and losing them to a rename is not a
        // failure anyone would connect back to this command.
        if (entity is File) {
          entity.renameSync(into);
        } else if (entity is Directory) {
          entity.renameSync(into);
        } else {
          throw StateError(
            'app:rename found ${entity.runtimeType} at ${entity.path} inside '
            'the Kotlin package directory and will not move it. Move or '
            'remove it by hand, then re-run.',
          );
        }
      }
      source.deleteSync(recursive: true);
      _pruneEmptyParents(source.parent, 'android/app/src/main/kotlin');
    }

    if (plan.changed.isEmpty && move == null) {
      ctx.output.success(
        'Nothing to do: the tree already carries this identity.',
      );
      return;
    }

    ctx.output.success(
      'Renamed. ${plan.changed.length} file(s) rewritten'
      '${move == null ? '' : ', 1 package directory moved'}. '
      'Run `flutter pub get` before anything else: the Dart package name '
      'changed, so the current .dart_tool resolution is stale.',
    );
  }

  /// Removes the organisation directories the move emptied. Git does not track
  /// empty directories, so leaving them behind would make a fresh clone of the
  /// fork differ from the machine the rename ran on.
  void _pruneEmptyParents(Directory directory, String stopAtRelative) {
    final stop = _absolute(stopAtRelative);
    var current = directory;
    while (current.path != stop &&
        current.existsSync() &&
        current.listSync().isEmpty) {
      final parent = current.parent;
      current.deleteSync();
      current = parent;
    }
  }

  // ---------------------------------------------------------------------------
  // Small helpers
  // ---------------------------------------------------------------------------

  String? _stringOption(ArtisanContext ctx, String name) {
    final value = ctx.input.option(name);
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _absolute(String relative) => '${_root.path}/$relative';

  String _relative(String absolute) {
    final prefix = '${_root.path}/';
    return absolute.startsWith(prefix)
        ? absolute.substring(prefix.length)
        : absolute;
  }

  String? _read(String relative) {
    final file = File(_absolute(relative));
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  /// Every rule is line-local, so the line count never shifts and an
  /// index-wise comparison is exact.
  int _changedLines(String before, String after) {
    final a = before.split('\n');
    final b = after.split('\n');
    var count = 0;
    for (var i = 0; i < a.length && i < b.length; i++) {
      if (a[i] != b[i]) count++;
    }
    return count + (a.length - b.length).abs();
  }
}

/// The three identity facets plus everything derived from them.
class _Identity {
  const _Identity({
    required this.package,
    required this.org,
    required this.display,
  });

  /// Dart package name, e.g. `acme_app`.
  final String package;

  /// Reverse DNS organisation prefix, e.g. `com.acme`.
  final String org;

  /// Human display name, e.g. `Acme App`.
  final String display;

  /// Android `namespace` / `applicationId` and the Linux GTK application id.
  /// Android keeps the underscored form; the underscore is significant to
  /// plugin discovery (flutter/flutter#55318).
  String get androidId => '$org.$package';

  /// Apple bundle identifier. Apple's tooling rejects underscores in a bundle
  /// id, so the package name is camel cased here and only here.
  String get appleId => '$org.$_camelPackage';

  /// Directory path under `android/app/src/main/kotlin/`.
  String get kotlinPath => '${org.split('.').join('/')}/$package';

  String get _camelPackage {
    final parts = package.split('_');
    return parts.first +
        parts
            .skip(1)
            .where((p) => p.isNotEmpty)
            .map((p) => p[0].toUpperCase() + p.substring(1))
            .join();
  }
}

typedef _Replacer = String Function(Match match);

/// One anchored rewrite inside a file.
class _Rule {
  const _Rule(this.pattern, this.replace);

  final RegExp pattern;
  final _Replacer replace;
}

/// Every rule that applies to one file, keyed by its project-relative path.
class _FileRewrite {
  const _FileRewrite(this.path, this.rules);

  final String path;
  final List<_Rule> rules;
}

/// A file whose rewritten content is ready to be written.
class _PlannedFile {
  const _PlannedFile(this.path, this.content, this.changedLines);

  final String path;
  final String content;
  final int changedLines;
}

/// The Kotlin package directory move.
class _PlannedMove {
  const _PlannedMove(this.source, this.destination);

  final String source;
  final String destination;
}

/// The complete rename, computed before anything is written.
class _RenamePlan {
  const _RenamePlan({
    required this.changed,
    required this.unchanged,
    required this.absent,
    required this.move,
  });

  final List<_PlannedFile> changed;
  final List<String> unchanged;
  final List<String> absent;
  final _PlannedMove? move;
}
