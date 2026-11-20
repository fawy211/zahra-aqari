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
    if (!await isAdmin()) {
      throw Exception('غير مصرح لك بإضافة عقار من لوحة الإدارة.');
    }
    Map<String, dynamic> data = property.toMap();

    // تعيين التواريخ بصيغة UTC موحدة.
    data['created_at'] = DateTime.now().toUtc().toIso8601String();
    data['expires_at'] =
        DateTime.now().toUtc().add(const Duration(days: 90)).toIso8601String();

    // إزالة المعرف المؤقت إن وجد ليتولى Supabase إنشاؤه تلقائياً
    data.remove('id');

    await _supabase.from('properties').insert(data);
  }

  /// تنشيط الإعلان ورفعه لأعلى القائمة (Refresh)
  Future<void> refreshProperty(String propertyId) async {
    if (!await isAdmin()) {
      throw Exception('غير مصرح لك بتنشيط الإعلانات.');
    }
    final updated = await _supabase
        .from('properties')
        .update({'last_refreshed': DateTime.now().toUtc().toIso8601String()})
        .eq('id', propertyId)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw Exception('لم يتم العثور على الإعلان لتنشيطه.');
    }
  }

  /// تمييز الإعلان لفترة محددة بالأيام
  Future<void> featureProperty(String propertyId, int days) async {
    if (!await isAdmin()) {
      throw Exception('غير مصرح لك بتمييز الإعلانات.');
    }
    if (days <= 0 || days > 365) {
      throw ArgumentError('مدة التمييز يجب أن تكون بين يوم و365 يوماً.');
    }
    final expiryDate =
        DateTime.now().toUtc().add(Duration(days: days)).toIso8601String();
    final updated = await _supabase
        .from('properties')
        .update({
          'is_featured': true,
          'featured_until': expiryDate,
        })
        .eq('id', propertyId)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw Exception('لم يتم العثور على الإعلان لتمييزه.');
    }
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
      if (!await isAdmin()) {
        throw Exception('غير مصرح لك بمعالجة البلاغات.');
      }
      if (delete) {
        final deleted = await _supabase
            .from('properties')
            .delete()
            .eq('id', propertyId)
            .select('id')
            .maybeSingle();
        if (deleted == null) {
          throw Exception('لم يتم العثور على الإعلان لحذفه.');
        }
      } else {
        final updated = await _supabase
            .from('properties')
            .update({
              'is_reported': false,
              'report_count': 0,
            })
            .eq('id', propertyId)
            .select('id')
            .maybeSingle();
        if (updated == null) {
          throw Exception('لم يتم العثور على الإعلان لتحديث البلاغ.');
        }
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
