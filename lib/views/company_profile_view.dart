import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property_models.dart';
import 'property_details_screen.dart';
import 'Chat_Screen.dart';

class CompanyProfileView extends StatelessWidget {
  final String companyId;
  final String ownerId;
  final String companyName;

  const CompanyProfileView({
    super.key,
    required this.companyId,
    required this.ownerId,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          companyName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
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
                'عقارات الشركة المتاحة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase
                  .from('properties')
                  .select()
                  .eq('owner_id', ownerId)
                  .eq('status', 'verified')
                  .contains('metadata', {'company_id': companyId}),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF003366),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('تعذر تحميل عقارات الشركة حالياً'),
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
                          'لا توجد عقارات متاحة حالياً',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
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
                    final rawImages = data['images'];
                    final imageUrl = rawImages is List && rawImages.isNotEmpty
                        ? rawImages.first.toString()
                        : (data['imageUrl'] ?? data['image'] ?? '').toString();
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

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () => _openChat(context),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('مراسلة',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          MaterialPageRoute(
            builder: (_) => DetailsScreen(property: property),
          ),
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
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
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
                    '${property.price} ج.م',
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

  Future<void> _openChat(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')),
      );
      return;
    }
    if (currentUserId == ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكنك مراسلة حسابك الشخصي')),
      );
      return;
    }

    try {
      final firstUserId =
          currentUserId.compareTo(ownerId) < 0 ? currentUserId : ownerId;
      final secondUserId =
          currentUserId.compareTo(ownerId) < 0 ? ownerId : currentUserId;

      var chat = await supabase
          .from('chats')
          .select('id')
          .eq('user1_id', firstUserId)
          .eq('user2_id', secondUserId)
          .isFilter('property_id', null)
          .maybeSingle();

      if (chat == null) {
        chat = await supabase
            .from('chats')
            .insert({
              'user1_id': firstUserId,
              'user2_id': secondUserId,
            })
            .select('id')
            .single();
      }

      final chatId = chat['id']?.toString();
      if (chatId == null || chatId.isEmpty) {
        throw Exception('لم يتم إنشاء رقم المحادثة');
      }
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserName: companyName,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر فتح المحادثة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
