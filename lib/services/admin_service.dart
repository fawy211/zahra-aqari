import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/models/property_models.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // تخزين مؤقت سريع لتجنب استعلامات Supabase المتكررة لنفس الجلسة
  Map<String, dynamic>? _cachedAdminData;
  String? _cachedUserId;

  /// التحقق مما إذا كان المستخدم الحالي مشرفاً
  Future<bool> isAdmin() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return false;

    // استخدام الكاش إذا كان نفس المستخدم
    if (_cachedUserId == currentUser.id && _cachedAdminData != null) {
      return true;
    }

    try {
      final response = await _supabase
          .from('admins')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response != null) {
        _cachedUserId = currentUser.id;
        _cachedAdminData = response;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// جلب صلاحيات المشرف مع الاستفادة من الكاش
  Future<Map<String, dynamic>?> getAdminPermissions() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return null;

    if (_cachedUserId == currentUser.id && _cachedAdminData != null) {
      return _cachedAdminData;
    }

    try {
      final response = await _supabase
          .from('admins')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response != null) {
        _cachedUserId = currentUser.id;
        _cachedAdminData = response;
        return _cachedAdminData;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// التحقق من صلاحية معينة
  Future<bool> hasPermission(String permission) async {
    Map<String, dynamic>? adminData = await getAdminPermissions();
    if (adminData == null) return false;

    List<dynamic> permissions =
        (adminData['permissions'] as List<dynamic>?) ?? [];
    String role = (adminData['role'] as String?) ?? 'user';

    return permissions.contains(permission) || role == 'super_admin';
  }

  /// إضافة عقار جديد مع تواريخ دقيقة
  Future<void> addProperty(PropertyModel property) async {
    Map<String, dynamic> data = property.toMap();

    // تعيين تواريخ التوافق مع Supabase (ISO8601 Strings)
    data['created_at'] = DateTime.now().toIso8601String();
    data['expires_at'] =
        DateTime.now().add(const Duration(days: 90)).toIso8601String();

    // إزالة المعرف المؤقت إن وجد ليتولى Supabase إنشاؤه تلقائياً
    data.remove('id');

    await _supabase.from('properties').insert(data);
  }

  /// تنشيط الإعلان ورفعه لأعلى القائمة (Refresh)
  Future<void> refreshProperty(String propertyId) async {
    await _supabase.from('properties').update({
      'last_refreshed': DateTime.now().toIso8601String(),
    }).eq('id', propertyId);
  }

  /// تمييز الإعلان لفترة محددة بالأيام
  Future<void> featureProperty(String propertyId, int days) async {
    DateTime expiryDate = DateTime.now().add(Duration(days: days));
    await _supabase.from('properties').update({
      'is_featured': true,
      'featured_until': expiryDate.toIso8601String(),
    }).eq('id', propertyId);
  }

  /// جلب العقارات التي تم الإبلاغ عنها باستخدام Realtime Streams في Supabase
  Stream<List<PropertyModel>> getReportedProperties() {
    return _supabase
        .from('properties')
        .stream(primaryKey: ['id'])
        .eq('is_reported', true)
        .map((rows) {
          // يمكن الترتيب محلياً أو الاعتماد على دفق البيانات
          rows.sort((a, b) =>
              (b['report_count'] ?? 0).compareTo(a['report_count'] ?? 0));
          return rows
              .map((row) =>
                  PropertyModel.fromMap(row, id: row['id']?.toString()))
              .toList();
        });
  }

  /// معالجة البلاغ (إما الحذف النهائي أو إعادة تعيين حالة البلاغ)
  Future<void> resolveReport(String propertyId, {bool delete = false}) async {
    try {
      if (delete) {
        await _supabase.from('properties').delete().eq('id', propertyId);
      } else {
        await _supabase.from('properties').update({
          'is_reported': false,
          'report_count': 0,
        }).eq('id', propertyId);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// مسح الكاش عند تسجيل الخروج
  void clearCache() {
    _cachedAdminData = null;
    _cachedUserId = null;
  }
}
