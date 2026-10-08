import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // تخزين مؤقت محلي للإعدادات لتجنب الاستعلامات المتكررة لنفس الجلسة
  final Map<String, Map<String, dynamic>> _settingsCache = {};

  /// جلب قيمة محددة من مستند الإعدادات (مع دعم الكاش والتخزين المؤقت)
  Future<T?> getSettingValue<T>(String docId, String fieldKey,
      {T? defaultValue}) async {
    try {
      // التحقق من الكاش أولاً
      if (_settingsCache.containsKey(docId) &&
          _settingsCache[docId]!.containsKey(fieldKey)) {
        return _settingsCache[docId]![fieldKey] as T?;
      }

      final response = await _supabase
          .from('app_settings')
          .select()
          .eq('id', docId)
          .maybeSingle();

      if (response != null) {
        Map<String, dynamic> data = Map<String, dynamic>.from(response);

        // حفظ المستند بالكامل في الكاش
        _settingsCache[docId] = data;

        if (data.containsKey(fieldKey)) {
          return data[fieldKey] as T?;
        }
      }
      return defaultValue;
    } catch (e) {
      debugPrint("خطأ في جلب الإعداد ($docId - $fieldKey): $e");
      return defaultValue;
    }
  }

  /// جلب محتوى نصي (متوافق مع الدالة القديمة لديك للتوافقية)
  Future<String> getAppSettings(String docId,
      {String fieldKey = 'content'}) async {
    try {
      String? result = await getSettingValue<String>(docId, fieldKey);
      return result ?? "لم يتم إضافة محتوى بعد.";
    } catch (e) {
      return "خطأ في الاتصال بالخادم.";
    }
  }

  /// مسح الكاش عند الحاجة (مثلاً عند تحديث الإعدادات من لوحة التحكم)
  void clearCache() {
    _settingsCache.clear();
  }
}
