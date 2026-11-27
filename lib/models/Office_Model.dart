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
    this.phone = '',
    this.email,
    this.logo,
    this.address,
    this.propertiesCount = 0,
    this.isVerified = false,
    this.createdAt,
  });

  factory OfficeModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final metadataValue = map['metadata'];
    final metadata = metadataValue is Map
        ? Map<String, dynamic>.from(metadataValue)
        : <String, dynamic>{};

    String readString(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = metadata[key] ?? map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return fallback;
    }

    int readInt(List<String> keys) {
      for (final key in keys) {
        final value = metadata[key] ?? map[key];
        if (value is int) return value;
        if (value != null) {
          final parsed = int.tryParse(value.toString());
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    final verifiedValue = metadata['is_verified'] ??
        metadata['isVerified'] ??
        map['is_verified'] ??
        map['isVerified'];

    return OfficeModel(
      id: id ?? map['id']?.toString(),
      name: readString(['name'], fallback: 'مكتب بدون اسم'),
      phone: readString(['contact_phone', 'phone', 'phone_number']),
      email: readString(['contact_email', 'email']),
      logo: readString(['logo_url', 'logoUrl', 'logo']),
      address: readString(['address', 'location'], fallback: 'غير محدد'),
      propertiesCount: readInt(['properties_count', 'propertiesCount']),
      isVerified: verifiedValue == true ||
          verifiedValue?.toString().toLowerCase() == 'true',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  /// Maps only to columns that actually exist in public.offices.
  /// Optional office details are kept inside the metadata JSON object.
  Map<String, dynamic> toMap() {
    final metadata = <String, dynamic>{
      'contact_phone': phone,
      if (email != null && email!.trim().isNotEmpty)
        'contact_email': email!.trim(),
      if (logo != null && logo!.trim().isNotEmpty) 'logo_url': logo!.trim(),
      'properties_count': propertiesCount,
      'is_verified': isVerified,
    };

    return {
      'name': name,
      if (address != null && address!.trim().isNotEmpty)
        'location': address!.trim(),
      'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
    };
  }
}
