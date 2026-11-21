import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> submitPropertyReport({
    required String propertyId,
    required String reason,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول للإبلاغ عن إعلان.');
    }

    final normalizedReason = reason.trim();
    if (normalizedReason.length < 3 || normalizedReason.length > 500) {
      throw ArgumentError('سبب البلاغ يجب أن يكون بين 3 و500 حرف.');
    }

    try {
      await _supabase.from('reports').insert({
        'user_id': user.id,
        'target_type': 'property',
        'target_id': propertyId,
        'reason': normalizedReason,
      });
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception('سبق لك الإبلاغ عن هذا الإعلان.');
      }
      if (error.code == '42501') {
        throw Exception('غير مسموح بإرسال بلاغ على هذا الإعلان.');
      }
      rethrow;
    }
  }
}
