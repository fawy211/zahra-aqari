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
      debugPrint("❌ خطأ في جلب العقارات النشطة: $error");
      return <PropertyModel>[];
    });
  }

  /// جلب عقارات مميزة (Featured Properties)
  Stream<List<PropertyModel>> getFeaturedProperties() {
    final nowIso = DateTime.now().toIso8601String();
    return _supabase.from('properties').stream(primaryKey: ['id']).map((rows) {
      final featuredRows = rows.where((row) {
        final isFeatured = row['is_featured'] == true;
        final featuredUntil = row['featured_until']?.toString();
        if (!isFeatured || featuredUntil == null) return false;
        return featuredUntil.compareTo(nowIso) > 0;
      }).toList();

      return featuredRows
          .map((row) => PropertyModel.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    }).handleError((error) {
      debugPrint("❌ خطأ في جلب العقارات المميزة: $error");
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
      dynamic query = _supabase.from('properties').select();

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
    } on PostgrestException catch (e) {
      debugPrint("❌ خطأ في فلترة العقارات (Database): ${e.message}");
      return [];
    } catch (e) {
      debugPrint("❌ خطأ في فلترة العقارات: $e");
      return [];
    }
  }

  /// زيادة عدد المشاهدات للعقار عند فتحه بشكل آمن
  Future<void> incrementViewCount(String propertyId) async {
    try {
      if (propertyId.isEmpty) {
        throw Exception("معرّف العقار غير صحيح");
      }

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
        debugPrint("✅ تم تحديث عدد المشاهدات");
      }
    } catch (e) {
      debugPrint("⚠️ خطأ في تحديث عدد المشاهدات: $e");
    }
  }

  /// إضافة عقار جديد مع رفع الصور للسيرفر تلقائياً وتخزين روابطها
  Future<bool> addProperty(
      PropertyModel property, List<String> imagePaths) async {
    try {
      List<String> uploadedImageUrls = [];

      // 1. رفع الصور إلى Supabase Storage باستخدام الـ bucket الموجود فعلياً
      for (String path in imagePaths) {
        // إذا كانت الصورة مسار محلي وليست رابطاً ويب بالفعل
        if (!path.startsWith('http')) {
          final file = File(path);
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
          final storagePath = 'properties/$fileName';

          await _supabase.storage
              .from('property_images')
              .upload(storagePath, file);

          final String publicUrl = _supabase.storage
              .from('property_images')
              .getPublicUrl(storagePath);
          uploadedImageUrls.add(publicUrl);
        } else {
          uploadedImageUrls.add(path);
        }
      }

      // 2. تحديث قائمة الصور في بيانات العقار لتصبح روابط سحابية
      final Map<String, dynamic> dataToInsert = property.toMap();
      if (uploadedImageUrls.isNotEmpty) {
        dataToInsert['images'] = uploadedImageUrls;
      }

      // 3. إدخال البيانات في جدول properties
      await _supabase.from('properties').insert(dataToInsert);
      debugPrint("✅ تم إضافة العقار بنجاح");
      return true;
    } on PostgrestException catch (e) {
      debugPrint("❌ خطأ في إضافة العقار (Database): ${e.message}");
      return false;
    } catch (e) {
      debugPrint("❌ خطأ أثناء إضافة العقار: $e");
      return false;
    }
  }

  /// تحديث بيانات الإعلان
  Future<void> updateProperty(
      String propertyId, Map<String, dynamic> updatedData) async {
    try {
      if (propertyId.isEmpty) {
        throw Exception("معرّف العقار غير صحيح");
      }

      await _supabase
          .from('properties')
          .update(updatedData)
          .eq('id', propertyId);
      debugPrint("✅ تم تحديث بيانات العقار");
    } on PostgrestException catch (e) {
      debugPrint("❌ خطأ في تحديث العقار (Database): ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("❌ خطأ أثناء تحديث العقار: $e");
      rethrow;
    }
  }

  /// حذف إعلان بواسطة الـ ID مع معالجة آمنة للمفضلة
  Future<void> deleteProperty(String propertyId) async {
    try {
      if (propertyId.isEmpty) {
        throw Exception("معرّف العقار غير صحيح");
      }

      // 1. محاولة حذف السجلات المرتبطة في جدول favorites (إن وجدت)
      try {
        await _supabase
            .from('favorites')
            .delete()
            .eq('property_id', propertyId);
        debugPrint("✅ تم حذف سجلات المفضلة المرتبطة");
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST205') {
          debugPrint(
              "⚠️ تحذير: جدول favorites غير موجود، سيتم المتابعة بحذف العقار");
        } else {
          rethrow;
        }
      }

      // 2. حذف العقار الأساسي من جدول properties
      await _supabase.from('properties').delete().eq('id', propertyId);
      debugPrint("✅ تم حذف العقار بنجاح");
    } on PostgrestException catch (e) {
      debugPrint("❌ خطأ في حذف العقار (Database): ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("❌ خطأ أثناء حذف العقار: $e");
      rethrow;
    }
  }
}
