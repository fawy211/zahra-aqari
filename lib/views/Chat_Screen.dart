import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart' as intl;

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  late final User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = _supabase.auth.currentUser;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.otherUserName,
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
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // في Supabase، نستخدم الـ stream لجلب الرسائل الخاصة بالمحادثة وترتيبها تنازلياً
              stream: _supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq('chat_id', widget.chatId)
                  .order('timestamp', ascending: false),
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
                        "حدث خطأ أثناء تحميل الرسائل:\n${snapshot.error}",
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          "لا توجد رسائل. ابدأ المحادثة الآن!",
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, // مهم جداً للمحادثات لتبدأ من الأسفل
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var msg = docs[index];
                    bool isMe = msg['senderId'] == currentUser?.id;
                    String text = msg['text'] ?? '';

                    // معالجة التوقيت في Supabase (سواء كان String أو DateTime)
                    String timeStr = '';
                    var rawTime = msg['timestamp'];
                    if (rawTime != null) {
                      DateTime? messageDate;
                      if (rawTime is String) {
                        messageDate = DateTime.tryParse(rawTime);
                      } else if (rawTime is DateTime) {
                        messageDate = rawTime;
                      }

                      if (messageDate != null) {
                        timeStr = intl.DateFormat('HH:mm').format(messageDate);
                      }
                    }

                    return _buildMessageBubble(text, timeStr, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // تصميم فقاعة الرسالة بشكل أنيق وداعم للاتجاهات
  Widget _buildMessageBubble(String text, String time, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF003366) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: isMe ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // شريط كتابة وإرسال الرسائل بتصميم راقٍ
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: "اكتب رسالتك هنا...",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF003366),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    String text = _controller.text.trim();
    _controller.clear();

    try {
      final currentTime = DateTime.now().toIso8601String();

      // 1. إضافة الرسالة إلى جدول messages (تأكد من وجود عمود chat_id يربطها بالمحادثة)
      await _supabase.from('messages').insert({
        'chat_id': widget.chatId,
        'text': text,
        'senderId': currentUser?.id,
        'timestamp': currentTime,
      });

      // 2. تحديث جدول المحادثات الرئيسي (chats) لتحديث آخر رسالة ووقت التحديث
      await _supabase.from('chats').update({
        'lastMessage': text,
        'updatedAt': currentTime,
      }).eq('id', widget.chatId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("فشل إرسال الرسالة: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
