import 'package:aqari_app/features/property/config/app_config.dart'; // مسار ملف الـ Config لديك

class PropertyCategory {
  final String name;
  final String code;
  final List<String> fields; // الحقول المطلوبة حسب جدول الأكواد

  PropertyCategory({
    required this.name,
    required this.code,
    required this.fields,
  });
}

/// توليد قائمة التصنيفات تلقائياً من AppConfig لضمان التطابق التام
final List<PropertyCategory> propertyCategories =
    AppConfig.categories.entries.map((entry) {
  return PropertyCategory(
    name: entry.key,
    code: entry.value['code'] as String,
    fields: List<String>.from(entry.value['fields'] as List),
  );
}).toList();
