import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/models/Office_Model.dart'; // تأكد من مسار المودل

class OfficeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// جلب كل المكاتب العقارية المسجلة (Stream للتحديث اللحظي عبر Supabase Realtime)
  Stream<List<OfficeModel>> getOffices() {
    return _supabase
        .from('offices')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
          return rows.map((row) => OfficeModel.fromMap(row)).toList();
        })
        .handleError((error) {
          debugPrint("خطأ في جلب المكاتب العقارية: $error");
          return <OfficeModel>[];
        });
  }

  /// جلب تفاصيل مكتب معين بالـ ID
  Future<OfficeModel?> getOfficeById(String officeId) async {
    try {
      final response = await _supabase
          .from('offices')
          .select()
          .eq('id', officeId)
          .maybeSingle();

      if (response != null) {
        return OfficeModel.fromMap(response);
      }
      return null;
    } catch (e) {
      debugPrint("خطأ في جلب تفاصيل المكتب: $e");
      return null;
    }
  }
}
