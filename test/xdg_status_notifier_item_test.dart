import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:dart_xdg_status_notifier_item/dart_xdg_status_notifier_item.dart';

import 'package:test/test.dart';

class MockNotifierWatcherObject extends DBusObject {
  final String namespace;

  MockNotifierWatcherObject(this.namespace)
      : super(DBusObjectPath('/StatusNotifierWatcher'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != '$namespace.StatusNotifierWatcher') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      case 'RegisterStatusNotifierItem':
        return DBusMethodSuccessResponse();

      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }
}

class MockDBusObject extends DBusObject {
  final String namespace;
  MockDBusObject(this.namespace)
      : super(DBusObjectPath('/org/freedesktop/DBus'));

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.freedesktop.DBus' &&
        methodCall.name == 'NameHasOwner') {
      String name = methodCall.values[0].asString();
      if (name == '$namespace.StatusNotifierWatcher') {
        return DBusMethodSuccessResponse([DBusBoolean(true)]);
      }
      return DBusMethodSuccessResponse([DBusBoolean(false)]);
    }
    return DBusMethodErrorResponse.unknownMethod();
  }
}

class MockNotifierWatcherServer extends DBusClient {
  late final MockNotifierWatcherObject _root;
  late final MockDBusObject _dbusRoot;
  final String namespace;

  MockNotifierWatcherServer(DBusAddress clientAddress, this.namespace)
      : super(clientAddress) {
    _root = MockNotifierWatcherObject(namespace);
    _dbusRoot = MockDBusObject(namespace);
  }

  Future<void> start() async {
    await requestName('org.freedesktop.DBus');
    await requestName('$namespace.StatusNotifierWatcher');
    await registerObject(_root);
    await registerObject(_dbusRoot);
  }
}

