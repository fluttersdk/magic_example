import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart' show SelectOption, WDiv, WText;
import 'package:magic_starter/magic_starter.dart'
    show
        Badge,
        BadgeTone,
        Button,
        ButtonIntent,
        ButtonSize,
        Card,
        CardVariant,
        Input,
        InputState,
        MagicFormField,
        Select,
        Switch,
        Tabs,
        Typography,
        TypographyVariant;

/// Components preview: a curated matrix of the key library components.
///
/// Buttons/badges/inputs/cards are shown as static variant matrices; the
/// interactive controls (switch, tabs, select) are LIVE so the catalog can be
/// clicked to see real behavior. Layout rows use the `wrap` utility (Wind's
/// Wrap widget) so they reflow instead of overflowing the pane.
class ComponentsPreview extends StatefulWidget {
  /// Creates the components preview.
  const ComponentsPreview({super.key});

  @override
  State<ComponentsPreview> createState() => _ComponentsPreviewState();
}

class _ComponentsPreviewState extends State<ComponentsPreview> {
  bool _switchOn = true;
  int _tabIndex = 1;
  String _team = 'engineering';

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'flex flex-col gap-8',
      children: [
        _section('Buttons', _buildButtons()),
        _section('Badges', _buildBadges()),
        _section('Inputs', _buildInputs()),
        _section('Switches', _buildSwitches()),
        _section('Select', _buildSelect()),
        _section('Tabs', _buildTabs()),
        _section('Cards', _buildCards()),
      ],
    );
  }

  /// A labelled section wrapper.
  Widget _section(String title, Widget body) {
    return WDiv(
      className: 'flex flex-col gap-3',
      children: [
        WText(title, className: 'text-fg text-sm font-semibold uppercase'),
        body,
      ],
    );
  }

  /// Every button intent at each size, plus the loading and disabled states.
  Widget _buildButtons() {
    return WDiv(
      className: 'flex flex-col gap-3',
      children: [
        for (final ButtonSize size in ButtonSize.values)
          WDiv(
            className: 'wrap items-center gap-3',
            children: [
              for (final ButtonIntent intent in ButtonIntent.values)
                Button(
                  intent: intent,
                  size: size,
                  onPressed: () {},
                  child: WText(intent.name),
                ),
            ],
          ),
        WDiv(
          className: 'wrap items-center gap-3',
          children: [
            Button(
              isLoading: true,
              onPressed: () {},
              child: const WText('Loading'),
            ),
            Button(
              disabled: true,
              onPressed: () {},
              child: const WText('Disabled'),
            ),
          ],
        ),
      ],
    );
  }

  /// Every badge tone.
  Widget _buildBadges() {
    return WDiv(
      className: 'wrap items-center gap-3',
      children: [
        for (final BadgeTone tone in BadgeTone.values)
          Badge(tone.name, tone: tone),
      ],
    );
  }

  /// Normal and error input states wrapped in a form field.
  Widget _buildInputs() {
    return const WDiv(
      className: 'flex flex-col gap-4 max-w-md',
      children: [
        MagicFormField(
          label: 'Email',
          hint: 'We never share your email.',
          child: Input(placeholder: 'ada@example.com'),
        ),
        MagicFormField(
          label: 'Password',
          error: 'Password is required.',
          child: Input(
            placeholder: 'Enter your password',
            state: InputState.error,
          ),
        ),
      ],
    );
  }

  /// A live switch the user can toggle, plus a disabled one.
  Widget _buildSwitches() {
    return WDiv(
      className: 'wrap items-center gap-6',
      children: [
        Switch(
          value: _switchOn,
          onChanged: (bool v) => setState(() => _switchOn = v),
        ),
        const Switch(value: true, onChanged: null, disabled: true),
      ],
    );
  }

  /// A live single-select dropdown.
  Widget _buildSelect() {
    return WDiv(
      className: 'max-w-xs',
      child: Select<String>(
        value: _team,
        onChange: (String? v) => setState(() => _team = v ?? _team),
        options: const <SelectOption<String>>[
          SelectOption(value: 'engineering', label: 'Engineering'),
          SelectOption(value: 'design', label: 'Design'),
          SelectOption(value: 'personal', label: 'Personal'),
        ],
      ),
    );
  }

  /// A live tab strip; tapping a tab swaps the panel.
  Widget _buildTabs() {
    return Tabs(
      tabs: const <String>['Overview', 'Members', 'Settings'],
      selectedIndex: _tabIndex,
      onChanged: (int i) => setState(() => _tabIndex = i),
      panelBuilder: (int index) => WDiv(
        className: 'p-4',
        child: WText('Panel ${index + 1}', className: 'text-fg text-sm'),
      ),
    );
  }

  /// Each card variant with a title and body.
  Widget _buildCards() {
    return WDiv(
      className: 'wrap gap-4',
      children: [
        for (final CardVariant variant in CardVariant.values)
          WDiv(
            className: 'w-64',
            child: Card(
              title: variant.name,
              variant: variant,
              child: const Typography(
                'Card body content.',
                variant: TypographyVariant.caption,
              ),
            ),
          ),
      ],
    );
  }
}
