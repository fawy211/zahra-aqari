import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? get userProfile => _userProfile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // تهيئة والاستماع لتغيرات الدخول والخروج
  AuthProvider() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        fetchUserProfile();
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
    if (currentUser != null) {
      fetchUserProfile();
    }
  }

  // جلب بيانات البروفايل من جدول profiles
  Future<void> fetchUserProfile() async {
    if (currentUser == null) return;
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      _userProfile = response;
      notifyListeners();
    } catch (e) {
      print('خطأ في جلب بيانات البروفايل: $e');
    }
  }

  // تسجيل الدخول
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('خطأ في تسجيل الدخول: $e');
      return false;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _userProfile = null;
    notifyListeners();
  }
}
