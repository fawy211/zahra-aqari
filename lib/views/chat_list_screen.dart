import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:aqari_app/views/Chat_Screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "رسائلي",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: const Color(0xFF003366),
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            "يرجى تسجيل الدخول لعرض المحادثات",
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "رسائلي",
          style: TextStyle(
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('chats')
            .stream(primaryKey: ['id'])
            .order('updated_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF003366)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "حدث خطأ أثناء تحميل المحادثات:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            );
          }

          final chats = (snapshot.data ?? []).where((chat) {
            return chat['user1_id'] == currentUser.id ||
                chat['user2_id'] == currentUser.id;
          }).toList();

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "لا توجد محادثات حالياً",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final chatId = chat['id']?.toString() ?? '';
              final otherUserId = chat['user1_id'] == currentUser.id
                  ? chat['user2_id']?.toString()
                  : chat['user1_id']?.toString();

              DateTime? updatedAt;
              final rawTime = chat['updated_at'];
              if (rawTime is String) {
                updatedAt = DateTime.tryParse(rawTime)?.toLocal();
              } else if (rawTime is DateTime) {
                updatedAt = rawTime.toLocal();
              }

              final now = DateTime.now();
              final time = updatedAt == null
                  ? ''
                  : (updatedAt.year == now.year &&
                          updatedAt.month == now.month &&
                          updatedAt.day == now.day
                      ? DateFormat('HH:mm').format(updatedAt)
                      : DateFormat('dd/MM').format(updatedAt));

              if (chatId.isEmpty || otherUserId == null || otherUserId.isEmpty) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<Map<String, dynamic>?>(
                future: supabase
                    .from('profiles_public')
                    .select('name')
                    .eq('id', otherUserId)
                    .maybeSingle(),
                builder: (context, profileSnapshot) {
                  final rawName = profileSnapshot.data?['name']?.toString();
                  final chatName = rawName != null && rawName.trim().isNotEmpty
                      ? rawName.trim()
                      : 'محادثة';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            const Color(0xFF003366).withOpacity(0.1),
                        child: Text(
                          chatName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF003366),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      title: Text(
                        chatName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF003366),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: supabase
                              .from('messages')
                              .stream(primaryKey: ['id'])
                              .eq('chat_id', chatId)
                              .order('created_at', ascending: false),
                          builder: (context, messageSnapshot) {
                            final messages = messageSnapshot.data ?? [];
                            final latest = messages.isNotEmpty
                                ? messages.first['content']?.toString()
                                : null;
                            final preview = messageSnapshot.hasError
                                ? 'تعذر تحميل آخر رسالة'
                                : (latest == null || latest.isEmpty
                                    ? 'اضغط لعرض الرسائل'
                                    : latest);
                            return Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            );
                          },
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chatId,
                              otherUserName: chatName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
