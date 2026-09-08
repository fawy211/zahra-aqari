import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/widgets/custom_header.dart'; // تأكد من مسار الاستيراد الصحيح لديك
import 'chat_screen.dart'; // تأكد من مسار استيراد شاشة الدردشة الصحيح لديك

class CompaniesView extends StatefulWidget {
  const CompaniesView({super.key});

  @override
  State<CompaniesView> createState() => _CompaniesViewState();
}

class _CompaniesViewState extends State<CompaniesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final SupabaseClient _supabase = Supabase.instance.client;
  late final String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _supabase.auth.currentUser?.id;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: const HeaderWidget(),
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // في Supabase، نستخدم الـ stream ونقوم بالفلترة حسب الـ role باستخدام .inFilter
              stream: _supabase.from('users').stream(
                  primaryKey: ['id']).inFilter('role', ['office', 'company']),
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
                        "حدث خطأ في تحميل البيانات:\n${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ),
                  );
                }

                final allData = snapshot.data ?? [];

                if (allData.isEmpty) {
                  return const Center(
                    child: Text("لا توجد مكاتب أو شركات مسجلة حالياً",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                // استبعاد المستخدم الحالي من القائمة، ثم الفلترة والترتيب محلياً
                final docs = allData.where((data) {
                  final String docId = data['id']?.toString() ?? '';
                  if (docId == currentUserId) {
                    return false; // عدم إظهار الحساب الشخصي إن كان شركة/مكتب
                  }
                  final name = (data['companyName'] ?? data['fullName'] ?? '')
                      .toString()
                      .toLowerCase();
                  return name.contains(_searchQuery);
                }).toList()
                  ..sort((a, b) {
                    final nameA =
                        (a['companyName'] ?? a['fullName'] ?? '').toString();
                    final nameB =
                        (b['companyName'] ?? b['fullName'] ?? '').toString();
                    return nameA.compareTo(nameB);
                  });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("لا توجد نتائج مطابقة للبحث",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final String targetUserId = data['id']?.toString() ?? '';
                    return _buildCompanyCard(data, targetUserId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // شريط البحث بتصميم أنيق
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'ابحث عن شركة أو مكتب عقاري...',
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF003366)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF003366), width: 1.5),
          ),
        ),
        onChanged: (value) =>
            setState(() => _searchQuery = value.trim().toLowerCase()),
      ),
    );
  }

  // تصميم كارت الشركة أو المكتب بمعايير عالية مع تفعيل الانتقال للمحادثة
  Widget _buildCompanyCard(Map<String, dynamic> data, String targetUserId) {
    final String displayName =
        data['companyName'] ?? data['fullName'] ?? 'جهة غير مسماة';
    final bool isOffice = data['role'] == 'office';
    final String roleText = isOffice ? 'مكتب عقاري' : 'شركة عقارية';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      shadowColor: Colors.black12,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF003366).withOpacity(0.1),
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
            style: const TextStyle(
              color: Color(0xFF003366),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF003366),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            roleText,
            style: TextStyle(
              color: isOffice ? Colors.orange[800] : Colors.blue[800],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر اختصار للدردشة المباشرة
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF003366)),
              onPressed: () => _openChat(targetUserId, displayName),
              tooltip: "مراسلة",
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
        onTap: () {
          // فتح المحادثة مباشرة عند الضغط على الكارت بالكامل أيضاً
          _openChat(targetUserId, displayName);
        },
      ),
    );
  }

  // دالة لإنشاء أو توليد معرف محادثة فريد وثابت بين أي مستخدمين لمنع تكرار الغرف في Supabase
  Future<void> _openChat(String targetUserId, String targetUserName) async {
    if (currentUserId == null) return;

    // لتوحيد الـ chatId بغض النظر عن من بدأ المحادثة، نقوم بترتيب الـ IDs أبجدياً
    List<String> ids = [currentUserId!, targetUserId];
    ids.sort();
    String chatId = "${ids[0]}_${ids[1]}";

    try {
      // التحقق من وجود المحادثة مسبقاً في جدول chats
      final existingChat = await _supabase
          .from('chats')
          .select('id')
          .eq('id', chatId)
          .maybeSingle();

      if (existingChat == null) {
        // إذا لم تكن موجودة، يتم إنشاؤها
        await _supabase.from('chats').insert({
          'id': chatId,
          'participants': [currentUserId, targetUserId],
          'createdAt': DateTime.now().toIso8601String(),
          'lastMessage': '',
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      if (!mounted) return;

      // الانتقال لشاشة المحادثة
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserName: targetUserName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تعذر فتح المحادثة: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
