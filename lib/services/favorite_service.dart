import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // دالة لجلب المستخدم الحالي لتجنب تكرار الكود
  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  /// إضافة عقار للمفضلة أو إزالته مع معالجة الأخطاء
  Future<void> toggleFavorite(String propertyId) async {
    try {
      final userId = _currentUserId;
      if (userId.isEmpty) {
        throw Exception("يجب تسجيل الدخول لاستخدام المفضلة");
      }

      // التحقق هل العقار موجود مسبقاً في المفضلة
      final existingResponse = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', userId)
          .eq('property_id', propertyId)
          .maybeSingle();

      if (existingResponse != null) {
        // إذا كان موجوداً، يتم حذفه
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('property_id', propertyId);
      } else {
        // إذا لم يكن موجوداً، يتم إضافته
        await _supabase.from('favorites').insert({
          'user_id': userId,
          'property_id': propertyId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint("خطأ في خدمة المفضلة (toggleFavorite): $e");
      rethrow; // إعادة رمي الخطأ ليتم التعامل معه في الواجهة (UI)
    }
  }

  /// يتبع تدفق المفضلة جلسة الدخول الحالية، ويوقف تدفق الحساب السابق
  /// تلقائياً عند تسجيل الخروج أو تبديل المستخدم.
  Stream<bool> isFavorite(String propertyId) {
    return _supabase.auth.onAuthStateChange.asyncExpand((_) {
      final userId = _currentUserId;
      if (userId.isEmpty) return Stream<bool>.value(false);

      return _supabase
          .from('favorites')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((rows) => rows.any((row) => row['property_id'] == propertyId));
    }).handleError((error) {
      debugPrint("خطأ في تدفق المفضلة (isFavorite): $error");
    });
  }

  /// جلب مفضلات المستخدم الحالي مع إعادة الربط تلقائياً عند تغير الجلسة.
  Stream<List<Map<String, dynamic>>> getFavorites() {
    return _supabase.auth.onAuthStateChange.asyncExpand((_) {
      final userId = _currentUserId;
      if (userId.isEmpty) {
        return Stream<List<Map<String, dynamic>>>.value([]);
      }

      return _supabase
          .from('favorites')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .map((rows) => rows.cast<Map<String, dynamic>>());
    }).handleError((error) {
      debugPrint("خطأ في جلب المفضلات (getFavorites): $error");
    });
  }
}
