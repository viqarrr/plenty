import 'package:flutter/material.dart';

/// Navigation helper extension methods on [BuildContext].
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
}
