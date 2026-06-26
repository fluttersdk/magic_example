import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart' show WDiv;
import 'package:magic_starter/magic_starter.dart' show Badge, BadgeTone;

/// Badge preview: every tone.
class BadgePreview extends StatelessWidget {
  /// Creates the badge preview.
  const BadgePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'wrap items-center gap-3',
      children: [
        for (final BadgeTone tone in BadgeTone.values)
          Badge(tone.name, tone: tone),
      ],
    );
  }
}
