class PropertyModel {
  final String? id;
  final String title;
  final String description;
  final String categoryCode;
  final String type;
  final String finishing;
  final double price;
  final double area;
  final String gov;
  final String city;
  final String street;
  final String advertiserType;
  final String phone;
  final List<String> images;
  final String? video;
  final String ownerId;
  final String? companyId;
  final String status;
  final Map<String, dynamic> metadata;

  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? lastRefreshed;

  final bool isFeatured;
  final DateTime? featuredUntil;

  final bool isReported;
  final int reportCount;

  PropertyModel({
    this.id,
    required this.title,
    required this.description,
    required this.categoryCode,
    required this.type,
    required this.finishing,
    required this.price,
    required this.area,
    required this.gov,
    required this.city,
    required this.street,
    required this.advertiserType,
    required this.phone,
    required this.images,
    this.video,
    required this.ownerId,
    this.companyId,
    this.status = 'pending',
    required this.metadata,
    this.createdAt,
    this.expiresAt,
    this.lastRefreshed,
    this.isFeatured = false,
    this.featuredUntil,
    this.isReported = false,
    this.reportCount = 0,
  });

  /// توحيد الحقول القديمة والجديدة داخل metadata للعرض والبحث.
  /// بعض السجلات تخزن floor/utilities/amenties كأعمدة مباشرة، بينما
  /// سجلات أخرى تخزنها داخل JSON metadata.
  static Map<String, dynamic> _mergeMetadata(Map<String, dynamic> data) {
    final merged = <String, dynamic>{};
    final rawMetadata = data['metadata'];
    if (rawMetadata is Map) {
      merged.addAll(Map<String, dynamic>.from(rawMetadata));
    }

    void addDirect(String key, dynamic value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        final alreadyExists = merged.keys.any(
            (existing) => existing.toLowerCase().trim() == key.toLowerCase());
        if (!alreadyExists) merged[key] = value;
      }
    }

    // الأسماء الموجودة فعلياً في جدول properties أو في الإصدارات السابقة.
    addDirect('floor', data['floor']);
    addDirect('rooms', data['rooms']);
    addDirect('utilities', data['utilities']);
    addDirect('amenties', data['amenties']);
    addDirect('amenities', data['amenities']);
    addDirect('bathrooms', data['bathrooms']);
    addDirect('is_negotiable', data['is_negotiable']);
    addDirect('is_furnished', data['is_furnished']);
    addDirect('contact_method', data['contact_method']);
    addDirect('transaction_type', data['transaction_type']);
    addDirect('code', data['code']);

