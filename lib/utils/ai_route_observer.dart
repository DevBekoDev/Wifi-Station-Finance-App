import 'package:flutter/material.dart';
import 'package:wsfm/utils/app_routes.dart';

final ValueNotifier<String?> currentRouteName =
    ValueNotifier<String?>(AppRoutes.start);

class AiRouteObserver extends NavigatorObserver {
  void _save(Route<dynamic>? route) {
    currentRouteName.value = route?.settings.name;
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