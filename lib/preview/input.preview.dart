import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart' show WDiv;
import 'package:magic_starter/magic_starter.dart'
    show Input, InputState, MagicFormField;

/// Input preview: normal and error input states wrapped in a form field.
class InputPreview extends StatelessWidget {
  /// Creates the input preview.
  const InputPreview({super.key});

  @override
  Widget build(BuildContext context) {
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
}
