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

  test(
    'DBusMenuObject.update throws ArgumentError if children count changes',
    () async {
      final rootMenu = DBusMenuItem(
        children: [
          DBusMenuItem(label: 'Item 1'), // Item 1
        ],
      );

      final menuObject = DBusMenuObject(DBusObjectPath('/MenuBar'), rootMenu);
      final updatedMenu = DBusMenuItem(
        children: [
          DBusMenuItem(label: 'Item 1 updated'),
          DBusMenuItem(label: 'Item 2 added'),
        ],
      );

      expect(
        () => menuObject.update(updatedMenu),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Updated menu must have the same number of items as the previous menu.',
          ),
        ),
      );
    },
  );
}
