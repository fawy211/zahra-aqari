class OfficeModel {
  final String? id;
  final String name;
  final String phone;
  final String? email;
  final String? logo;
  final String? address;
  final int propertiesCount;
  final bool isVerified;
  final DateTime? createdAt;

  OfficeModel({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.logo,
    this.address,
    this.propertiesCount = 0,
    this.isVerified = false,
    this.createdAt,
  });

  // قراءة البيانات من جدول Supabase (Map)
  factory OfficeModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return OfficeModel(
      id: id ?? map['id']?.toString(),
      name: map['name'] ?? 'مكتب بدون اسم',
      phone: map['phone'] ?? '',
      email: map['email'],
      logo: map['logo'],
      address: map['address'],
      propertiesCount: map['propertiesCount'] ?? map['properties_count'] ?? 0,
      isVerified: map['isVerified'] ?? map['is_verified'] ?? false,
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
      'phone': phone,
      'email': email,
      'logo': logo,
      'address': address,
      'propertiesCount': propertiesCount,
      'isVerified': isVerified,
    };

    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String();
    }

    return data;
  }
}
