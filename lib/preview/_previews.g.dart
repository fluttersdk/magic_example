// GENERATED: do not edit by hand.
// Regenerate via: dart run magic:artisan previews:refresh
//
// Source: *.preview.dart files discovered under the scan dir.

import 'package:magic_devtools/preview.dart';
import 'components.preview.dart';
import 'dashboard_screen.preview.dart';
import 'foundations.preview.dart';
import 'login_screen.preview.dart';
import 'profile_screen.preview.dart';
import 'register_screen.preview.dart';
import 'settings_screen.preview.dart';
import 'teams_screen.preview.dart';

List<PreviewEntry> previewEntries() {
  return <PreviewEntry>[
    PreviewEntry(
      label: 'Components',
      slug: 'components',
      builder: (_) => const ComponentsPreview(),
    ),
    PreviewEntry(
      label: 'DashboardScreen',
      slug: 'dashboard_screen',
      builder: (_) => const DashboardScreenPreview(),
    ),
    PreviewEntry(
      label: 'Foundations',
      slug: 'foundations',
      builder: (_) => const FoundationsPreview(),
    ),
    PreviewEntry(
      label: 'LoginScreen',
      slug: 'login_screen',
      builder: (_) => const LoginScreenPreview(),
    ),
    PreviewEntry(
      label: 'ProfileScreen',
      slug: 'profile_screen',
      builder: (_) => const ProfileScreenPreview(),
    ),
    PreviewEntry(
      label: 'RegisterScreen',
      slug: 'register_screen',
      builder: (_) => const RegisterScreenPreview(),
    ),
    PreviewEntry(
      label: 'SettingsScreen',
      slug: 'settings_screen',
      builder: (_) => const SettingsScreenPreview(),
    ),
    PreviewEntry(
      label: 'TeamsScreen',
      slug: 'teams_screen',
      builder: (_) => const TeamsScreenPreview(),
    ),
  ];
}
