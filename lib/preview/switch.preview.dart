import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart' show WDiv;
import 'package:magic_starter/magic_starter.dart' show Switch;

/// Switch preview: a live switch the user can toggle, plus a disabled one.
class SwitchPreview extends StatefulWidget {
  /// Creates the switch preview.
  const SwitchPreview({super.key});

  @override
  State<SwitchPreview> createState() => _SwitchPreviewState();
}

class _SwitchPreviewState extends State<SwitchPreview> {
  bool _on = true;

  @override
  Widget build(BuildContext context) {
    return WDiv(
      className: 'wrap items-center gap-6',
      children: [
        Switch(value: _on, onChanged: (bool v) => setState(() => _on = v)),
        const Switch(value: true, onChanged: null, disabled: true),
      ],
    );
  }
}
