import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/models/property_models.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // تخزين مؤقت سريع لتجنب استعلامات Supabase المتكررة لنفس الجلسة
  Map<String, dynamic>? _cachedAdminData;
  String? _cachedUserId;
  DateTime? _adminCacheExpiresAt;

  static const Duration _adminCacheTtl = Duration(minutes: 2);

  bool get _hasValidAdminCache =>
      _cachedAdminData != null &&
      _cachedUserId == _supabase.auth.currentUser?.id &&
      _adminCacheExpiresAt != null &&
      DateTime.now().isBefore(_adminCacheExpiresAt!);

  void _clearAdminCache() {
    _cachedAdminData = null;
    _cachedUserId = null;
    _adminCacheExpiresAt = null;
  }

  void _storeAdminCache(String userId, Map<String, dynamic> data) {
    _cachedUserId = userId;
    _cachedAdminData = data;
    _adminCacheExpiresAt = DateTime.now().add(_adminCacheTtl);
  }

  /// التحقق مما إذا كان المستخدم الحالي مشرفاً
  Future<bool> isAdmin() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _clearAdminCache();
      return false;
    }

    if (_hasValidAdminCache) return true;

    try {
      final response = await _supabase
          .from('admins')
          .select('user_id, role')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response != null) {
        _storeAdminCache(currentUser.id, response);
        return true;
      }
      _clearAdminCache();
      return false;
    } catch (e) {
      _clearAdminCache();
      return false;
    }
  }

  /// جلب صلاحيات المشرف مع الاستفادة من الكاش
  Future<Map<String, dynamic>?> getAdminPermissions() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _clearAdminCache();
      return null;
    }

    if (_hasValidAdminCache) return _cachedAdminData;

    try {
      final response = await _supabase
          .from('admins')
          .select('user_id, role')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response != null) {
        _storeAdminCache(currentUser.id, response);
        return _cachedAdminData;
      }
      _clearAdminCache();
    } catch (e) {
      _clearAdminCache();
      return null;
    }
    return null;
  }

  /// التحقق من صلاحية معينة
  Future<bool> hasPermission(String permission) async {
    Map<String, dynamic>? adminData = await getAdminPermissions();
    if (adminData == null) return false;

    // The admins table has no permissions column. Until granular permissions
    // are defined server-side, only super_admin receives explicit permission
    // checks; all other roles are denied by default.
    final role = (adminData['role'] as String?)?.trim().toLowerCase();
    return role == 'super_admin';
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
    final now = DateTime.now().toUtc();
    final expiryDate =
        now.add(Duration(days: days)).toIso8601String();
    // لا نميز إعلاناً قيد المراجعة أو مرفوضاً أو انتهت صلاحيته.
    final updated = await _supabase
        .from('properties')
        .update({
          'is_featured': true,
          'featured_until': expiryDate,
        })
        .eq('id', propertyId)
        .eq('status', 'verified')
        .or('expires_at.is.null,expires_at.gt.${now.toIso8601String()}')
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw Exception(
        'لم يتم تمييز الإعلان. تأكد أنه معتمد وما زال سارياً.',
      );
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
    _clearAdminCache();
  }
}
