class Property {
  final String? id; // يفضل نضيف الـ id عشان لو حبيت تعدل أو تحذف عقار بعدين
  final String title;
  final double price;
  final String description;
  final String transactionType; // إيجار / تمليك
  final String propertyCategory; // سكني / تجاري / إلخ

  Property({
    this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.transactionType,
    required this.propertyCategory,
  });

  // 1. تحويل البيانات القادمة من Supabase إلى كود Dart (قراءة)
  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id']?.toString(),
      title: map['title'] ?? '',
      // بنستخدم num.tryParse أو نتحول لـ double لضمان عدم حدوث Crash لو السعر جاء بصيغة نصية أو صحيحة
      price: (map['price'] != null) ? (map['price'] as num).toDouble() : 0.0,
      description: map['description'] ?? '',
      transactionType:
          map['transaction_type'] ?? '', // ملاحظة تطابق اسم العمود في القاعدة
      propertyCategory:
          map['property_category'] ?? '', // ملاحظة تطابق اسم العمود في القاعدة
    );
  }

  // 2. تحويل كود Dart إلى Map لكي يتم إرساله إلى Supabase (إضافة)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'description': description,
      'transaction_type': transactionType,
      'property_category': propertyCategory,
    };
  }
}
