import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'admin_panel_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _userRole;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRole();

    // الاستماع لتغيرات حالة المصادقة في Supabase (تسجيل دخول / خروج)
    _supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        _checkAuthAndRole();
      }
    });
  }

  Future<void> _checkAuthAndRole() async {
    setState(() => _isLoading = true);

    try {
      final session = _supabase.auth.currentSession;

      if (session != null) {
        _isAuthenticated = true;
        final userId = session.user.id;

        // جلب نوع الحساب من جدول profiles الموحد
        final response = await _supabase
            .from('profiles')
            .select('account_type, user_type')
            .eq('id', userId)
            .maybeSingle();

        if (response != null) {
          final accountType = response['account_type']?.toString();
          final userType = response['user_type']?.toString();
          _userRole = accountType == 'admin' || userType == 'admin'
              ? 'admin'
              : (accountType ?? userType ?? 'individual');
        } else {
          _userRole = 'individual'; // القيمة الافتراضية في حال عدم وجود سجل
        }
      } else {
        _isAuthenticated = false;
        _userRole = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _userRole = null;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // حالة الانتظار أثناء التحقق من المصادقة أو الدور
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF003366),
          ),
        ),
      );
    }

    // إذا لم يكن المستخدم مسجلاً للدخول
    if (!_isAuthenticated) {
      return const LoginScreen();
    }

    // إذا كان المستخدم مسجلاً، نقوم بالتوجيه الذكي بناءً على الدور (Role)
    if (_userRole == 'admin') {
      return const AdminPanelScreen();
    } else {
      return const HomeScreen();
    }
  }
}
