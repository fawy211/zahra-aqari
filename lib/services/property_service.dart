import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/models/property_models.dart';

class PropertyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// جلب كل العقارات النشطة وغير المنتهية الصلاحية
  Stream<List<PropertyModel>> getActiveProperties() {
    return _supabase.from('properties').stream(primaryKey: ['id']).map((rows) {
      // مقارنة التواريخ كـ DateTime لتجنب أخطاء مقارنة النصوص واختلاف المناطق الزمنية.
      final now = DateTime.now().toUtc();
      final activeRows = rows.where((row) {
        if (row['status'] != 'verified') return false;
        final rawExpiry = row['expires_at']?.toString();
        if (rawExpiry == null || rawExpiry.isEmpty) return true;
        final expiry = DateTime.tryParse(rawExpiry)?.toUtc();
        return expiry != null && expiry.isAfter(now);
      }).toList();

      // الترتيب: حسب تاريخ الإنشاء من الأحدث
      activeRows.sort((a, b) {
        final dateA = a['created_at']?.toString() ?? '';
        final dateB = b['created_at']?.toString() ?? '';
        return dateB.compareTo(dateA);
      });

      return activeRows
          .map((row) => PropertyModel.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    }).handleError((error) {
      debugPrint("خطأ في جلب العقارات النشطة: $error");
      return <PropertyModel>[];
    });
  }

  /// جلب عقارات مميزة (Featured Properties)
  Stream<List<PropertyModel>> getFeaturedProperties() {
    return _supabase.from('properties').stream(primaryKey: ['id']).map((rows) {
      final now = DateTime.now().toUtc();
      final featuredRows = rows.where((row) {
        if (row['status'] != 'verified') return false;
        final rawExpiry = row['expires_at']?.toString();
        if (rawExpiry != null && rawExpiry.isNotEmpty) {
          final expiry = DateTime.tryParse(rawExpiry)?.toUtc();
          if (expiry == null || !expiry.isAfter(now)) return false;
        }
        final isFeatured = row['is_featured'] == true;
        final rawFeaturedUntil = row['featured_until']?.toString();
        if (!isFeatured || rawFeaturedUntil == null) return false;
        final featuredUntil = DateTime.tryParse(rawFeaturedUntil)?.toUtc();
        return featuredUntil != null && featuredUntil.isAfter(now);
      }).toList();

      return featuredRows
          .map((row) => PropertyModel.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    }).handleError((error) {
      debugPrint("خطأ في جلب العقارات المميزة: $error");
      return <PropertyModel>[];
    });
  }

  /// البحث والفلترة المتقدمة مع تصحيح اسم حقل المحافظة ليكون 'gov' ليطابق قاعدة البيانات
  Future<List<PropertyModel>> filterProperties({
    String? governorate,
    String? city,
    Map<String, dynamic>? codeFilters,
  }) async {
    try {
      // البحث العام يعرض الإعلانات الموثقة فقط
      dynamic query = _supabase
          .from('properties')
          .select()
          .eq('status', 'verified')
          .or('expires_at.is.null,expires_at.gt.${DateTime.now().toUtc().toIso8601String()}');

      // تم التعديل من 'governorate' إلى 'gov' ليتطابق مع قاعدة البيانات واسم الحقل في الموديل
      if (governorate != null && governorate.isNotEmpty) {
        query = query.eq('gov', governorate);
      }

      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }

      // إضافة أي فلتر برمجي إضافي تم تمريره
      if (codeFilters != null && codeFilters.isNotEmpty) {
        codeFilters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      final response = await query;
      final List<dynamic> data = response as List<dynamic>;

      return data
          .map((row) => PropertyModel.fromMap(
              Map<String, dynamic>.from(row as Map<String, dynamic>)))
          .toList();
    } catch (e) {
      debugPrint("خطأ في فلترة العقارات: $e");
      return [];
    }
  }

  /// زيادة عدد المشاهدات للعقار عند فتحه بشكل آمن
  Future<void> incrementViewCount(String propertyId) async {
    try {
      final res = await _supabase
          .from('properties')
          .select('views_count')
          .eq('id', propertyId)
          .maybeSingle();

      if (res != null) {
        int currentViews = (res['views_count'] as int?) ?? 0;
        await _supabase
            .from('properties')
            .update({'views_count': currentViews + 1}).eq('id', propertyId);
      }
    } catch (e) {
      debugPrint("خطأ في تحديث عدد المشاهدات: $e");
    }
  }

  /// إضافة عقار جديد مع رفع الصور للسيرفر تلقائياً وتخزين روابطها
  Future<bool> addProperty(
      PropertyModel property, List<String> imagePaths) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      debugPrint('يجب تسجيل الدخول لإضافة العقار.');
      return false;
    }

    final List<String> uploadedImageUrls = [];
    final List<String> uploadedStoragePaths = [];

    try {
      // ارفع الملفات أولاً، مع الاحتفاظ بمساراتها لتنظيفها إذا فشل إدخال العقار.
      for (final path in imagePaths) {
        if (path.startsWith('http://') || path.startsWith('https://')) {
          uploadedImageUrls.add(path);
          continue;
        }

        final file = File(path);
        final fileName =
            '${DateTime.now().microsecondsSinceEpoch}_${file.path.split('/').last}';
        final storagePath = 'properties/$fileName';

        await _supabase.storage
            .from('property_images')
            .upload(storagePath, file);
        uploadedStoragePaths.add(storagePath);

        uploadedImageUrls.add(
          _supabase.storage.from('property_images').getPublicUrl(storagePath),
        );
      }

      final dataToInsert = property.toMap();
      dataToInsert['images'] = uploadedImageUrls;
      // لا نثق في حالة الإعلان أو المالك أو حقول التمييز القادمة من كائن العميل.
      dataToInsert['owner_id'] = userId;
      dataToInsert['status'] = 'pending';
      dataToInsert['is_featured'] = false;
      dataToInsert['is_reported'] = false;
      dataToInsert['report_count'] = 0;
      dataToInsert.remove('expires_at');
      dataToInsert.remove('featured_until');
      dataToInsert.remove('last_refreshed');
      dataToInsert.remove('created_at');

      await _supabase.from('properties').insert(dataToInsert).select('id').single();
      return true;
    } catch (e) {
      debugPrint("خطأ أثناء إضافة العقار: $e");

      // لا تترك الصور التي رفعها هذا الطلب إذا فشل إدخال العقار.
      if (uploadedStoragePaths.isNotEmpty) {
        try {
          await _supabase.storage
              .from('property_images')
              .remove(uploadedStoragePaths);
        } catch (cleanupError) {
          debugPrint("تعذر تنظيف الصور المرفوعة بعد فشل الإضافة: $cleanupError");
        }
      }
      return false;
    }
  }

  /// تحديث بيانات الإعلان
  Future<void> updateProperty(
      String propertyId, Map<String, dynamic> updatedData) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('يجب تسجيل الدخول لتعديل الإعلان.');
      }

      // Allowlist: لا تسمح لهذه الخدمة بتغيير المالك أو حالة المراجعة
      // أو التمييز أو البلاغات أو تواريخ الصلاحية.
      const allowedFields = {'title', 'price', 'finishing', 'metadata'};
      final safeData = <String, dynamic>{
        for (final entry in updatedData.entries)
          if (allowedFields.contains(entry.key)) entry.key: entry.value,
      };
      if (safeData.isEmpty) {
        throw Exception('لا توجد حقول مسموح بتحديثها.');
      }

      final updatedRow = await _supabase
          .from('properties')
          .update(safeData)
          .eq('id', propertyId)
          .eq('owner_id', userId)
          .select('id')
          .maybeSingle();

      if (updatedRow == null) {
        throw Exception('لم يتم تعديل الإعلان. قد لا يكون تابعاً لحسابك أو لا توجد صلاحية.');
      }
    } catch (e) {
      debugPrint("خطأ أثناء تحديث العقار: $e");
      rethrow;
    }
  }

  /// حذف إعلان بواسطة الـ ID بعد التأكد من أن المستخدم الحالي هو المالك.
  /// يجب أيضاً فرض شرط owner_id وسياسة الحذف في Supabase RLS.
  Future<void> deleteProperty(String propertyId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('يجب تسجيل الدخول لحذف الإعلان.');
      }

      // لا نحذف مفضلات أي مستخدم قبل التأكد من ملكية الإعلان وحذف سجله.
      final deletedProperty = await _supabase
          .from('properties')
          .delete()
          .eq('id', propertyId)
          .eq('owner_id', userId)
          .select('id')
          .maybeSingle();

      if (deletedProperty == null) {
        throw Exception('لم يتم حذف الإعلان. قد لا يكون تابعاً لحسابك أو لم يعد موجوداً.');
      }

      // تنظيف المفضلات يجب أن يتم عبر FK ON DELETE CASCADE في قاعدة البيانات.
      // لا نحذف مفضلات المستخدمين الآخرين من عميل المالك؛ ذلك يتطلب صلاحية إدارية/عملية ذرية.
    } catch (e) {
      debugPrint("خطأ أثناء حذف العقار: $e");
      rethrow;
    }
  }
}
