/// View Configuration.
///
/// Customizes the appearance of Magic UI components (dialogs, confirms,
/// loading). These className values are read by MagicFeedback via
/// `Config.get('view.*')`.
///
/// EVERY COLOUR HERE IS A SEMANTIC TOKEN, never a palette one. These strings
/// are as much a design surface as a widget's `className`, and they used to be
/// the one place in this app that reached straight for `bg-white`,
/// `text-gray-600` and `bg-red-500`. A raw palette colour cannot answer to a
/// theme change: regenerating `wind_theme.g.dart` from a different DESIGN.md
/// restyled the whole app and left every dialog looking like the old one.
///
/// It also means the `dark:` peers disappear from this file. They have not been
/// dropped: each alias carries its own, so `bg-surface-container` already
/// resolves to one hex in light and another in dark.
Map<String, dynamic> get viewConfig => {
  'view': {
    'dialog': {
      'class': 'bg-surface-container rounded-xl p-6 shadow-2xl max-w-lg',
    },
    'confirm': {
      'container_class':
          'bg-surface-container rounded-xl p-6 shadow-2xl w-80',
      'title_class': 'text-lg font-bold text-fg',
      'message_class': 'text-fg-muted mt-2',
      'button_cancel_class': 'px-4 py-2 text-fg-muted',
      'button_confirm_class': 'px-4 py-2 bg-primary text-on-primary rounded-lg',
      'button_danger_class':
          'px-4 py-2 bg-destructive text-on-destructive rounded-lg',
    },
  },
};
