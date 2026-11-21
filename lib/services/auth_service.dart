import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// دالة إنشاء الحساب وحفظ بياناته الأساسية بشكل آمن
  Future<void> registerUser({
    required String email,
    required String password,
    required Map<String, dynamic> userMap,
  }) async {
    try {
      // 1. إنشاء المستخدم في Supabase Auth
      AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('فشل في إنشاء حساب المستخدم.');
      }

      String uid = user.id;

      // 2. حفظ الأعمدة المعروفة فقط في profiles.
      // لا نكتب في users أو wallets قبل اعتماد مخططهما وسياسات RLS الخاصة بهما.
      // نوع الحساب والصلاحيات الحساسة تُحددها قاعدة البيانات، وليس بيانات العميل.

      await _supabase.from('profiles').insert({
        'id': uid,
        'email': email,
        'name': userMap['name'] ?? userMap['full_name'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow; // إعادة رمي الخطأ ليتم التعامل معه في واجهة المستخدم
    }
  }

  /// دالة تسجيل الدخول
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// دالة تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// جلب بيانات المستخدم الحالي من جدول profiles
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }
}
