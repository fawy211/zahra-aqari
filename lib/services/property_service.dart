import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/models/property_models.dart';

class PropertyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// جلب كل العقارات النشطة وغير المنتهية الصلاحية
  Stream<List<PropertyModel>> getActiveProperties() {
    final nowIso = DateTime.now().toIso8601String();
    return _supabase.from('properties').stream(primaryKey: ['id']).map((rows) {
      // فلترة العقارات التي لم تنتهي صلاحيتها وتثبيت الترتيب محلياً للـ Stream
      final activeRows = rows.where((row) {
        // القوائم العامة تعرض الإعلانات الموثقة فقط
        if (row['status'] != 'verified') return false;
        final expiresAt = row['expires_at']?.toString();
        if (expiresAt == null) return true;
        return expiresAt.compareTo(nowIso) > 0;
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
    final nowIso = DateTime.now().toIso8601String();
    return _supabase.from('properties').stream(primaryKey: ['id']).map((rows) {
      final featuredRows = rows.where((row) {
        // القوائم العامة تعرض الإعلانات الموثقة فقط
        if (row['status'] != 'verified') return false;
        final isFeatured = row['is_featured'] == true;
        final featuredUntil = row['featured_until']?.toString();
        if (!isFeatured || featuredUntil == null) return false;
        return featuredUntil.compareTo(nowIso) > 0;
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
      dynamic query = _supabase.from('properties').select().eq('status', 'verified');

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
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint("تعذر إضافة العقار: لا يوجد مستخدم مسجل الدخول");
      return false;
    }

    // نحتفظ بمسارات الملفات التي رفعناها نحن فقط حتى ننظفها عند فشل الإدخال.
    final List<String> uploadedStoragePaths = [];

    try {
      final List<String> uploadedImageUrls = [];

      for (final path in imagePaths) {
        if (path.startsWith('http://') || path.startsWith('https://')) {
          uploadedImageUrls.add(path);
          continue;
        }

        final file = File(path);
        if (!await file.exists()) {
          throw Exception("ملف الصورة غير موجود");
        }

        final originalName = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'image';
        final safeName = originalName.replaceAll(
          RegExp(r'[^a-zA-Z0-9._-]'),
          '_',
        );
        final fileName =
            '${DateTime.now().microsecondsSinceEpoch}_$safeName';
        final storagePath = 'properties/$fileName';

        await _supabase.storage
            .from('property_images')
            .upload(storagePath, file);

        uploadedStoragePaths.add(storagePath);
        uploadedImageUrls.add(
          _supabase.storage.from('property_images').getPublicUrl(storagePath),
        );
      }

      // لا نثق في قيم المالك أو التوثيق أو التمييز القادمة من كائن الشاشة.
      // هذه حماية إضافية من جهة التطبيق، ويجب فرض الصلاحيات نفسها في RLS.
      final Map<String, dynamic> dataToInsert = property.toMap()
        ..remove('ownerId')
        ..remove('owner_id')
        ..remove('status')
        ..remove('is_featured')
        ..remove('featured_until')
        ..remove('is_reported')
        ..remove('report_count');

      dataToInsert['owner_id'] = user.id;
      dataToInsert['status'] = 'pending';
      dataToInsert['is_featured'] = false;
      dataToInsert['is_reported'] = false;
      dataToInsert['report_count'] = 0;
      dataToInsert['images'] = uploadedImageUrls;

      await _supabase.from('properties').insert(dataToInsert);
      return true;
    } catch (e) {
      debugPrint("خطأ أثناء إضافة العقار: $e");

      // لا نترك الصور التي رفعناها لهذه المحاولة إذا فشل حفظ الإعلان.
      if (uploadedStoragePaths.isNotEmpty) {
        try {
          await _supabase.storage
              .from('property_images')
              .remove(uploadedStoragePaths);
        } catch (cleanupError) {
          debugPrint("تعذر تنظيف الصور المرفوعة بعد فشل الحفظ: $cleanupError");
        }
      }
      return false;
    }
  }

  /// تحديث بيانات الإعلان
  Future<void> updateProperty(
      String propertyId, Map<String, dynamic> updatedData) async {
    try {
      await _supabase
          .from('properties')
          .update(updatedData)
          .eq('id', propertyId);
    } catch (e) {
      debugPrint("خطأ أثناء تحديث العقار: $e");
      rethrow;
    }
  }

  /// حذف إعلان بواسطة الـ ID مع تنظيف السجلات المرتبطة في المفضلة تلقائياً
  Future<void> deleteProperty(String propertyId) async {
    try {
      // 1. حذف المستندات المرتبطة في المفضلة (favorites) أولاً
      await _supabase.from('favorites').delete().eq('property_id', propertyId);

      // 2. حذف العقار الأساسي من جدول properties
      await _supabase.from('properties').delete().eq('id', propertyId);
    } catch (e) {
      debugPrint("خطأ أثناء حذف العقار: $e");
      rethrow;
    }
  }
}
