import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? get userProfile => _userProfile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<AuthState>? _authSubscription;
  bool _disposed = false;

  // تهيئة والاستماع لتغيرات الدخول والخروج
  AuthProvider() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        fetchUserProfile();
      } else {
        _userProfile = null;
        if (!_disposed) notifyListeners();
      }
    });
    if (currentUser != null) {
      fetchUserProfile();
    }
  }

  // جلب بيانات البروفايل من جدول profiles
  Future<void> fetchUserProfile() async {
    final requestedUserId = currentUser?.id;
    if (requestedUserId == null || _disposed) return;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', requestedUserId)
          .maybeSingle();

      // تجاهل نتيجة طلب قديم إذا تغير المستخدم أثناء تحميل البيانات.
      if (_disposed || currentUser?.id != requestedUserId) return;
      _userProfile = response;
      notifyListeners();
    } catch (e) {
      if (!_disposed && currentUser?.id == requestedUserId) {
        debugPrint('خطأ في جلب بيانات البروفايل: $e');
      }
    }
  }

  // تسجيل الدخول
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      if (!_disposed) notifyListeners();

      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (!_disposed) notifyListeners();
      debugPrint('خطأ في تسجيل الدخول: $e');
      return false;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _userProfile = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}
