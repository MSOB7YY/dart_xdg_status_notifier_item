import 'dart:io';
import 'package:dart_xdg_status_notifier_item/dart_xdg_status_notifier_item.dart';
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';

late StatusNotifierItemClient client;
var itemClicked = false;
var checkmarkIsActive = true;
var activeRadio = 1;

DBusMenuItem buildMenu() {
  return DBusMenuItem(
    children: [
      DBusMenuItem(
        label: itemClicked ? 'Clicked Item' : 'Item',
        onClicked: () async {
          print('Clicked on: ${itemClicked ? 'Clicked Item' : 'Item'}');
          await handleClick();
        },
      ),
      DBusMenuItem(label: 'Disabled Item', enabled: false),
      DBusMenuItem(label: 'Invisible Item', visible: false),
      DBusMenuItem.separator(),
      DBusMenuItem(
        label: 'Submenu',
        children: [
          DBusMenuItem(
            label: 'Submenu 1',
            onClicked: () async => print('Submenu item 1 clicked!'),
          ),
          DBusMenuItem(
            label: 'Submenu 2',
            onClicked: () async => print('Submenu item 2 clicked!'),
          ),
          DBusMenuItem(
            label: 'Submenu 3',
            onClicked: () async => print('Submenu item 3 clicked!'),
          ),
        ],
      ),
      DBusMenuItem.separator(),
      DBusMenuItem.checkmark(
        'Checkmark',
        state: checkmarkIsActive,
        onClicked: () async {
          print('Toggled checkmark: ${!checkmarkIsActive}');
          await toggleCheckmark();
        },
      ),
      DBusMenuItem.separator(),
      DBusMenuItem.checkmark(
        'Radio 1',
        state: activeRadio == 1,
        onClicked: () async {
          print('Selected Radio 1');
          await setRadio(1);
        },
      ),
      DBusMenuItem.checkmark(
        'Radio 2',
        state: activeRadio == 2,
        onClicked: () async {
          print('Selected Radio 2');
          await setRadio(2);
        },
      ),
      DBusMenuItem.checkmark(
        'Radio 3',
        state: activeRadio == 3,
        onClicked: () async {
          print('Selected Radio 3');
          await setRadio(3);
        },
      ),
      DBusMenuItem.separator(),
      DBusMenuItem(
        label: 'Quit',
        onClicked: () async {
          print('Quit clicked');
          await client.close();
        },
      ),
    ],
  );
}

Future<void> rebuild() async {
  print('Rebuilding menu...');
  await client.updateMenu(buildMenu());
}

Future<void> handleClick() async {
  itemClicked = true;
  await rebuild();
}

Future<void> toggleCheckmark() async {
  checkmarkIsActive = !checkmarkIsActive;
  await rebuild();
}

Future<void> setRadio(int active) async {
  activeRadio = active;
  await rebuild();
}

StatusNotifierIconPixmap? loadIconPixmap(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    print('Warning: Icon file not found at $path');
    return null;
  }
  final image = img.decodeImage(file.readAsBytesSync());
  if (image == null) {
    print('Warning: Failed to decode icon at $path');
    return null;
  }
  // The FreeDesktop spec expects ARGB (network byte order),
  // which is often represented as ARGB in 32-bit integers.
  return StatusNotifierIconPixmap(
    width: image.width,
    height: image.height,
    pixels: image.getBytes(order: img.ChannelOrder.argb),
  );
}

void main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  print('Starting StatusNotifierItemClient example...');

  final requireWatcher = args.contains('--require-watcher');
  final iconByName = args.contains('--icon-by-name');
  final enableGnomeExtensionCheck = !args.contains('--disable-gnome-check');

  var backend = StatusNotifierItemBackend.auto;
  for (final arg in args) {
    if (arg.startsWith('--backend=')) {
      final value = arg.substring('--backend='.length);
      switch (value) {
        case 'kde':
          backend = StatusNotifierItemBackend.kde;
          break;
        case 'ayatana':
          backend = StatusNotifierItemBackend.ayatana;
          break;
        case 'spec':
          backend = StatusNotifierItemBackend.spec;
          break;
        case 'auto':
          backend = StatusNotifierItemBackend.auto;
          break;
        default:
          print('Unknown backend: $value');
      }
    }
  }

  print('Using backend: $backend');

  final iconPixmap = loadIconPixmap('example/icon.png');
  if (iconPixmap != null) {
    print(
      'Loaded icon from example/icon.png (${iconPixmap.width}x${iconPixmap.height})',
    );
  } else {
    print('Proceeding without PNG icon pixmap.');
  }

  client = StatusNotifierItemClient(
    id: 'dart-test',
    backend: backend,
    iconName: iconByName ? 'computer-fail-symbolic' : '',
    iconPixmap: (!iconByName) && iconPixmap != null ? [iconPixmap] : const [],
    menu: buildMenu(),
    onContextMenu: (x, y) async {
      print('onContextMenu called at ($x, $y)');
    },
    onActivate: (x, y) async {
      print('onActivate called at ($x, $y)');
    },
    onSecondaryActivate: (x, y) async {
      print('onSecondaryActivate called at ($x, $y)');
    },
    onScroll: (delta, orientation) async {
      print('onScroll called with delta $delta, orientation $orientation');
    },
  );

  client.onHostRegisteredChanged = (registered) async {
    print('Host registration changed. Is host registered? $registered');
  };

  print('Connecting to D-Bus...');
  try {
    await client.connect(
      requireWatcher: requireWatcher,
      enableGnomeExtensionCheck: enableGnomeExtensionCheck,
    );
    print('Connected successfully.');
  } catch (e) {
    print('Failed to connect: $e');
  }
}
