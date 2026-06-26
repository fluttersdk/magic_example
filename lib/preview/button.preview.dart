import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart' show WDiv, WText;
import 'package:magic_starter/magic_starter.dart'
    show Button, ButtonIntent, ButtonSize;

/// Button preview: every intent at each size, plus the loading and disabled
/// states.
class ButtonPreview extends StatelessWidget {
  /// Creates the button preview.
  const ButtonPreview({super.key});

  @override
  Widget build(BuildContext context) {
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
}
