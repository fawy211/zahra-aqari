class UserModel {
  final String uid;
  final String email;
  final String name; // الاسم لعرضه في واجهة المستخدم
  final String userType; // نوع المستخدم من قاعدة البيانات
  final String accountType; // نوع الحساب ('individual', 'office', 'company')
  final String subscriptionPlan; // خطة الاشتراك ('free', 'basic', etc.)
  final int adsCount; // عدد الإعلانات المتاحة
  final bool isVerifiedOffice; // توثيق المكتب

  UserModel({
    required this.uid,
    required this.email,
    this.name = '',
    this.userType = '',
    this.accountType = 'individual',
    this.subscriptionPlan = 'free',
    this.adsCount = 0,
    this.isVerifiedOffice = false,
  });

  // 1. القراءة الآمنة من Supabase مع قيم افتراضية كاملة لمنع الانهيار
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? map['full_name']?.toString() ?? '',
      userType: map['user_type']?.toString() ?? '',
      accountType: map['account_type']?.toString() ??
          map['accountType']?.toString() ??
          'individual',
      subscriptionPlan: map['subscription_plan']?.toString() ??
          map['subscriptionPlan']?.toString() ??
          'free',

      // معالجة أمنية شاملة لقراءة الأرقام سواء كانت int أو String أو null
      adsCount: () {
        final val = map['ads_count'] ?? map['adsCount'];
        if (val is int) return val;
        if (val is String) return int.tryParse(val) ?? 0;
        return 0;
      }(),

      // معالجة أمنية للقيم البوليانية (True / False)
      isVerifiedOffice: () {
        final val = map['is_verified_office'] ?? map['isVerifiedOffice'];
        if (val is bool) return val;
        if (val is String) return val.toLowerCase() == 'true';
        if (val is int) return val == 1;
        return false;
      }(),
    );
  }

  // 2. الإرسال إلى Supabase (متوافق تماماً مع أسماء الأعمدة في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'email': email,
      'name': name,
      'user_type': userType,
      'account_type': accountType,
      'subscription_plan': subscriptionPlan,
      'ads_count': adsCount,
      'is_verified_office': isVerifiedOffice,
    };
  }

  // نسخة للتحديث الجزئي (copyWith)
  UserModel copyWith({
    String? email,
    String? name,
    String? userType,
    String? accountType,
    String? subscriptionPlan,
    int? adsCount,
    bool? isVerifiedOffice,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      accountType: accountType ?? this.accountType,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      adsCount: adsCount ?? this.adsCount,
      isVerifiedOffice: isVerifiedOffice ?? this.isVerifiedOffice,
    );
  }
}
