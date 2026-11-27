class CompanyModel {
  final String? id;
  final String? ownerId;
  final String name;
  final String? businessField;
  final DateTime? createdAt;

  const CompanyModel({
    this.id,
    this.ownerId,
    required this.name,
    this.businessField,
    this.createdAt,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CompanyModel(
      id: id ?? map['id']?.toString(),
      ownerId: map['owner_id']?.toString(),
      name: (map['name'] ?? '').toString().trim().isEmpty
          ? 'شركة بدون اسم'
          : map['name'].toString(),
      businessField: map['business_field']?.toString(),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
    );
  }
}
