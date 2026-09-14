# Agent Guidelines for xdg_status_notifier_item.dart

## Documentation
- Continuously improve documentation based on changes you make.
- Maintain and update the `TODO.md` file dynamically. As you implement new features (like DBus signals, properties, backend integrations), remove them from `TODO.md` and document them in the `README.md` or `CHANGELOG.md` accordingly.
- Ensure that you consider the current state of desktop environments (KDE, GTK, Ayatana) when deciding which specs to rely on. The base line is the freedesktop spec, but other backends should be considered when implementing workarounds.

## Testing and Verification
- Always run `dart test` and `dart analyze` before submitting code changes.
- Ensure any new backend or feature gets added to `test/xdg_status_notifier_item_test.dart`.
