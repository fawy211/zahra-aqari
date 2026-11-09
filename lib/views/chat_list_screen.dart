import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // تأكد من إضافة intl في الـ pubspec
import 'package:aqari_app/services/chat_service.dart';
import 'package:aqari_app/views/Chat_Screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  Future<List<ChatSummary>>? _chats;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  void _loadChats() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _chats = null;
      return;
    }
    _chats = _chatService.chatsForUser(userId);
  }

  Future<void> _reload() async {
    setState(_loadChats);
    final chats = _chats;
    if (chats != null) await chats;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;

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
      body: currentUser == null
          ? const Center(
              child: Text(
                "يرجى تسجيل الدخول لعرض المحادثات",
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            )
          : FutureBuilder<List<ChatSummary>>(
              future: _chats,
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
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  );
                }

                // يعتمد جدول chats على property_id، لذا تكون مشاركة المستخدم
                // إما ملكية العقار أو إرسال رسالة في المحادثة (ChatService).
                final docs = snapshot.data ?? [];

                return RefreshIndicator(
                  color: const Color(0xFF003366),
                  onRefresh: _reload,
                  child: docs.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 140),
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Center(
                              child: Text(
                                "لا توجد محادثات حالياً",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: docs.length,
                          itemBuilder: (context, index) =>
                              _buildChatTile(context, docs[index]),
                        ),
                );
              },
            ),
    );
  }

  Widget _buildChatTile(BuildContext context, ChatSummary chat) {
    final String chatName = chat.title;
    final String lastMessage =
        chat.lastMessage.isEmpty ? "ابدأ المحادثة الآن" : chat.lastMessage;
    final String time = _formatTime(chat.updatedAt);

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chat.chatId,
              otherUserName: chatName,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('dd/MM').format(date);
  }
}
