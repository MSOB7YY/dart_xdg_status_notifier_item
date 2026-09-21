import 'package:dbus/dbus.dart';
import 'package:dart_xdg_status_notifier_item/src/dbus_menu_object.dart';
import 'package:test/test.dart';

void main() {
  test(
    'DBusMenuObject out-of-bounds item id returns UnknownId error',
    () async {
      // Create a simple menu with one item.
      // Menu root is item 0.
      final rootMenu = DBusMenuItem(
        children: [
          DBusMenuItem(label: 'Item 1'), // Item 1
        ],
      );

      // Creates DBusMenuObject which registers ids recursively.
      // _items will contain 2 items: root (0), and "Item 1" (1).
      final menuObject = DBusMenuObject(DBusObjectPath('/MenuBar'), rootMenu);

      // Try to call AboutToShow with an out-of-bounds id (id = 2).
      final methodCall = DBusMethodCall(
        sender: 'org.freedesktop.DBus',
        interface: 'com.canonical.dbusmenu',
        name: 'AboutToShow',
        values: [DBusInt32(2)],
      );

      final response = await menuObject.handleMethodCall(methodCall);

      expect(response, isA<DBusMethodErrorResponse>());
      final errorResponse = response as DBusMethodErrorResponse;
      expect(errorResponse.errorName, 'com.canonical.dbusmenu.UnknownId');
    },
  );

  test('DBusMenuObject in-bounds item id returns success', () async {
    final rootMenu = DBusMenuItem(
      children: [
        DBusMenuItem(label: 'Item 1'), // Item 1
      ],
    );

    final menuObject = DBusMenuObject(DBusObjectPath('/MenuBar'), rootMenu);

    // Call AboutToShow with an in-bounds id (id = 1).
    final methodCall = DBusMethodCall(
      sender: 'org.freedesktop.DBus',
      interface: 'com.canonical.dbusmenu',
      name: 'AboutToShow',
      values: [DBusInt32(1)],
    );

    final response = await menuObject.handleMethodCall(methodCall);

    expect(response, isA<DBusMethodSuccessResponse>());
  });

  test('DBusMenuObject EventGroup parses struct correctly', () async {
    final rootMenu = DBusMenuItem(
      children: [
        DBusMenuItem(label: 'Item 1'), // Item 1
      ],
    );

    final menuObject = DBusMenuObject(DBusObjectPath('/MenuBar'), rootMenu);

    // Call EventGroup with an in-bounds id (id = 1).
    final methodCall = DBusMethodCall(
      sender: 'org.freedesktop.DBus',
      interface: 'com.canonical.dbusmenu',
      name: 'EventGroup',
      values: [
        DBusArray(DBusSignature('(isvu)'), [
          DBusStruct([
            DBusInt32(1), // id
            DBusString('clicked'), // eventId
            DBusVariant(DBusString('')), // data
            DBusUint32(0), // timestamp
          ]),
        ]),
      ],
    );

    final response = await menuObject.handleMethodCall(methodCall);

    expect(response, isA<DBusMethodSuccessResponse>());
    final successResponse = response as DBusMethodSuccessResponse;
    expect(successResponse.values.length, 1);
    expect(successResponse.values[0].signature.value, 'ai');
    final idErrors = successResponse.values[0].asInt32Array().toList();
    expect(idErrors, isEmpty);
  });

  test('DBusMenuObject GetGroupProperties returns requested items', () async {
    final rootMenu = DBusMenuItem(
      children: [
        DBusMenuItem(label: 'Item 1', enabled: false), // Item 1
        DBusMenuItem.separator(), // Item 2
      ],
    );

    final menuObject = DBusMenuObject(DBusObjectPath('/MenuBar'), rootMenu);

    final methodCall = DBusMethodCall(
      sender: 'org.freedesktop.DBus',
      interface: 'com.canonical.dbusmenu',
      name: 'GetGroupProperties',
      values: [
        DBusArray.int32([1, 2, 5]),
        DBusArray.string([]),
      ],
    );

    final response = await menuObject.handleMethodCall(methodCall);

    expect(response, isA<DBusMethodSuccessResponse>());
    final values = (response as DBusMethodSuccessResponse).values;
    expect(values.length, 1);
    expect(values[0].signature.value, 'a(ia{sv})');
    final items = values[0].asArray().map((e) => e.asStruct()).toList();
    expect(items.map((e) => e[0].asInt32()), [1, 2]);
    expect(items[0][1].asStringVariantDict(), {
      'enabled': DBusBoolean(false),
      'label': DBusString('Item 1'),
    });
    expect(items[1][1].asStringVariantDict(), {
      'type': DBusString('separator'),
      'visible': DBusBoolean(true),
    });
  });

  test(
    'DBusMenuObject GetGroupProperties returns all items filtered by names',
    () async {
      final rootMenu = DBusMenuItem(
        children: [
          DBusMenuItem(label: 'Item 1', enabled: false), // Item 1
        ],
      );

      final menuObject = DBusMenuObject(DBusObjectPath('/MenuBar'), rootMenu);

      final methodCall = DBusMethodCall(
        sender: 'org.freedesktop.DBus',
        interface: 'com.canonical.dbusmenu',
        name: 'GetGroupProperties',
        values: [
          DBusArray.int32([]),
          DBusArray.string(['label']),
        ],
      );

      final response = await menuObject.handleMethodCall(methodCall);

      final values = (response as DBusMethodSuccessResponse).values;
      final items = values[0].asArray().map((e) => e.asStruct()).toList();
      expect(items.map((e) => e[0].asInt32()), [0, 1]);
      expect(items[0][1].asStringVariantDict(), isEmpty);
      expect(items[1][1].asStringVariantDict(), {
        'label': DBusString('Item 1'),
      });
    },
  );

  test('DBusMenuObject.update increases GetLayout revision', () async {
    final rootMenu = DBusMenuItem(
      children: [
        DBusMenuItem(label: 'Item 1'), // Item 1
      ],
    );

    final menuObject = DBusMenuObject(DBusObjectPath('/MenuBar'), rootMenu);

    Future<int> getRevision() async {
      final response = await menuObject.handleMethodCall(
        DBusMethodCall(
          sender: 'org.freedesktop.DBus',
          interface: 'com.canonical.dbusmenu',
          name: 'GetLayout',
          values: [DBusInt32(0), DBusInt32(-1), DBusArray.string([])],
        ),
      );
      return (response as DBusMethodSuccessResponse).values[0].asUint32();
    }

    final initialRevision = await getRevision();
    await menuObject.update(
      DBusMenuItem(
        children: [
          DBusMenuItem(label: 'Item 1 updated'),
        ],
      ),
    );
    expect(await getRevision(), greaterThan(initialRevision));
  });

  test('DBusMenuObject.update exports a menu whose children count changed', () async {
    final rootMenu = DBusMenuItem(
      children: [
        DBusMenuItem(label: 'Item 1'), // Item 1
      ],
    );

    final menuObject = DBusMenuObject(DBusObjectPath('/MenuBar'), rootMenu);

    Future<DBusMethodSuccessResponse> getLayout() async {
      final response = await menuObject.handleMethodCall(
        DBusMethodCall(
          sender: 'org.freedesktop.DBus',
          interface: 'com.canonical.dbusmenu',
          name: 'GetLayout',
          values: [DBusInt32(0), DBusInt32(-1), DBusArray.string([])],
        ),
      );
      return response as DBusMethodSuccessResponse;
    }

    final initialRevision = (await getLayout()).values[0].asUint32();

    await menuObject.update(
      DBusMenuItem(
        children: [
          DBusMenuItem(label: 'Item 1 updated'),
          DBusMenuItem(label: 'Item 2 added'),
        ],
      ),
    );

    final layout = await getLayout();
    expect(layout.values[0].asUint32(), greaterThan(initialRevision));

    final children = layout.values[1].asStruct()[2].asArray().map((e) => e.asVariant().asStruct()).toList();
    expect(children.length, 2);
    expect(children[0][1].asStringVariantDict()['label'], DBusString('Item 1 updated'));
    expect(children[1][1].asStringVariantDict()['label'], DBusString('Item 2 added'));
  });
}
