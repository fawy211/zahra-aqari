import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/models/Office_Model.dart';

class OfficeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// دليل المكاتب العام؛ يقرأ الحقول المنشورة فقط من offices_public.
  /// يتم تحديث القائمة دورياً لأن Supabase Realtime لا يدعم بثّ الـ views مباشرة.
  Stream<List<OfficeModel>> getOffices() async* {
    Future<List<OfficeModel>> loadOffices() async {
      final rows = await _supabase
          .from('offices_public')
          .select()
          .order('created_at', ascending: false);

      return rows
          .map<OfficeModel>((row) => OfficeModel.fromMap(row))
          .toList();
    }

    yield await loadOffices();
    yield* Stream<void>.periodic(const Duration(seconds: 30))
        .asyncMap((_) => loadOffices());
  }

  /// جلب تفاصيل المكتب من العرض العام دون قراءة بياناته الخاصة.
  Future<OfficeModel?> getOfficeById(String officeId) async {
    try {
      final response = await _supabase
          .from('offices_public')
          .select()
          .eq('id', officeId)
          .maybeSingle();

      if (response == null) return null;
      return OfficeModel.fromMap(response);
    } catch (e) {
      debugPrint('خطأ في جلب تفاصيل المكتب: $e');
      return null;
    }
  }
}
