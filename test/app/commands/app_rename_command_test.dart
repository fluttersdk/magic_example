import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluttersdk_artisan/artisan.dart';
import 'package:magic_example/app/commands/app_rename_command.dart';

/// Every identity site `app:rename` owns. The fixture COPIES these out of the
/// real project rather than inventing stand-ins, so a change to any platform
/// file that breaks an anchor fails here instead of in a fork.
const List<String> _fixtureFiles = <String>[
  'pubspec.yaml',
  '.env',
  'DESIGN.md',
  '.github/dependabot.yml',
  'lib/main.dart',
  'bin/dispatcher.dart',
  'test/config/wind_token_resolution_test.dart',
  'test/ui/components/recipes_test.dart',
  'android/app/build.gradle.kts',
  'android/app/src/main/AndroidManifest.xml',
  'android/app/src/main/kotlin/com/fluttersdk/magic_example/MainActivity.kt',
  'ios/Runner/Info.plist',
  'ios/Runner.xcodeproj/project.pbxproj',
  'macos/Runner/Info.plist',
  'macos/Runner/Configs/AppInfo.xcconfig',
  'macos/Runner.xcodeproj/project.pbxproj',
  'macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
  'windows/CMakeLists.txt',
  'windows/runner/Runner.rc',
  'windows/runner/main.cpp',
  'linux/CMakeLists.txt',
  'linux/runner/my_application.cc',
  'web/manifest.json',
  'web/index.html',
];

const String _oldKotlinDir =
    'android/app/src/main/kotlin/com/fluttersdk/magic_example';
const String _newKotlinDir = 'android/app/src/main/kotlin/com/acme/acme_app';

