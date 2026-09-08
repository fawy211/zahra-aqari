import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PropertyCategory {
  final String code;
  final String name;

  PropertyCategory({required this.code, required this.name});
}

class PropertyFormState {
  final PropertyCategory? selectedCategory;
  final bool isSubmitting;
  final String? error;
  final bool success;
  final List<String> mediaUrls;
  final Map<String, String> dynamicFields; // لتخزين الحقول الديناميكية

  PropertyFormState({
    this.selectedCategory,
    this.isSubmitting = false,
    this.error,
    this.success = false,
    this.mediaUrls = const [],
    this.dynamicFields = const {},
  });

  PropertyFormState copyWith({
    PropertyCategory? selectedCategory,
    bool? isSubmitting,
    String? error,
    bool? success,
    List<String>? mediaUrls,
    Map<String, String>? dynamicFields,
  }) {
    return PropertyFormState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error, // يسمح بتصفير الخطأ أو تحديثه
      success: success ?? this.success,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      dynamicFields: dynamicFields ?? this.dynamicFields,
    );
  }
}

class AddPropertyNotifier extends Notifier<PropertyFormState> {
  @override
  PropertyFormState build() {
    return PropertyFormState();
  }

  void selectCategory(PropertyCategory category) {
    state = state.copyWith(selectedCategory: category, error: null);
  }

  /// إرفاق روابط الصور أو الفيديوهات المرفوعة مسبقاً
  void setMediaUrls(List<String> urls) {
    state = state.copyWith(mediaUrls: urls);
  }

  /// تحديث وتخزين قيمة أي حقل ديناميكي فور كتابته
  void updateDynamicField(String fieldKey, String value) {
    final updatedFields = Map<String, String>.from(state.dynamicFields);
    updatedFields[fieldKey] = value;
    state = state.copyWith(dynamicFields: updatedFields);
  }

  /// تعبئة الحالة ببيانات عقار حالي لغرض التعديل
  void loadPropertyForEdit(dynamic property) {
    final Map<String, String> stringMetadata = {};
    property.metadata.forEach((key, value) {
      if (value != null) {
        stringMetadata[key] = value.toString();
      }
    });

    state = state.copyWith(
      selectedCategory: PropertyCategory(
        code: property.categoryCode,
        name: property.category,
      ),
      mediaUrls: property.images,
      dynamicFields: stringMetadata,
      error: null,
      success: false,
    );
  }

  Future<void> submitProperty({
    required Map<String, dynamic> formData,
    required String phone,
    String?
        propertyId, // يُستخدم في حالة التعديل لتحديث عقار موجود بدلاً من إضافة جديد
  }) async {
    state = state.copyWith(isSubmitting: true, error: null, success: false);
    try {
      final supabase = Supabase.instance.client;

      // جلب معرف المستخدم الحقيقي إن وجد
      final String? currentUserId = supabase.auth.currentUser?.id;

      final String categoryName =
          state.selectedCategory?.name ?? formData['category'] ?? '';
      final String categoryCode =
          state.selectedCategory?.code ?? formData['category_code'] ?? '';
      final double priceVal =
          double.tryParse(formData['price']?.toString() ?? '0') ?? 0.0;
      final double areaVal = double.tryParse(
              formData['area']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ??
                  '0') ??
          0.0;

      final String govVal = formData['gov'] ?? '';
      final String cityVal = formData['city'] ?? '';
      final String typeVal = formData['type'] ?? '';
      final String finishingVal = formData['finishing'] ?? '';
      final String advertiserTypeVal = formData['advertiser_type'] ?? 'مالك';

      // تجهيز خريطة الـ metadata لتتوافق تماماً مع شروط البحث والفلترة في HomeScreen
      final Map<String, dynamic> metadataMap = {
        'المحافظة': govVal,
        'المدينة': cityVal,
        'نوع العقار': typeVal,
        'type': typeVal,
        'التشطيب': finishingVal,
        'finishing': finishingVal,
        'المساحة': areaVal,
        'صفة المعلن': advertiserTypeVal,
        'قابل للتفاوض': (formData['is_negotiable'] ?? false).toString(),
        'is_negotiable': formData['is_negotiable'] ?? false,
        ...state.dynamicFields, // تضمين أي حقول ديناميكية أخرى إن وجدت
      };

      // تجهيز خريطة البيانات الصريحة المتوافقة مع الأعمدة وجدول Supabase الرئيسي
      final Map<String, dynamic> propertyData = {
        'title': formData['title'] ?? 'عقار جديد',
        'description': formData['description'] ?? '',
        'category': categoryName,
        'category_code': categoryCode,
        'type': typeVal,
        'finishing': finishingVal,
        'price': priceVal,
        'area': areaVal,
        'gov': govVal,
        'city': cityVal,
        'street': formData['street'] ?? '',
        'advertiser_type': advertiserTypeVal,
        'phone': phone,
        'images': state.mediaUrls,
        'metadata': metadataMap,
        if (currentUserId != null && currentUserId.isNotEmpty)
          'owner_id': currentUserId,
        'rooms': formData['rooms']?.toString(),
        'floor': formData['floor']?.toString(),
        'code': formData['code']?.toString(),
        'is_negotiable': formData['is_negotiable'] ?? false,
        'contact_method': formData['contact_method'] ?? 'الكل',
      };

      if (propertyId != null && propertyId.isNotEmpty) {
        // تحديث العقار إذا كان مُعرفه موجوداً (عملية تعديل)
        await supabase
            .from('properties')
            .update(propertyData)
            .eq('id', propertyId);
      } else {
        // إرسال البيانات مباشرة كإضافة جديدة إلى جدول 'properties'
        propertyData['is_featured'] = false;
        await supabase.from('properties').insert(propertyData);
      }

      state = state.copyWith(isSubmitting: false, success: true);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('========== ERROR IN SUBMIT PROPERTY ==========');
        debugPrint(e.toString());
        debugPrint(stackTrace.toString());
        debugPrint('==============================================');
      }
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  /// إعادة تعيين النموذج بعد النجاح أو الإلغاء
  void resetForm() {
    state = PropertyFormState();
  }
}

final addPropertyProvider =
    NotifierProvider<AddPropertyNotifier, PropertyFormState>(
  () => AddPropertyNotifier(),
);
