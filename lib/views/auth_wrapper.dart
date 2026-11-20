import 'dart:async';

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
  String? _authCheckError;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRole();

    // الاستماع لتغيرات حالة المصادقة في Supabase (تسجيل دخول / خروج)
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      // لا نعيد استخدام صلاحيات إدارية مخزنة بعد تغير جلسة المصادقة.
      _adminService.clearCache();
      if (mounted) {
        _checkAuthAndRole();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthAndRole() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _authCheckError = null;
    });

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
      // لا نعتبر المستخدم خارج الجلسة بسبب فشل الشبكة/فحص الدور.
      _authCheckError = 'تعذر التحقق من الحساب والصلاحيات. تحقق من الاتصال وحاول مرة أخرى.';
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

    if (_authCheckError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                Text(_authCheckError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _checkAuthAndRole,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
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
