import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/models/Company_Model.dart';

class CompanyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Public company directory. The view intentionally excludes contact details.
  /// Views are not streamed through Supabase Realtime, so refresh periodically.
  Stream<List<CompanyModel>> getCompanies() async* {
    Future<List<CompanyModel>> loadCompanies() async {
      try {
        final rows = await _supabase
            .from('companies_public')
            .select()
            .order('created_at', ascending: false);

        return rows
            .map<CompanyModel>((row) => CompanyModel.fromMap(row))
            .toList();
      } catch (e) {
        debugPrint('خطأ في جلب قائمة الشركات العامة: $e');
        return <CompanyModel>[];
      }
    }

    yield await loadCompanies();
    yield* Stream<void>.periodic(const Duration(seconds: 30))
        .asyncMap((_) => loadCompanies());
  }

  /// Public company details; private contact data is never selected here.
  Future<CompanyModel?> getCompanyById(String companyId) async {
    try {
      final response = await _supabase
          .from('companies_public')
          .select()
          .eq('id', companyId)
          .maybeSingle();

      if (response == null) return null;
      return CompanyModel.fromMap(response);
    } catch (e) {
      debugPrint('خطأ في جلب تفاصيل الشركة: $e');
      return null;
    }
  }
}
