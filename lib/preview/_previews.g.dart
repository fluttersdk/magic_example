// GENERATED: do not edit by hand.
// Regenerate via: dart run magic:artisan previews:refresh
//
// Source: *.preview.dart files discovered under the scan dir.

import 'package:magic_devtools/preview.dart';
import 'bottom_menu.preview.dart';
import 'dashboard_screen.preview.dart';
import 'foundations.preview.dart';
import 'login_screen.preview.dart';
import 'profile_screen.preview.dart';
import 'register_screen.preview.dart';
import 'settings_screen.preview.dart';
import 'sidebar_menu.preview.dart';
import 'teams_screen.preview.dart';

List<PreviewEntry> previewEntries() {
  return <PreviewEntry>[
    PreviewEntry(
      label: 'BottomMenu',
      slug: 'bottom_menu',
      builder: (_) => const BottomMenuPreview(),
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
      label: 'SidebarMenu',
      slug: 'sidebar_menu',
      builder: (_) => const SidebarMenuPreview(),
    ),
    PreviewEntry(
      label: 'TeamsScreen',
      slug: 'teams_screen',
      builder: (_) => const TeamsScreenPreview(),
    ),
  ];
}
