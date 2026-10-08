class PropertyMapper {
  // 1. قاموس المحافظات (ربط الرقم بالاسم)
  static final Map<String, String> governorates = {
    '1': 'القاهرة',
    '2': 'الجيزة',
    '3': 'الاسكندرية',
    '4': 'القليوبية',
    '5': 'الشرقية',
    '6': 'بورسعيد',
    '7': 'الاسماعيلية',
    '8': 'السويس',
    '9': 'شمال سيناء',
    '10': 'جنوب سيناء',
    '11': 'البحر الاحمر',
    '12': 'مطروح',
    '13': 'الوادى الجديد',
    '14': 'دمياط',
    '15': 'كفر الشيخ',
    '16': 'البحيره',
    '17': 'الغربية',
    '18': 'الدقهلية',
    '19': 'المنوفية',
    '20': 'الفيوم',
    '21': 'بنى سويف',
    '22': 'المنيا',
    '23': 'سوهاج',
    '24': 'اسيوط',
    '25': 'قنا',
    '26': 'الاقصر',
    '27': 'اسوان',
  };

  // 2. قاموس المواصفات (ربط الرمز بالنص العربي)
  static final Map<String, String> specs = {
    // حالة التشطيب
    's11a181': 'متشطب',
    's11a182': 'نصف تشطيب',
    's11a183': 'محارة وحلوق',
    's11a184': 'بدون تشطيب',
    's11a185': 'لوكس',
    's11a186': 'سوبر لوكس',
    's11a187': 'الترا سوبر لوكس',

    // الملكية
    's11a61': 'أول مالك',
    's11a62': 'إعادة بيع',

    // المرافق
    's11a151': 'عداد مياه',
    's11a152': 'عداد كهرباء',
    's11a153': 'عداد غاز',
    's11a154': 'خط تليفون أرضى',
  };

  // قيم قديمة أو رموز إنجليزية محفوظة في قاعدة البيانات، ونحوّلها
  // إلى نص عربي واضح قبل عرضها للمستخدم.
  static final Map<String, String> displayValues = {
    'residential': 'سكني',
    'commercial': 'تجاري',
    'industrial': 'صناعي',
    'agricultural': 'زراعي',
    'tourist': 'سياحي',
    'tourism': 'سياحي',
    'other': 'أخرى',
    'other_property': 'عقار آخر',
    'apartment': 'شقة',
    'flat': 'شقة',
    'villa': 'فيلا',
    'duplex': 'دوبلكس',
    'penthouse': 'بنتهاوس',
    'roof': 'روف',
    'shop': 'محل',
    'office': 'مكتب',
    'showroom': 'معرض',
    'factory': 'مصنع',
    'warehouse': 'مخزن',
    'farm': 'مزرعة',
    'chalet': 'شاليه',
    'hotel': 'فندق',
    'super_lux': 'سوبر لوكس',
    'lux': 'لوكس',
    'semi_finished': 'نصف تشطيب',
    'core_shell': 'على المحارة',
    'unfinished': 'بدون تشطيب',
    'finished': 'متشطب',
    'owner': 'مالك',
    'individual': 'مستخدم فرد',
    'agent': 'وسيط',
    'company': 'شركة',
    'sale': 'بيع',
    'rent': 'إيجار',
    'for_sale': 'للبيع',
    'for_rent': 'للإيجار',
    'ground': 'الأرضي',
    'basement': 'البدروم',
    'mezzanine': 'الميزانين',
    'yes': 'نعم',
    'no': 'لا',
    'true': 'نعم',
    'false': 'لا',
  };

  // ترجمة القيم التي تصل أحياناً من النسخ القديمة باللغة الإنجليزية.
  // هذه القواميس منفصلة عن قاموس المحافظات حتى لا يتم تفسير رقم الدور
  // على أنه رقم محافظة.
  static final Map<String, String> amenities = {
    'balcony': 'شرفة',
    'terrace': 'تراس',
    'elevator': 'أسانسير',
    'lift': 'أسانسير',
    'parking': 'جراج',
    'garage': 'جراج',
    'security': 'أمن وحراسة',
    'garden': 'حديقة',
    'pool': 'حمام سباحة',
    'swimming_pool': 'حمام سباحة',
    'air_conditioning': 'تكييف',
    'ac': 'تكييف',
    'furnished': 'مفروش',
  };

  static final Map<String, String> utilities = {
    'electricity': 'كهرباء',
    'electric': 'كهرباء',
    'water': 'مياه',
    'gas': 'غاز',
    'phone': 'تليفون أرضي',
    'telephone': 'تليفون أرضي',
    'landline': 'تليفون أرضي',
    'internet': 'إنترنت',
  };

  /// يحول أسماء الحقول المختلفة لنفس الاسم المنطقي، مثل:
  /// amenities / amenties / الكماليات => amenities
  static String canonicalKey(String key) {
    final normalized =
        key.toLowerCase().trim().replaceAll('-', '_').replaceAll(' ', '_');

    switch (normalized) {
      case 'amenities':
      case 'amenties': // خطأ إملائي قديم موجود في اسم عمود Supabase
      case 'amenity':
      case 'الكماليات':
        return 'amenities';
      case 'utilities':
      case 'utility':
      case 'المرافق':
      case 'المرافق_العامة':
        return 'utilities';
      case 'floor':
      case 'floors':
      case 'الطابق':
      case 'الطوابق':
      case 'الدور':
        return 'floor';
      case 'rooms':
      case 'room':
      case 'عدد_الغرف':
      case 'عدد الغرف':
        return 'rooms';
      case 'finishing':
      case 'التشطيب':
      case 'نوع_التشطيب':
      case 'نوع التشطيب':
        return 'finishing';
      case 'governorate':
      case 'gov':
      case 'المحافظة':
        return 'governorate';
      case 'city':
      case 'المدينة':
        return 'city';
      case 'street':
      case 'الشارع':
        return 'street';
      case 'advertiser_type':
      case 'صفة_المعلن':
      case 'صفة المعلن':
        return 'advertiser_type';
      case 'contact_method':
      case 'طريقة_التواصل':
      case 'طريقة التواصل':
        return 'contact_method';
      case 'is_negotiable':
      case 'قابل_للتفاوض':
      case 'قابل للتفاوض':
        return 'is_negotiable';
      case 'is_furnished':
      case 'مفروش':
        return 'is_furnished';
      default:
        return normalized;
    }
  }

  static String translateKey(String key) {
    switch (canonicalKey(key)) {
      case 'amenities':
        return 'الكماليات';
      case 'utilities':
        return 'المرافق';
      case 'floor':
        return 'الدور';
      case 'rooms':
        return 'عدد الغرف';
      case 'finishing':
        return 'التشطيب';
      case 'governorate':
        return 'المحافظة';
      case 'city':
        return 'المدينة';
      case 'street':
        return 'الشارع';
      case 'advertiser_type':
        return 'صفة المعلن';
      case 'contact_method':
        return 'طريقة التواصل';
      case 'is_negotiable':
        return 'قابل للتفاوض';
      case 'is_furnished':
        return 'مفروش';
      default:
        return key;
    }
  }

  // دالة التحويل (من رمز إلى اسم)
  static String getLabel(String code) {
    return specs[code] ?? code; // لو ملقاش الرمز يرجع الرمز زي ما هو
  }

  /// تحويل أي قيمة محفوظة بصيغة إنجليزية أو رمز داخلي إلى قيمة مناسبة للعرض.
  /// القيم العربية والأرقام والعبارات غير المعروفة تُترك كما هي.
  static String displayValue(dynamic value) {
    if (value == null) return '';

    if (value is bool) {
      return value ? 'نعم' : 'لا';
    }

    if (value is List) {
      final seen = <String>{};
      return value
          .map(displayValue)
          .where((item) => item.isNotEmpty)
          .where((item) => seen.add(item.toLowerCase()))
          .join('، ');
    }

    final raw = value.toString().trim();
    if (raw.isEmpty) return '';

    final normalized = raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    return displayValues[normalized] ?? specs[raw] ?? raw;
  }

  /// عرض قيمة حسب نوع الحقل. لا نستخدم قاموس المحافظات إلا مع حقل المحافظة
  /// حتى لا تتحول قيمة الدور "5" إلى "الشرقية".
  static String displayFieldValue(String key, dynamic value) {
    final canonical = canonicalKey(key);

    if (canonical == 'governorate') {
      return displayGovernorate(value);
    }

    if (canonical == 'amenities') {
      return _displayCollection(value, amenities);
    }

    if (canonical == 'utilities') {
      return _displayCollection(value, utilities);
    }

    return displayValue(value);
  }

  static String displayGovernorate(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value.map(displayGovernorate).where((v) => v.isNotEmpty).join('، ');
    }

    final raw = value.toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return '';
    return governorates[raw] ?? displayValue(raw);
  }

  static String _displayCollection(
      dynamic value, Map<String, String> translations) {
    if (value == null) return '';

    final values = value is List
        ? value
        : value
            .toString()
            .split(RegExp(r'[,،;|/\n]+'))
            .map((part) => part.trim())
            .toList();

    final seen = <String>{};
    final translated = <String>[];
    for (final item in values) {
      final raw = item.toString().trim();
      if (raw.isEmpty) continue;
      final normalized =
          raw.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
      final label = translations[normalized] ??
          displayValues[normalized] ??
          specs[raw] ??
          raw;
      if (seen.add(label.toLowerCase())) translated.add(label);
    }
    return translated.join('، ');
  }

  // دالة عكسية (لو احتجناها)
  static String? getCode(String label) {
    return specs.entries
        .firstWhere((e) => e.value == label, orElse: () => MapEntry('', ''))
        .key;
  }
}
