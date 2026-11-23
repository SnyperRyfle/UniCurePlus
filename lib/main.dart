import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniCurePlusApp());
}

/// UiTM Mobile eProcurement — PEMBEKAL (Supplier) flow.
class UniCurePlusApp extends StatelessWidget {
  const UniCurePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'UniCurePlus',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.isDark
              ? ThemeMode.dark
              : ThemeMode.light,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
