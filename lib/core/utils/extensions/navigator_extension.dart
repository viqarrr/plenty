import 'package:flutter/material.dart';

/// Navigation helper extension methods on [BuildContext].
///
/// NOTE: Single point of navigation and modal overlays in Plenty.
/// Do NOT invoke raw `Navigator.` or `showModalBottomSheet` / `showDialog` directly in feature widgets.
/// Always use these context extension methods.
extension ExtendedNavigator on BuildContext {
  /// Push a new [page] onto the navigation stack.
  Future<T?> push<T>(Widget page, {String? name}) {
    return Navigator.push<T>(
      this,
      MaterialPageRoute<T>(
        builder: (_) => page,
        settings: RouteSettings(name: name ?? page.runtimeType.toString()),
      ),
    );
  }

  /// Replace the current route with a new [page].
  Future<T?> pushReplacement<T, TO>(Widget page, {String? name, TO? result}) {
    return Navigator.pushReplacement<T, TO>(
      this,
      MaterialPageRoute<T>(
        builder: (_) => page,
        settings: RouteSettings(name: name ?? page.runtimeType.toString()),
      ),
      result: result,
    );
  }

  /// Push a new [page] and remove all previous routes from the stack.
  Future<T?> pushAndRemoveAll<T>(Widget page, {String? name}) {
    return Navigator.pushAndRemoveUntil<T>(
      this,
      MaterialPageRoute<T>(
        builder: (_) => page,
        settings: RouteSettings(name: name ?? page.runtimeType.toString()),
      ),
      (route) => false,
    );
  }

  /// Pop the top route off the navigation stack.
  void pop<T>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  /// Attempts to pop the current route safely.
  Future<bool> maybePop<T>([T? result]) {
    return Navigator.of(this).maybePop<T>(result);
  }

  /// Opens a modal bottom sheet with standard rounded corners and configuration.
  Future<T?> showAppBottomSheet<T>(
    Widget child, {
    bool isScrollControlled = true,
    Color backgroundColor = Colors.transparent,
    bool useRootNavigator = false,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      useRootNavigator: useRootNavigator,
      builder: (_) => child,
    );
  }

  /// Opens a modal dialog with standard configuration.
  Future<T?> showAppDialog<T>(
    Widget child, {
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      builder: (_) => child,
    );
  }
}
