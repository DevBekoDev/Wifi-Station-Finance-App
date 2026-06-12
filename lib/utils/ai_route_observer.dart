import 'package:flutter/material.dart';

final ValueNotifier<String?> currentRouteName = ValueNotifier<String?>(null);

class AiRouteObserver extends NavigatorObserver {
  void _save(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null) {
      currentRouteName.value = name;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _save(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _save(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _save(previousRoute);
  }
}

final aiRouteObserver = AiRouteObserver();