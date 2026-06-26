import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart' show WDiv;
import 'package:magic_starter/magic_starter.dart'
    show Card, CardVariant, Typography, TypographyVariant;

/// Card preview: each card variant with a title and body.
class CardPreview extends StatelessWidget {
  /// Creates the card preview.
  const CardPreview({super.key});

  @override
  Widget build(BuildContext context) {
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
