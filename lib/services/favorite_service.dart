import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // دالة لجلب المستخدم الحالي لتجنب تكرار الكود
  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  /// إضافة عقار للمفضلة أو إزالته مع معالجة الأخطاء المحسّنة
  Future<void> toggleFavorite(String propertyId) async {
    try {
      final userId = _currentUserId;
      if (userId.isEmpty) {
        throw Exception("يجب تسجيل الدخول أولاً لاستخدام المفضلة");
      }

      if (propertyId.isEmpty) {
        throw Exception("معرّف العقار غير صحيح");
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
        debugPrint("✅ تم إزالة العقار من المفضلة");
      } else {
        // إذا لم يكن موجوداً، يتم إضافته
        await _supabase.from('favorites').insert({
          'user_id': userId,
          'property_id': propertyId,
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint("✅ تم إضافة العقار إلى المفضلة");
      }
    } on PostgrestException catch (e) {
      debugPrint("❌ خطأ في قاعدة البيانات (toggleFavorite): ${e.message}");
      if (e.code == 'PGRST205') {
        throw Exception("خطأ: جدول المفضلة غير موجود في قاعدة البيانات. يرجى التواصل مع الدعم.");
      }
      rethrow;
    } catch (e) {
      debugPrint("❌ خطأ غير متوقع (toggleFavorite): $e");
      throw Exception("حدث خطأ أثناء تحديث المفضلة: $e");
    }
  }

  /// التحقق هل العقار مفضل (Stream لتحديث الأيقونة لحظياً في الـ UI)
  Stream<bool> isFavorite(String propertyId) {
    final userId = _currentUserId;
    if (userId.isEmpty) {
      return Stream.value(false);
    }

    if (propertyId.isEmpty) {
      return Stream.value(false);
    }

    return _supabase
        .from('favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .handleError((error) {
          debugPrint("⚠️ خطأ في تدفق المفضلة (isFavorite): $error");
          if (error.toString().contains('PGRST205')) {
            debugPrint("⚠️ تحذير: جدول favorites غير موجود. تحقق من قاعدة البيانات.");
          }
          return [];
        })
        .map((rows) {
          try {
            return rows.any((row) => row['property_id'] == propertyId);
          } catch (e) {
            debugPrint("❌ خطأ في معالجة نتائج المفضلة: $e");
            return false;
          }
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
        .order('created_at', ascending: false)
        .handleError((error) {
          debugPrint("❌ خطأ في جلب المفضلات (getFavorites): $error");
          if (error.toString().contains('PGRST205')) {
            debugPrint("⚠️ تحذير: جدول favorites غير موجود.");
          }
          return [];
        })
        .map((rows) {
          try {
            return rows.cast<Map<String, dynamic>>();
          } catch (e) {
            debugPrint("❌ خطأ في معالجة قائمة المفضلات: $e");
            return <Map<String, dynamic>>[];
          }
        });
  }
}
