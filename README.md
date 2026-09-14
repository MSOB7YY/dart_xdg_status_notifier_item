[![Pub Package](https://img.shields.io/pub/v/dart_xdg_status_notifier_item.svg)](https://pub.dev/packages/dart_xdg_status_notifier_item)
[![codecov](https://codecov.io/gh/canonical/xdg_status_notifier_item.dart/branch/main/graph/badge.svg?token=QW1N0AQQOY)](https://codecov.io/gh/canonical/xdg_status_notifier_item.dart)

This is a fork of the original [xdg_status_notifier_item](https://pub.dev/packages/xdg_status_notifier_item) package.

Allows status notifications (i.e. system tray) on Linux desktops using the [StatusNotifierItem specification](https://www.freedesktop.org/wiki/Specifications/StatusNotifierItem/).

## Installation

### Add to `pubspec.yaml`
```yaml
dependencies:
  dart_xdg_status_notifier_item: ^0.0.1
```

### Or using `dart pub add`
```bash
dart pub add dart_xdg_status_notifier_item
```

### Or using `flutter pub add`
```bash
flutter pub add dart_xdg_status_notifier_item
```

## Sample

A complete basic example of setting up a status notifier client with a system tray menu:

```dart
import 'package:dart_xdg_status_notifier_item/dart_xdg_status_notifier_item.dart';

late final StatusNotifierItemClient client;

void main() async {
  client = StatusNotifierItemClient(
    id: 'test-client',
    iconName: 'computer-fail-symbolic',
    menu: DBusMenuItem(children: [
      DBusMenuItem(label: 'Hello', onClicked: () async => print('Hello')),
      DBusMenuItem(label: 'World', enabled: false),
      DBusMenuItem.separator(),
      DBusMenuItem(
        label: 'Quit',
        onClicked: () async => await client.close(),
      ),
    ]),
  );
  await client.connect();
}
```

## Using dynamic properties

You can change properties and signals dynamically, like the tool tip, the title, and the status:

```dart
client.title = 'New Title';
client.toolTip = StatusNotifierToolTip('icon-name', [], 'New Tool Tip title', 'New Tool Tip body');
client.status = StatusNotifierItemStatus.passive;
```

## Complex Menus & Interactivity

You can create complex nested menus using `DBusMenuItem`, including separators, disabled items, submenus, and checkmarks/radio buttons.

```dart
DBusMenuItem buildMenu() {
  return DBusMenuItem(
    children: [
      DBusMenuItem(
        label: 'Submenu Example',
        children: [
          DBusMenuItem(
            label: 'Submenu 1',
            onClicked: () async => print('Submenu item 1 clicked!'),
          ),
          DBusMenuItem(
            label: 'Submenu 2',
            onClicked: () async => print('Submenu item 2 clicked!'),
          ),
        ],
      ),
      DBusMenuItem.separator(),
      DBusMenuItem.checkmark(
        'Checkmark Example',
        state: true, // or false depending on your state
        onClicked: () async {
          // Toggle your state and rebuild menu
          print('Toggled checkmark');
        },
      ),
    ],
  );
}
```

If your application state changes (like toggling a checkmark), you can dynamically update the entire menu structure:

```dart
await client.updateMenu(buildMenu());
```

## Events & Interactivity

The `StatusNotifierItemClient` exposes several event callbacks that you can provide when constructing it:

```dart
client = StatusNotifierItemClient(
  id: 'test-client',
  menu: buildMenu(),
  onContextMenu: (x, y) async => print('Context menu opened at $x, $y'),
  onActivate: (x, y) async => print('Activated at $x, $y'),
  onSecondaryActivate: (x, y) async => print('Secondary activated at $x, $y'),
  onScroll: (delta, orientation) async => print('Scrolled $delta ($orientation)'),
);

// You can also listen for host registration changes:
client.onHostRegisteredChanged = (registered) async {
  print('Host registration changed: $registered');
};
```

## Advanced Configuration & Connection

### Connection Options

When calling `connect()`, you can customize how the client attaches to the D-Bus watcher:

```dart
await client.connect(
  requireWatcher: false, // If true, throws if no watcher is found
  enableGnomeExtensionCheck: true, // Warns if GNOME Shell extensions aren't enabled
);
```

### Supported environments

The library supports the FreeDesktop specification `org.freedesktop`, KDE `org.kde` and Ayatana `org.ayatana` implementation.
You can specify the backend at initialization:

```dart
client = StatusNotifierItemClient(
    id: 'test-client',
    backend: StatusNotifierItemBackend.auto, // Tries to automatically detect
    menu: buildMenu(),
);
```

## Running the Example

You can find a comprehensive example in `example/example.dart`. You can run it with various command-line arguments:

```bash
# Run with automatic backend detection
dart run example/example.dart

# Run with a specific backend
dart run example/example.dart --backend=kde
dart run example/example.dart --backend=ayatana
dart run example/example.dart --backend=spec

# Require the watcher to be present or fail
dart run example/example.dart --require-watcher

# Use an icon name from your theme instead of a local png
dart run example/example.dart --icon-by-name

# Disable checking for GNOME AppIndicator extension warnings
dart run example/example.dart --disable-gnome-check
```

## Contributing to xdg_status_notifier_item.dart

We welcome contributions! Please make sure you format, analyze, and test your code before submitting a pull request.