    return merged;
  }

  factory PropertyModel.fromPropertyData(
      Map<String, dynamic> data, String currentUserId) {
    // التعامل الآمن مع الحقول البولينية سواء أكانت قادمة كـ boolean أو كـ نص ('نعم' / 'لا')
    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is String) {
        return val == 'نعم' || val.toLowerCase() == 'true';
      }
      return false;
    }

    return PropertyModel(
      title: data['title'] ?? 'عقار جديد',
      description: data['description'] ?? '',
      categoryCode: data['category'] ??
          data['property_category'] ??
          data['categoryCode'] ??
          '',
      type: data['type'] ?? '',
      finishing: data['finishing'] ?? '',
      price: double.tryParse(data['price']?.toString() ?? '0') ?? 0.0,
      area: double.tryParse(data['area']?.toString() ?? '0') ?? 0.0,
      gov: data['gov'] ?? '',
      city: data['city'] ?? '',
      street: data['street'] ?? '',
      advertiserType: data['advertiser_type'] ?? 'مالك',
      phone: data['phone'] ?? '',
      images: data['images'] != null ? List<String>.from(data['images']) : [],
      video: data['video']?.toString(),
      ownerId: currentUserId,
      isFeatured: parseBool(data['is_featured']),
      metadata: {
        ..._mergeMetadata(data),
        if (data['is_negotiable'] != null)
          'is_negotiable': parseBool(data['is_negotiable']),
      },
      createdAt: DateTime.now(),
    );
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map, {String? id}) {
    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is String) {
        return val == 'نعم' || val.toLowerCase() == 'true';
      }
      return false;
    }

    return PropertyModel(
      id: id ?? map['id']?.toString(),
      title: map['title'] ?? 'بدون عنوان',
      description: map['description'] ?? '',
      categoryCode: map['categoryCode'] ??
          map['category'] ??
          map['property_category'] ??
          '',
      type: map['type'] ?? '',
      finishing: map['finishing'] ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      area: double.tryParse(map['area']?.toString() ?? '0') ?? 0.0,
      gov: map['gov'] ?? '',
      city: map['city'] ?? '',
      street: map['street'] ?? '',
      advertiserType: map['advertiser_type'] ?? '',
      phone: map['phone'] ?? '',
      images: map['images'] != null ? List<String>.from(map['images']) : [],
      video: map['video']?.toString(),
      ownerId: map['ownerId']?.toString() ?? map['owner_id']?.toString() ?? '',
      companyId: map['companyId']?.toString() ?? map['company_id']?.toString(),
      status: map['status'] ?? 'pending',
      metadata: _mergeMetadata(map),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      expiresAt: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'].toString())
          : null,
      lastRefreshed: map['last_refreshed'] != null
          ? DateTime.tryParse(map['last_refreshed'].toString())
          : null,
      isFeatured: parseBool(map['isFeatured'] ?? map['is_featured']),
      featuredUntil: map['featured_until'] != null
          ? DateTime.tryParse(map['featured_until'].toString())
          : null,
      isReported: parseBool(map['isReported'] ?? map['is_reported']),
      reportCount: int.tryParse(map['reportCount']?.toString() ??
              map['report_count']?.toString() ??
              '0') ??
          0,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'title': title,
      'description': description,
      'category': categoryCode,
      'type': type,
      'finishing': finishing,
      'price': price,
      'area': area,
      'gov': gov,
      'city': city,
      'street': street,
      'advertiser_type': advertiserType,
      'phone': phone,
      'images': images,
      'owner_id': ownerId,
      'status': status,
      'metadata': metadata,
      'is_featured': isFeatured,
      'is_reported': isReported,
      'report_count': reportCount,
    };

    if (video != null && video!.isNotEmpty) {
      data['video'] = video;
    }

    if (companyId != null) {
      data['company_id'] = companyId;
    }
    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String();
    }
    if (expiresAt != null) {
      data['expires_at'] = expiresAt!.toIso8601String();
    }
    if (lastRefreshed != null) {
      data['last_refreshed'] = lastRefreshed!.toIso8601String();
    }
    if (featuredUntil != null) {
      data['featured_until'] = featuredUntil!.toIso8601String();
    }

    return data;
  }

  PropertyModel copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryCode,
    String? type,
    String? finishing,
    double? price,
    double? area,
    String? gov,
    String? city,
    String? street,
    String? advertiserType,
    String? phone,
    List<String>? images,
    String? video,
    String? ownerId,
    String? companyId,
    String? status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? lastRefreshed,
    bool? isFeatured,
    DateTime? featuredUntil,
    bool? isReported,
    int? reportCount,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryCode: categoryCode ?? this.categoryCode,
      type: type ?? this.type,
      finishing: finishing ?? this.finishing,
      price: price ?? this.price,
      area: area ?? this.area,
      gov: gov ?? this.gov,
      city: city ?? this.city,
      street: street ?? this.street,
      advertiserType: advertiserType ?? this.advertiserType,
      phone: phone ?? this.phone,
      images: images ?? this.images,
      video: video ?? this.video,
      ownerId: ownerId ?? this.ownerId,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredUntil: featuredUntil ?? this.featuredUntil,
      isReported: isReported ?? this.isReported,
      reportCount: reportCount ?? this.reportCount,
    );
  }
}
