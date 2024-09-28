import 'package:flutter/material.dart';
import 'package:store/features/authentication/view/splash_screen/splash_screen.dart';
import 'package:store/providers/app_provider.dart';
import 'package:store/utils/theme/theme.dart';

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({Key? key, required this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Empathia',
        theme: TAppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
