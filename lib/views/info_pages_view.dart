import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InfoPagesView extends StatelessWidget {
  final String title;
  final String
      docId; // في Supabase يمكن أن يكون معرف نصي (slug) أو رقمي، حسب تصميم الجدول لديك

  const InfoPagesView({
    super.key,
    required this.title,
    required this.docId,
  });

  Future<Map<String, dynamic>?> _fetchPageContent() async {
    final supabase = Supabase.instance.client;

    // افتراض أن اسم الجدول هو 'pages' وأن الحقل المعرف الأساسي هو 'id' أو 'slug'
    // يمكنك تعديل 'id' حسب اسم العمود الأساسي في جدول Supabase لديك (مثلاً 'id' أو 'slug')
    final response =
        await supabase.from('pages').select().eq('id', docId).maybeSingle();

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          title,
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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchPageContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF003366)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    const Text(
                      "عذراً، حدث خطأ في تحميل الصفحة.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;

          if (data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.article_outlined,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      "المحتوى غير متوفر حالياً.",
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // استخراج المحتوى من أعمدة Supabase (يمكن أن يكوناسم العمود 'content' أو 'text')
          final String content =
              data['content'] ?? data['text'] ?? "لا يوجد محتوى لعرضه.";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.all(20.0),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.shade200, thickness: 1.5),
                  const SizedBox(height: 16),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.8,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
