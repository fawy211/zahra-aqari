import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/models/Company_Model.dart'; // تأكد من مسار المودل

class CompanyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// جلب كل الشركات العقارية المسجلة (Stream للتحديث اللحظي عبر Supabase Realtime)
  Stream<List<CompanyModel>> getCompanies() {
    return _supabase
        .from('companies')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
          return rows.map((row) => CompanyModel.fromMap(row)).toList();
        })
        .handleError((error) {
          debugPrint("خطأ في جلب الشركات العقارية: $error");
          return <CompanyModel>[];
        });
  }

  /// جلب تفاصيل شركة معينة بالـ ID
  Future<CompanyModel?> getCompanyById(String companyId) async {
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .eq('id', companyId)
          .maybeSingle();

      if (response != null) {
        return CompanyModel.fromMap(response);
      }
      return null;
    } catch (e) {
      debugPrint("خطأ في جلب تفاصيل الشركة: $e");
      return null;
    }
  }
}
