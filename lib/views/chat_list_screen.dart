import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // تأكد من إضافة intl في الـ pubspec
import 'package:aqari_app/views/Chat_Screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SupabaseClient supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "رسائلي",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // في Supabase، يتم استخدام الـ stream للمتابعة الحية للجدول وترتيبه تنازلياً
        stream: supabase
            .from('chats')
            .stream(primaryKey: ['id']).order('updatedAt', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF003366)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "حدث خطأ أثناء تحميل المحادثات:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            );
          }

          // فلترة المحادثات محلياً لتشمل فقط المحادثات التي يكون المستخدم الحالي مشاركاً فيها
          // (تأكد أن عمود participants في قاعدة البيانات مخزن كـ Array أو JSON يحتوي على IDs المستخدمين)
          final allChats = snapshot.data ?? [];
          final docs = allChats.where((chat) {
            final participants = chat['participants'];
            if (participants is List) {
              return participants.contains(currentUser.id);
            }
            return false;
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    "لا توجد محادثات حالياً",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final chatData = docs[index];
              final String chatId = chatData['id']?.toString() ?? '';

              String chatName = chatData['otherUserName'] ?? "مستخدم";
              String lastMessage =
                  chatData['lastMessage'] ?? "ابدأ المحادثة الآن";

              // معالجة وقت الرسالة في Supabase (عادة ما يُخزن كـ String بنظام ISO8601 أو Timestamp)
              String time = "";
              var rawTime = chatData['updatedAt'];
              if (rawTime != null) {
                DateTime? messageDate;
                if (rawTime is String) {
                  messageDate = DateTime.tryParse(rawTime);
                } else if (rawTime is DateTime) {
                  messageDate = rawTime;
                }

                if (messageDate != null) {
                  DateTime now = DateTime.now();

                  // إذا كانت الرسالة اليوم، نعرض الوقت فقط، وإلا نعرض التاريخ
                  if (messageDate.year == now.year &&
                      messageDate.month == now.month &&
                      messageDate.day == now.day) {
                    time = DateFormat('HH:mm').format(messageDate);
                  } else {
                    time = DateFormat('dd/MM').format(messageDate);
                  }
                }
              }

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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF003366).withOpacity(0.1),
                    child: Text(
                      chatName.isNotEmpty ? chatName[0].toUpperCase() : "م",
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
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      lastMessage,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      const Icon(Icons.arrow_forward_ios,
                          size: 12, color: Colors.grey),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chatId,
                        otherUserName: chatName,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
