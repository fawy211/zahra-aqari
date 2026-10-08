import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart'; // تأكد من مطابقة اسم ملف شاشة تسجيل الدخول لديك

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Supabase (قم بتغيير القيم بما يناسب مشروعك)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة زهرة العقارية',
      debugShowCheckedModeBanner: false,
      // توحيد الاتجاه للغة العربية
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        primaryColor: const Color(0xFF003366),
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily:
            'Cairo', // يمكنك تغيير الخط حسب الرغبة أو حذفه للاستفادة من الافتراضي
      ),
      // مراقبة حالة المصادقة لتوجيه المستخدم تلقائياً
      home: const AuthGate(),
    );
  }
}

/// ويدجت مسؤولة عن فحص هل المستخدم مسجل الدخول أم لا بشكل لحظي
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // أثناء التحقق الأولي من الجلسة
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF003366),
              ),
            ),
          );
        }

        final session = snapshot.data?.session;

        // إذا وُجدت جلسة نشطة، انتقل للرئيسية، وإلا اعرض شاشة تسجيل الدخول
        if (session != null) {
          return const MainWrapper();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

/// ويدجت رئيسية لعرض المحتوى بعد تسجيل الدخول
class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية'),
        backgroundColor: const Color(0xFF003366),
      ),
      body: const Center(
        child: Text('مرحباً بك في منصة زهرة العقارية'),
      ),
    );
  }
}
