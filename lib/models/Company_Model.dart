class CompanyModel {
  final String? id;
  final String name;
  final String email;
  final String? phone;
  final String? logo;
  final String? address;
  final String? description;
  final int projectsCount;
  final bool isVerified;
  final DateTime? createdAt;

  CompanyModel({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.logo,
    this.address,
    this.description,
    this.projectsCount = 0,
    this.isVerified = false,
    this.createdAt,
  });

  // قراءة البيانات من جدول Supabase (Map)
  factory CompanyModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CompanyModel(
      id: id ?? map['id']?.toString(),
      name: map['name'] ?? 'شركة بدون اسم',
      email: map['email'] ?? '',
      phone: map['phone'],
      logo: map['logo'],
      address: map['address'],
      description: map['description'],
      projectsCount: map['projectsCount'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : (map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'].toString())
              : null),
    );
  }

  // تحويل البيانات لـ Map لحفظها في Supabase
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'phone': phone,
      'logo': logo,
      'address': address,
      'description': description,
      'projectsCount': projectsCount,
      'isVerified': isVerified,
    };

    // إرسال التاريخ بصيغة ISO أو ترك Supabase يتعامل مع القيمة الافتراضية للوقت
    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String();
    }

    return data;
  }
}
