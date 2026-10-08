import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OfficesView extends StatelessWidget {
  const OfficesView({super.key});

  // دالة احترافية للاتصال المباشر مع التحقق من صحة الرقم
  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("رقم الهاتف غير متوفر لهذا المكتب"),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("تعذر إجراء المكالمة"),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "المكاتب والشركات العقارية",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF003366),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // استخدام StreamBuilder للاستماع الفوري للبيانات من جدول offices في Supabase وترتيبها حسب الاسم
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('offices')
            .stream(primaryKey: ['id']).order('name', ascending: true),
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
                    Text(
                      "حدث خطأ في تحميل البيانات: ${snapshot.error}",
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_outlined,
                        size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      "لا توجد مكاتب مسجلة حالياً",
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              final phone = data['phone']?.toString() ?? '';

              return _OfficeCard(
                name: data['name']?.toString() ?? 'مكتب عقاري',
                location: data['location']?.toString() ?? 'غير محدد',
                phone: phone,
                logoUrl: data['logoUrl']?.toString() ?? '',
                onCall: () => _makePhoneCall(context, phone),
              );
            },
          );
        },
      ),
    );
  }
}

// الكلاس الخاص بتصميم الكارت بمعايير عالية الجودة وتوافق مع Material 3
class _OfficeCard extends StatelessWidget {
  final String name, location, phone, logoUrl;
  final VoidCallback onCall;

  const _OfficeCard({
    required this.name,
    required this.location,
    required this.phone,
    required this.logoUrl,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // الشعار بتصميم دائري فاخر وحماية للصورة
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF003366).withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                image: logoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(logoUrl),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {},
                      )
                    : null,
              ),
              child: logoUrl.isEmpty
                  ? const Icon(Icons.business_rounded,
                      size: 28, color: Color(0xFF003366))
                  : null,
            ),
            const SizedBox(width: 14),

            // المعلومات الأساسية
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 15, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // زر الاتصال المباشر بتصميم أنيق
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF003366).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.phone_in_talk_rounded,
                    color: Color(0xFF003366), size: 22),
                onPressed: onCall,
                tooltip: "اتصال مباشر",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
