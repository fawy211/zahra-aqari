class AppMaterials {
  // قائمة خيارات التشطيب المعتمدة في التطبيق
  static const List<String> finishingOptions = [
    'سوبر لوكس',
    'لوكس',
    'نصف تشطيب',
    'بدون تشطيب (على المحارة)',
    'تشطيب كامل ديلوكس',
    'تشطيب تجاري',
  ];

  // خريطة لربط القيم الإنجليزية (التي قد تاتي من قواعد البيانات القديمة) بالقيم العربية الموحدة
  static String normalizeFinishing(String? input) {
    if (input == null || input.isEmpty) return 'غير محدد';

    final lower = input.toLowerCase().trim();

    if (lower.contains('super') || lower.contains('سوبر')) {
      return 'سوبر لوكس';
    } else if (lower.contains('lux') || lower.contains('لوكس')) {
      return 'لوكس';
    } else if (lower.contains('semi') || lower.contains('نصف')) {
      return 'نصف تشطيب';
    } else if (lower.contains('core') ||
        lower.contains('محارة') ||
        lower.contains('بدون')) {
      return 'بدون تشطيب (على المحارة)';
    }

    return input; // إرجاع النص كما هو إذا لم يتطابق مع شروط التوحيد
  }

  // قائمة الكماليات والإضافات الشائعة المتاحة للعقارات
  static const List<String> commonAmenities = [
    'أمن وحراسة',
    'موقف سيارات (جراج)',
    'مصعد كهربائي',
    'حديقة خاصة',
    'شرفة (بلكونة)',
    'تكييف مركزى',
    'حمام سباحة',
    'غاز طبيعي',
    'عداد كهرباء مستقل',
    'عداد آب عذب',
  ];
}