void main() {
  final temporaries = <Directory>[];

  tearDown(() {
    for (final directory in temporaries) {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    }
    temporaries.clear();
  });

  Directory fixture({bool asGitRepository = false}) {
    final root = Directory.systemTemp.createTempSync('app_rename_');
    temporaries.add(root);
    for (final relative in _fixtureFiles) {
      final destination = File('${root.path}/$relative');
      destination.parent.createSync(recursive: true);
      destination.writeAsStringSync(File(relative).readAsStringSync());
    }
    if (asGitRepository) {
      _git(root, const ['init', '--initial-branch=main']);
      _git(root, const ['add', '-A']);
      _git(root, const [
        '-c',
        'user.email=test@example.com',
        '-c',
        'user.name=Test',
        'commit',
        '-m',
        'fixture',
      ]);
    }
    return root;
  }

  group('app:rename dry run', () {
    test('names every identity site and writes nothing', () async {
      final root = fixture();
      final before = _snapshot(root);

      final result = await _run(
        root,
        name: 'acme_app',
        org: 'com.acme',
        display: 'Acme App',
        dryRun: true,
      );

      expect(result.code, 0);
      expect(_snapshot(root), before);
      expect(Directory('${root.path}/$_oldKotlinDir').existsSync(), isTrue);
      expect(Directory('${root.path}/$_newKotlinDir').existsSync(), isFalse);

      for (final relative in _fixtureFiles) {
        if (relative == 'macos/Runner/Info.plist') continue;
        expect(
          result.output,
          contains(relative),
          reason: '$relative is missing from the dry-run report',
        );
      }
      expect(result.output, contains('$_oldKotlinDir -> $_newKotlinDir'));
    });

    test('stays usable while the worktree is dirty', () async {
      final root = fixture(asGitRepository: true);
      File('${root.path}/pubspec.yaml').writeAsStringSync(
        '${File('${root.path}/pubspec.yaml').readAsStringSync()}\n# scratch\n',
      );

      final result = await _run(
        root,
        name: 'acme_app',
        org: 'com.acme',
        display: 'Acme App',
        dryRun: true,
      );

      expect(result.code, 0);
      expect(result.output, isNot(contains('refused to write')));
    });
  });

  group('app:rename apply', () {
    test('rewrites every identity site', () async {
      final root = fixture();

      final result = await _run(
        root,
        name: 'acme_app',
        org: 'com.acme',
        display: 'Acme App',
      );
      expect(result.code, 0);

      String read(String relative) =>
          File('${root.path}/$relative').readAsStringSync();

      expect(read('pubspec.yaml'), contains('name: acme_app'));
      expect(read('.env'), contains('APP_NAME=Acme App'));
      expect(read('DESIGN.md'), contains('name: Acme App'));
      expect(read('DESIGN.md'), isNot(contains('Magic Example')));
      expect(
        read('.github/dependabot.yml'),
        contains('# Dependabot config for fluttersdk/acme_app'),
      );
      expect(read('lib/main.dart'), contains("title: 'Acme App'"));

      expect(
        read('android/app/build.gradle.kts'),
        contains('namespace = "com.acme.acme_app"'),
      );
      expect(
        read('android/app/build.gradle.kts'),
        contains('applicationId = "com.acme.acme_app"'),
      );
      expect(
        read('android/app/src/main/AndroidManifest.xml'),
        contains('android:label="Acme App"'),
      );

      expect(read('ios/Runner/Info.plist'), contains('<string>Acme App<'));
      expect(read('ios/Runner/Info.plist'), contains('<string>acme_app<'));
      // Apple bundle ids reject underscores, so the package name is camel cased
      // for the Apple platforms and only there.
      expect(
        read('ios/Runner.xcodeproj/project.pbxproj'),
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.acme.acmeApp;'),
      );
      expect(
        read('macos/Runner/Configs/AppInfo.xcconfig'),
        allOf(
          contains('PRODUCT_NAME = acme_app'),
          contains('PRODUCT_BUNDLE_IDENTIFIER = com.acme.acmeApp'),
          contains('PRODUCT_COPYRIGHT = '),
          contains('com.acme.'),
        ),
      );
      expect(
        read('macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme'),
        contains('BuildableName = "acme_app.app"'),
      );
      // macos/Runner/Info.plist reads $(PRODUCT_BUNDLE_IDENTIFIER) and
      // $(PRODUCT_NAME) from the xcconfig, so a rename must leave it alone.
      expect(
        read('macos/Runner/Info.plist'),
        File('macos/Runner/Info.plist').readAsStringSync(),
      );

      expect(
        read('windows/CMakeLists.txt'),
        allOf(
          contains('project(acme_app LANGUAGES CXX)'),
          contains('set(BINARY_NAME "acme_app")'),
        ),
      );
      expect(
        read('windows/runner/main.cpp'),
        contains('window.Create(L"Acme App"'),
      );
      expect(
        read('windows/runner/Runner.rc'),
        allOf(
          contains('VALUE "CompanyName", "com.acme"'),
          contains('VALUE "FileDescription", "Acme App"'),
          contains('VALUE "InternalName", "acme_app"'),
          contains('VALUE "OriginalFilename", "acme_app.exe"'),
          contains('VALUE "ProductName", "Acme App"'),
          contains('2026 com.acme.'),
        ),
      );

      expect(
        read('linux/CMakeLists.txt'),
        allOf(
          contains('set(BINARY_NAME "acme_app")'),
          contains('set(APPLICATION_ID "com.acme.acme_app")'),
        ),
      );
      expect(
        read('linux/runner/my_application.cc'),
        contains('gtk_header_bar_set_title(header_bar, "Acme App")'),
      );

      expect(read('web/manifest.json'), contains('"name": "Acme App"'));
      expect(read('web/manifest.json'), contains('"short_name": "Acme App"'));
      expect(read('web/index.html'), contains('<title>Acme App</title>'));

      expect(
        read('bin/dispatcher.dart'),
        contains('package:acme_app/app/commands/_index.g.dart'),
      );
      expect(
        read('test/ui/components/recipes_test.dart'),
        contains('package:acme_app/ui/components/tag/tag.recipe.dart'),
      );

      // Nothing may still carry the old identity anywhere this command owns.
      for (final relative in _fixtureFiles) {
        if (relative == 'macos/Runner/Info.plist') continue;
        if (relative == 'macos/Runner.xcodeproj/project.pbxproj') continue;
        // MainActivity.kt lives under the directory the rename just moved.
        final path = relative.replaceFirst(_oldKotlinDir, _newKotlinDir);
        expect(
          read(path),
          isNot(contains('magic_example')),
          reason: '$path still carries the old package name',
        );
      }
    });

    test(
      'moves the Kotlin package directory, not just its package line',
      () async {
        final root = fixture();

        await _run(
          root,
          name: 'acme_app',
          org: 'com.acme',
          display: 'Acme App',
        );

        expect(Directory('${root.path}/$_oldKotlinDir').existsSync(), isFalse);
        // The emptied organisation levels go too: git does not track empty
        // directories, so leaving them would make a fresh clone differ.
        expect(
          Directory(
            '${root.path}/android/app/src/main/kotlin/com/fluttersdk',
          ).existsSync(),
          isFalse,
        );
        expect(
          File(
            '${root.path}/$_newKotlinDir/MainActivity.kt',
          ).readAsStringSync(),
          contains('package com.acme.acme_app'),
        );
      },
    );

    test(
      'touches only anchored PRODUCT_BUNDLE_IDENTIFIER lines in a pbxproj',
      () async {
        final root = fixture();
        const decoys =
            '\t\t\t\t/* com.fluttersdk.magicExample is only a comment */\n'
            '\t\t\t\tINFOPLIST_KEY_CFBundleName = com.fluttersdk.magicExample;\n';
        final pbxproj = File(
          '${root.path}/ios/Runner.xcodeproj/project.pbxproj',
        );
        pbxproj.writeAsStringSync('${pbxproj.readAsStringSync()}$decoys');

        await _run(
          root,
          name: 'acme_app',
          org: 'com.acme',
          display: 'Acme App',
        );

        final updated = pbxproj.readAsStringSync();
        expect(updated, contains(decoys));
        expect(
          updated,
          isNot(contains('PRODUCT_BUNDLE_IDENTIFIER = com.fluttersdk')),
        );
        // The `.RunnerTests` suffix rides along instead of being flattened.
        expect(
          updated,
          contains('PRODUCT_BUNDLE_IDENTIFIER = com.acme.acmeApp.RunnerTests;'),
        );
      },
    );

    test('a second run with the same arguments changes nothing', () async {
      final root = fixture();

      await _run(root, name: 'acme_app', org: 'com.acme', display: 'Acme App');
      final afterFirst = _snapshot(root);

      final second = await _run(
        root,
        name: 'acme_app',
        org: 'com.acme',
        display: 'Acme App',
      );

      expect(second.code, 0);
      expect(second.output, contains('changed (0)'));
      expect(_snapshot(root), afterFirst);
    });
  });

  group('app:rename refusals', () {
    test('rejects a --name that is not a Dart package identifier', () async {
      for (final invalid in const ['Acme App', '../evil', 'com.acme', '9app']) {
        final root = fixture();
        final before = _snapshot(root);

        final result = await _run(
          root,
          name: invalid,
          org: 'com.acme',
          display: 'Acme App',
        );

        expect(result.code, 1, reason: 'accepted --name=$invalid');
        expect(result.output, contains('app:rename refused --name'));
        expect(_snapshot(root), before);
      }
    });

    test('rejects an --org that is not reverse DNS', () async {
      for (final invalid in const ['acme', '../../etc', 'com..acme', 'Com.A']) {
        final root = fixture();
        final before = _snapshot(root);

        final result = await _run(
          root,
          name: 'acme_app',
          org: invalid,
          display: 'Acme App',
        );

        expect(result.code, 1, reason: 'accepted --org=$invalid');
        expect(result.output, contains('app:rename refused --org'));
        expect(_snapshot(root), before);
      }
    });

    test(
      'rejects a --display that would break out of a string literal',
      () async {
        for (final invalid in const [
          'Acme "App"',
          r'Acme\App',
          'A<b>',
          r'$App',
        ]) {
          final root = fixture();
          final before = _snapshot(root);

          final result = await _run(
            root,
            name: 'acme_app',
            org: 'com.acme',
            display: invalid,
          );

          expect(result.code, 1, reason: 'accepted --display=$invalid');
          expect(result.output, contains('app:rename refused --display'));
          expect(_snapshot(root), before);
        }
      },
    );

    test('refuses when no identity option is given', () async {
      final root = fixture();

      final result = await _run(root);

      expect(result.code, 1);
      expect(
        result.output,
        contains('needs at least one of --name, --org or --display'),
      );
    });

    test('refuses to write into a dirty worktree', () async {
      final root = fixture(asGitRepository: true);
      final env = File('${root.path}/.env');
      env.writeAsStringSync('${env.readAsStringSync()}\nSCRATCH=1\n');
      final before = _snapshot(root);

      final result = await _run(
        root,
        name: 'acme_app',
        org: 'com.acme',
        display: 'Acme App',
      );

      expect(result.code, 1);
      expect(result.output, contains('app:rename refused to write'));
      expect(result.output, contains('uncommitted change'));
      expect(_snapshot(root), before);
    });

    test(
      'does not count a modified pubspec.lock or an untracked file as dirty',
      () async {
        final root = fixture(asGitRepository: true);
        // pubspec.lock is tracked and permanently modified in this workspace: the
        // index holds the hosted-only resolution, a local `flutter pub get`
        // rewrites the working copy with sibling paths.
        File('${root.path}/pubspec.lock').writeAsStringSync('# committed\n');
        _git(root, const ['add', 'pubspec.lock']);
        _git(root, const [
          '-c',
          'user.email=test@example.com',
          '-c',
          'user.name=Test',
          'commit',
          '-m',
          'lock',
        ]);
        File('${root.path}/pubspec.lock').writeAsStringSync('# local paths\n');
        File('${root.path}/scratch.txt').writeAsStringSync('untracked\n');

        final result = await _run(
          root,
          name: 'acme_app',
          org: 'com.acme',
          display: 'Acme App',
        );

        expect(result.code, 0);
        expect(result.output, isNot(contains('refused to write')));
        expect(
          File('${root.path}/pubspec.yaml').readAsStringSync(),
          contains('name: acme_app'),
        );
      },
    );

    test(
      'refuses when the Android namespace does not match the package name',
      () async {
        final root = fixture();
        final gradle = File('${root.path}/android/app/build.gradle.kts');
        gradle.writeAsStringSync(
          gradle.readAsStringSync().replaceFirst(
            'namespace = "com.fluttersdk.magic_example"',
            'namespace = "com.fluttersdk.somethingelse"',
          ),
        );
        final before = _snapshot(root);

        final result = await _run(
          root,
          name: 'acme_app',
          org: 'com.acme',
          display: 'Acme App',
        );

        expect(result.code, 1);
        expect(result.output, contains('does not end in ".magic_example"'));
        expect(_snapshot(root), before);
      },
    );
  });
}

/// Invokes the command against [root] and returns its exit code plus the whole
/// buffered output (errors included, prefixed with `[ERROR]`).
Future<({int code, String output})> _run(
  Directory root, {
  String? name,
  String? org,
  String? display,
  bool dryRun = false,
}) async {
  final output = BufferedOutput();
  final code = await AppRenameCommand(root: root).handle(
    ArtisanContext.bare(
      MapInput(<String, dynamic>{
        'name': ?name,
        'org': ?org,
        'display': ?display,
        'dry-run': dryRun,
      }),
      output,
    ),
  );
  return (code: code, output: output.content);
}

/// Path to content for every file under [root], excluding git's own storage.
Map<String, String> _snapshot(Directory root) {
  final snapshot = <String, String>{};
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File) continue;
    final relative = entity.path.substring(root.path.length + 1);
    if (relative.startsWith('.git/')) continue;
    snapshot[relative] = entity.readAsStringSync();
  }
  return snapshot;
}

void _git(Directory root, List<String> arguments) {
  final result = Process.runSync('git', arguments, workingDirectory: root.path);
  if (result.exitCode != 0) {
    throw StateError('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
}
