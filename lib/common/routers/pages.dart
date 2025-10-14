import 'package:album/common/routers/names.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:album/pages/splash/index.dart';

class RoutePages {
  static final RouteObserver<Route> observer = RouteObserver();
  static List<String> history = [];

  static List<GetPage> get list => [
    GetPage(
      name: RouteNames.splash,
      page: () => SplashPage(),
      binding: SplashBinding(),
    ),
  ];
}
