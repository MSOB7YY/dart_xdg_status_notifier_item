# Changelog

## 1.1.2

* **Menu updates:** `DBusMenuObject.update` no longer throws when the new menu has a different shape, it exports it and lets hosts re-read the layout. Before, a single item appearing or disappearing left the menu frozen on its previous contents forever.

## 1.1.1

* **libdbusmenu hosts:** Implemented `GetGroupProperties`, without it menus rendered empty on Cinnamon (`xapp-sn-watcher`), XFCE and MATE.
* **Layout revision:** `GetLayout` and `LayoutUpdated` now report an increasing revision, so hosts re-fetch updated layouts.
* **Property filtering:** `GetLayout` and `GetGroupProperties` respect the requested `propertyNames`.
* **Spec fix:** Clicking an item no longer emits `ItemActivationRequested`, which asks hosts to open the menu.

## 1.1.0

* **Enhanced Developer Experience:** Updated `README.md` with more comprehensive examples to help new developers integrate the package more easily.
* **Improved Out-of-the-Box Compatibility:** The default backend mode is now `auto`, which includes fallbacks for `ayatana`, ensuring the status icon works correctly across a wider range of Linux desktop environments (like MATE and KDE) without manual configuration.
* **Streamlined CI/CD:** Added automated release workflows to build and upload example binaries (Linux) on GitHub release tags, and optimized CI concurrency cancellation to prevent conflicting workflow runs.
* **Code Health:** Enforced consistent code formatting (`dart format`) across the repository.

## 0.0.3

* Version bump to prepare for upcoming release

## 0.0.2

* Rename library file to `dart_xdg_status_notifier_item.dart` to match package name
* Update Dart SDK constraints

## 0.0.1

* Initial release
