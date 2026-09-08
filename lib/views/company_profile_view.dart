import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property_models.dart';
import 'property_details_screen.dart';
import 'Chat_Screen.dart';

class CompanyProfileView extends StatelessWidget {
  final String ownerId;
  final String companyName;

  const CompanyProfileView({
    super.key,
    required this.ownerId,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    final SupabaseClient supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          companyName,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildProfileHeader(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "عقارات الشركة المتاحة",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800]),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // استخدام Supabase Stream لجلب العقارات الموثقة الخاصة بالشركة
              stream: supabase
                  .from('properties')
                  .stream(primaryKey: ['id'])
                  .eq('ownerId', ownerId)
                  .eq('status', 'verified'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF003366)),
                  );
                }

                final docs = snapshot.data ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_work_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          "لا توجد عقارات متاحة حالياً",
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final propertyId = data['id']?.toString() ?? '';
                    final property =
                        PropertyModel.fromMap(data, id: propertyId);
                    final imageUrl =
                        (data['imageUrl'] ?? data['image'] ?? '') as String;
                    return _buildPropertyCard(context, property, imageUrl);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // رأس الملف الشخصي للشركة مع جلب رقم الهاتف من جدول users في Supabase
  Widget _buildProfileHeader(BuildContext context) {
    final SupabaseClient supabase = Supabase.instance.client;

    return FutureBuilder<Map<String, dynamic>?>(
      future: supabase.from('users').select().eq('id', ownerId).maybeSingle(),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final phone = userData?['phone'] ?? userData?['phoneNumber'] ?? '';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFF003366).withOpacity(0.1),
                child: Text(
                  companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Color(0xFF003366),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // زر الاتصال الهاتفي
                        if (phone.toString().isNotEmpty) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              minimumSize: const Size(0, 32),
                            ),
                            onPressed: () async {
                              final Uri launchUri =
                                  Uri(scheme: 'tel', path: phone.toString());
                              if (await canLaunchUrl(launchUri)) {
                                await launchUrl(launchUri);
                              }
                            },
                            icon: const Icon(Icons.phone_rounded, size: 16),
                            label: const Text("اتصال",
                                style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // زر المراسلة داخل التطبيق
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003366),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            minimumSize: const Size(0, 32),
                          ),
                          onPressed: () => _openChat(context),
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 16),
                          label: const Text("مراسلة",
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // تصميم كارت العقار ضمن شبكة العرض (Grid)
  Widget _buildPropertyCard(
      BuildContext context, PropertyModel property, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailsScreen(property: property)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl.isNotEmpty
                      ? imageUrl
                      : 'https://via.placeholder.com/150',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${property.price} ج.م",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // فتح أو إنشاء غرفة محادثة مباشرة مع الشركة باستخدام Supabase
  Future<void> _openChat(BuildContext context) async {
    final SupabaseClient supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null || currentUserId == ownerId) return;

    List<String> ids = [currentUserId, ownerId];
    ids.sort();
    String chatId = "${ids[0]}_${ids[1]}";

    // التحقق من وجود المحادثة مسبقاً أو إنشائها
    final existingChat =
        await supabase.from('chats').select().eq('id', chatId).maybeSingle();

    if (existingChat == null) {
      await supabase.from('chats').insert({
        'id': chatId,
        'participants': [currentUserId, ownerId],
        'lastMessage': '',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          otherUserName: companyName,
        ),
      ),
    );
  }
}
