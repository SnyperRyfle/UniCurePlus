import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _testDatabaseConnection();
  runApp(const FindProcurementApp());
}

Future<void> _testDatabaseConnection() async {
  final settings = ConnectionSettings(
    host: '10.0.2.2', // 10.0.2.2 points to localhost (XAMPP/MySQL) from Android Emulator
    port: 3307,
    user: 'root',
    password: '',     // Default XAMPP password
    db: 'uitm_intern_db',
  );

  try {
    final conn = await MySqlConnection.connect(settings);
    debugPrint('✅ MySQL Connected successfully!');
    await conn.close();
  } catch (e) {
    debugPrint('❌ Connection failed: $e');
  }
}


/// UiTM Mobile eProcurement — PEMBEKAL (Supplier) flow.
class FindProcurementApp extends StatelessWidget {
  const FindProcurementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FindProcurement+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
