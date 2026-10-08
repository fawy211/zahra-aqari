import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/views/home_screen.dart';
import 'package:aqari_app/views/login_screen.dart';
import 'package:aqari_app/views/auth_wrapper.dart';
import 'package:aqari_app/supabase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Supabase بالرابط والمفتاح
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: ZaharApp()));
}

class ZaharApp extends StatelessWidget {
  const ZaharApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'زهرة العقاري',
      // دعم الاتجاه من اليمين لليسار للغة العربية بشكل كامل
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003366),
          primary: const Color(0xFF003366),
        ),
      ),
      // AuthWrapper هو المسار الوحيد للمصادقة وتحديد صلاحية الحساب.
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
