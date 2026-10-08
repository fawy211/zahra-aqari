class DelegateModel {
  final String id;
  final String name;
  final String email;
  final bool canAddProperties;
  final bool canReplyToMessages;
  final String companyId;

  DelegateModel({
    required this.id,
    required this.name,
    required this.email,
    this.canAddProperties = false,
    this.canReplyToMessages = false,
    required this.companyId,
  });

  // تحويل البيانات من Map الخاص بـ Supabase
  factory DelegateModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return DelegateModel(
      id: id ?? map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      canAddProperties:
          map['canAddProperties'] ?? map['can_add_properties'] ?? false,
      canReplyToMessages:
          map['canReplyToMessages'] ?? map['can_reply_to_messages'] ?? false,
      companyId:
          map['companyId']?.toString() ?? map['company_id']?.toString() ?? '',
    );
  }

  // تحويل البيانات لـ Map لحفظها في Supabase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'canAddProperties': canAddProperties,
      'canReplyToMessages': canReplyToMessages,
      'companyId': companyId,
    };
  }
}
