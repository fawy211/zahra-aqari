import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'admin_panel_screen.dart';
import '../services/admin_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  bool _isAdmin = false;
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
        // قرار الإدارة يُقرأ من جدول admins المتحكم به من الخادم، وليس من
        // profiles.account_type القابل للكتابة من العميل، حتى لا يستطيع أي
        // مستخدم منح نفسه صلاحية الإدارة.
        _isAdmin = await _adminService.isAdmin();
      } else {
        _isAuthenticated = false;
        _isAdmin = false;
      }
    } catch (e) {
      _isAuthenticated = false;
      _isAdmin = false;
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
    if (_isAdmin) {
      return const AdminPanelScreen();
    } else {
      return const HomeScreen();
    }
  }
}