void main() {
  test('connect (spec backend)', () async {
    var server = DBusServer();
    var clientAddress = await server.listenAddress(
      DBusAddress.unix(dir: Directory.systemTemp),
    );
    addTearDown(() async {
      await server.close();
    });

    var watcher = MockNotifierWatcherServer(clientAddress, 'org.freedesktop');
    await watcher.start();
    addTearDown(() async {
      await watcher.close();
    });

    var client = StatusNotifierItemClient(
      id: 'test',
      backend: StatusNotifierItemBackend.spec,
      menu: DBusMenuItem(),
      bus: DBusClient(clientAddress),
    );
    addTearDown(() async {});
    await client.connect();
  });

  test('connect (kde backend)', () async {
    var server = DBusServer();
    var clientAddress = await server.listenAddress(
      DBusAddress.unix(dir: Directory.systemTemp),
    );
    addTearDown(() async {
      await server.close();
    });

    var watcher = MockNotifierWatcherServer(clientAddress, 'org.kde');
    await watcher.start();
    addTearDown(() async {
      await watcher.close();
    });

    var client = StatusNotifierItemClient(
      id: 'test',
      backend: StatusNotifierItemBackend.kde,
      menu: DBusMenuItem(),
      bus: DBusClient(clientAddress),
    );
    addTearDown(() async {});
    await client.connect();
  });

  test('connect (ayatana backend)', () async {
    var server = DBusServer();
    var clientAddress = await server.listenAddress(
      DBusAddress.unix(dir: Directory.systemTemp),
    );
    addTearDown(() async {
      await server.close();
    });

    var watcher = MockNotifierWatcherServer(
      clientAddress,
      'org.ayatana.appindicator',
    );
    await watcher.start();
    addTearDown(() async {
      await watcher.close();
    });

    var client = StatusNotifierItemClient(
      id: 'test',
      backend: StatusNotifierItemBackend.ayatana,
      menu: DBusMenuItem(),
      bus: DBusClient(clientAddress),
    );
    addTearDown(() async {});
    await client.connect();
  });

  test('property changes', () async {
    var server = DBusServer();
    var clientAddress = await server.listenAddress(
      DBusAddress.unix(dir: Directory.systemTemp),
    );
    addTearDown(() async {
      await server.close();
    });

    var watcher = MockNotifierWatcherServer(clientAddress, 'org.freedesktop');
    await watcher.start();
    addTearDown(() async {
      await watcher.close();
    });

    var client = StatusNotifierItemClient(
      id: 'test',
      backend: StatusNotifierItemBackend.spec,
      menu: DBusMenuItem(
        children: [DBusMenuItem(label: 'Test', status: DBusMenuStatus.normal)],
      ),
      bus: DBusClient(clientAddress),
    );
    addTearDown(() async {});
    await client.connect();

    expect(client.status, StatusNotifierItemStatus.active);
    client.status = StatusNotifierItemStatus.passive;
    expect(client.status, StatusNotifierItemStatus.passive);

    client.title = 'test';
    expect(client.title, 'test');
    client.title = 'new test';
    expect(client.title, 'new test');
  });

  group('StatusNotifierItemClient actions', () {
    test('ContextMenu correctly parses coordinates', () async {
      int? resultX;
      int? resultY;
      var client = StatusNotifierItemClient(
        id: 'test',
        menu: DBusMenuItem(),
        onContextMenu: (x, y) async {
          resultX = x;
          resultY = y;
        },
      );

      var object = client.notifierItemObjectForTest;
      var methodCall = DBusMethodCall(
        sender: 'org.freedesktop.DBus',
        interface: 'org.freedesktop.StatusNotifierItem',
        name: 'ContextMenu',
        values: [DBusInt32(10), DBusInt32(20)],
      );

      var response = await object.handleMethodCall(methodCall);
      expect(response, isA<DBusMethodSuccessResponse>());
      expect(resultX, 10);
      expect(resultY, 20);
    });

    test('Activate correctly parses coordinates', () async {
      int? resultX;
      int? resultY;
      var client = StatusNotifierItemClient(
        id: 'test',
        menu: DBusMenuItem(),
        onActivate: (x, y) async {
          resultX = x;
          resultY = y;
        },
      );

      var object = client.notifierItemObjectForTest;
      var methodCall = DBusMethodCall(
        sender: 'org.freedesktop.DBus',
        interface: 'org.freedesktop.StatusNotifierItem',
        name: 'Activate',
        values: [DBusInt32(15), DBusInt32(25)],
      );

      var response = await object.handleMethodCall(methodCall);
      expect(response, isA<DBusMethodSuccessResponse>());
      expect(resultX, 15);
      expect(resultY, 25);
    });

    test('SecondaryActivate correctly parses coordinates', () async {
      int? resultX;
      int? resultY;
      var client = StatusNotifierItemClient(
        id: 'test',
        menu: DBusMenuItem(),
        onSecondaryActivate: (x, y) async {
          resultX = x;
          resultY = y;
        },
      );

      var object = client.notifierItemObjectForTest;
      var methodCall = DBusMethodCall(
        sender: 'org.freedesktop.DBus',
        interface: 'org.freedesktop.StatusNotifierItem',
        name: 'SecondaryActivate',
        values: [DBusInt32(30), DBusInt32(40)],
      );

      var response = await object.handleMethodCall(methodCall);
      expect(response, isA<DBusMethodSuccessResponse>());
      expect(resultX, 30);
      expect(resultY, 40);
    });

    test('Scroll correctly parses delta and orientation', () async {
      int? resultDelta;
      String? resultOrientation;
      var client = StatusNotifierItemClient(
        id: 'test',
        menu: DBusMenuItem(),
        onScroll: (delta, orientation) async {
          resultDelta = delta;
          resultOrientation = orientation;
        },
      );

      var object = client.notifierItemObjectForTest;
      var methodCall = DBusMethodCall(
        sender: 'org.freedesktop.DBus',
        interface: 'org.freedesktop.StatusNotifierItem',
        name: 'Scroll',
        values: [DBusInt32(5), DBusString('horizontal')],
      );

      var response = await object.handleMethodCall(methodCall);
      expect(response, isA<DBusMethodSuccessResponse>());
      expect(resultDelta, 5);
      expect(resultOrientation, 'horizontal');
    });
  });

  test(
    'Update DBus Menu item Status properties and manage state dynamically',
    () async {
      var client = StatusNotifierItemClient(id: 'test', menu: DBusMenuItem());

      var object = client.menuObjectForTest;

      var response = await object.getProperty(
        'com.canonical.dbusmenu',
        'Status',
      );
      expect(response, isA<DBusMethodSuccessResponse>());
      expect(
        (response as DBusMethodSuccessResponse)
            .returnValues[0]
            .asVariant()
            .asString(),
        'normal',
      );

      // Dynamically change menu status
      client.menuStatus = 'notice';

      response = await object.getProperty('com.canonical.dbusmenu', 'Status');
      expect(response, isA<DBusMethodSuccessResponse>());
      expect(
        (response as DBusMethodSuccessResponse)
            .returnValues[0]
            .asVariant()
            .asString(),
        'notice',
      );
    },
  );

  test('Icon name and markup sanitization', () async {
    var client = StatusNotifierItemClient(id: 'test', menu: DBusMenuItem());

    // Test icon name sanitization
    client.iconName = 'test-icon-name\n\r';
    expect(client.iconName, 'test-icon-name');

    client.attentionIconName = 'test-attention\n';
    expect(client.attentionIconName, 'test-attention');

    // Test tool tip sanitization
    client.toolTip = StatusNotifierToolTip(
      iconName: 'tooltip-icon\n',
      iconPixmap: [],
      title: '<b>Bold Title</b>',
      body: '<i>Italic Body</i>',
    );
    expect(client.toolTip?.iconName, 'tooltip-icon');

    // Escaping test
    var original = '<b>Bold</b> & "Quotes"';
    expect(
      escapeMarkup(original),
      '&lt;b&gt;Bold&lt;/b&gt; &amp; &quot;Quotes&quot;',
    );

    // Strip test
    expect(stripMarkup(original), 'Bold & "Quotes"');
  });
}
