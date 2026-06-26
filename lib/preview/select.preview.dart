import 'package:flutter/widgets.dart';
import 'package:magic/magic.dart' show SelectOption, WDiv;
import 'package:magic_starter/magic_starter.dart' show Select;

/// Select preview: a live single-select dropdown.
class SelectPreview extends StatefulWidget {
  /// Creates the select preview.
  const SelectPreview({super.key});

  @override
  State<SelectPreview> createState() => _SelectPreviewState();
}

class _SelectPreviewState extends State<SelectPreview> {
  String _team = 'engineering';

  @override
  Widget build(BuildContext context) {
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
}
