import 'package:album/common/routers/names.dart';
import 'package:album/common/routers/pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '相册',

      initialRoute: RouteNames.splash,
      getPages: RoutePages.list,
      navigatorObservers: [RoutePages.observer],
    );
  }
}
