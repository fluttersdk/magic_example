import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart';
import 'package:magic_starter/magic_starter.dart'
    show Card, CardVariant, Typography, TypographyVariant;

/// Dashboard view: the default landing page after successful authentication.
///
/// Design-first: every surface and text color flows through the semantic
/// alias tokens (`bg-surface`, `text-fg`, ...) so it tracks DESIGN.md in both
/// light and dark. The quick-link tiles compose the shared [Card] component.
class DashboardView extends StatelessWidget {
  /// Creates the [DashboardView].
  const DashboardView({super.key});

  static const _iconHero = Icons.auto_awesome;
  static const _iconDocs = Icons.menu_book;
  static const _iconGitHub = Icons.code;
  static const _iconCli = Icons.terminal;
  static const _iconArrow = Icons.arrow_forward_outlined;
  static const _iconHeart = Icons.favorite;

  @override
  Widget build(BuildContext context) {
    final appName = Config.get('app.name', 'My App') ?? 'My App';

    return WDiv(
      className: 'w-full max-w-[480px] md:max-w-4xl mx-auto p-4 lg:p-8',
      child: WDiv(
        className: '''
          rounded-2xl bg-surface-container
          border border-color-border
          p-6 lg:p-8 flex flex-col items-center
        ''',
        children: [
          // 1. Hero.
          WDiv(
            className: '''
              w-20 h-20 rounded-2xl
              flex items-center justify-center
              bg-primary
            ''',
            child: const WIcon(
              _iconHero,
              className: 'text-4xl text-on-primary',
            ),
          ),
          const WSpacer(className: 'h-6'),
          Typography(
            appName,
            variant: TypographyVariant.h2,
            className: 'text-center',
          ),
          const WSpacer(className: 'h-2'),
          const Typography(
            'Built with Magic Starter',
            variant: TypographyVariant.caption,
          ),

          const WSpacer(className: 'h-8'),

          // 2. Quick-link cards.
          WDiv(
            className: 'w-full grid grid-cols-1 md:grid-cols-3 gap-3',
            children: [
              _buildLinkCard(
                icon: _iconDocs,
                title: 'Documentation',
                description: 'Read the Magic Framework docs to get started.',
                url: 'https://magic.fluttersdk.com',
              ),
              _buildLinkCard(
                icon: _iconGitHub,
                title: 'GitHub',
                description:
                    'Star the repo, report issues, or contribute code.',
                url: 'https://github.com/fluttersdk/magic',
              ),
              _buildLinkCard(
                icon: _iconCli,
                title: 'CLI Commands',
                description:
                    'Run `magic --help` to see all available commands.',
                url: 'https://magic.fluttersdk.com/cli',
              ),
            ],
          ),

          const WSpacer(className: 'h-8'),

          // 3. Footer.
          WDiv(
            className: 'flex flex-row items-center justify-center gap-1',
            children: [
              const WText('Made with', className: 'text-xs text-fg-muted'),
              const WIcon(_iconHeart, className: 'text-xs text-destructive'),
              const WText('by', className: 'text-xs text-fg-muted'),
              WAnchor(
                onTap: () => Launch.url('https://anilcancakir.com'),
                child: const WText(
                  'Anılcan Çakır',
                  className: 'text-xs font-medium text-fg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a single quick-link tile composing the shared [Card] component.
  Widget _buildLinkCard({
    required IconData icon,
    required String title,
    required String description,
    required String url,
  }) {
    return Card(
      variant: CardVariant.inset,
      child: WDiv(
        className: 'flex flex-col',
        children: [
          WDiv(
            className: 'flex flex-row items-center gap-3 mb-2',
            children: [
              WDiv(
                className: 'p-2 rounded-lg bg-primary-container',
                child: WIcon(icon, className: 'text-lg text-fg'),
              ),
              // flex-1 so the title takes the remaining row width and fits
              // (or wraps) instead of overflowing when the card is narrow,
              // e.g. inside the 3-column grid beside the app-shell sidebar.
              WText(title, className: 'flex-1 text-base font-semibold text-fg'),
            ],
          ),
          WText(description, className: 'text-sm text-fg-muted mb-3'),
          WAnchor(
            onTap: () => Launch.url(url),
            child: WDiv(
              className: 'flex flex-row items-center gap-1',
              children: [
                const WText(
                  'Learn more',
                  className: 'text-sm font-medium text-fg',
                ),
                const WIcon(_iconArrow, className: 'text-sm text-fg'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
