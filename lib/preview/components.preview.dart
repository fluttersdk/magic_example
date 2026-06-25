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

/// Components preview: a curated matrix of the key library components rendered
/// in their representative variants.
///
/// This is a static variant matrix (the catalog renders it in light and dark);
/// interactive components are shown in fixed display states, matching the v1
/// "no knobs" decision. Selection callbacks are no-ops so the snapshot stays
/// stable across rebuilds.
class ComponentsPreview extends StatelessWidget {
  /// Creates the components preview.
  const ComponentsPreview({super.key});

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
            className: 'flex flex-row flex-wrap items-center gap-3',
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
          className: 'flex flex-row flex-wrap items-center gap-3',
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
      className: 'flex flex-row flex-wrap items-center gap-3',
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

  /// On and off switch states, plus disabled.
  Widget _buildSwitches() {
    return WDiv(
      className: 'flex flex-row items-center gap-6',
      children: [
        Switch(value: true, onChanged: (_) {}),
        Switch(value: false, onChanged: (_) {}),
        const Switch(value: true, onChanged: null, disabled: true),
      ],
    );
  }

  /// A single-select dropdown with a chosen value.
  Widget _buildSelect() {
    return WDiv(
      className: 'max-w-xs',
      child: Select<String>(
        value: 'engineering',
        onChange: (_) {},
        options: const <SelectOption<String>>[
          SelectOption(value: 'engineering', label: 'Engineering'),
          SelectOption(value: 'design', label: 'Design'),
          SelectOption(value: 'personal', label: 'Personal'),
        ],
      ),
    );
  }

  /// A tab strip with the second tab active.
  Widget _buildTabs() {
    return Tabs(
      tabs: const <String>['Overview', 'Members', 'Settings'],
      selectedIndex: 1,
      onChanged: (_) {},
      panelBuilder: (int index) => WDiv(
        className: 'p-4',
        child: WText('Panel ${index + 1}', className: 'text-fg text-sm'),
      ),
    );
  }

  /// Each card variant with a title and body.
  Widget _buildCards() {
    return WDiv(
      className: 'flex flex-row flex-wrap gap-4',
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
