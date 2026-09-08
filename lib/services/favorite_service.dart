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

  /// التحقق هل العقار مفضل (Stream لتحديث الأيقونة لحظياً في الـ UI)
  Stream<bool> isFavorite(String propertyId) {
    final userId = _currentUserId;
    if (userId.isEmpty) {
      return Stream.value(false); // إذا لم يوجد مستخدم، فالعقار ليس مفضلاً
    }

    return _supabase
        .from('favorites')
        .stream(primaryKey: [
          'id'
        ]) // تأكد من أن جدول favorites يحتوي على عمود id كـ Primary Key
        .eq('user_id', userId)
        .map((rows) {
          return rows.any((row) => row['property_id'] == propertyId);
        })
        .handleError((error) {
          debugPrint("خطأ في تدفق المفضلة (isFavorite): $error");
          return false;
        });
  }

  /// جلب كل مفضلات المستخدم (تُرجع قائمة بالبيانات كـ Stream)
  Stream<List<Map<String, dynamic>>> getFavorites() {
    final userId = _currentUserId;
    if (userId.isEmpty) return Stream.value([]);

    return _supabase
        .from('favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false) // ترتيب المفضلات من الأحدث
        .map((rows) => rows.cast<Map<String, dynamic>>())
        .handleError((error) {
          debugPrint("خطأ في جلب المفضلات (getFavorites): $error");
          return <Map<String, dynamic>>[];
        });
  }
}
