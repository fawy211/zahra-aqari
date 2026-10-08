import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SupabaseClient supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "لوحة تحكم المسؤول",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('properties').stream(primaryKey: ['id']).map(
            (rows) => rows.where((row) => row['status'] == 'pending').toList()),
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
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_outlined,
                      size: 64, color: Colors.green.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    "لا توجد طلبات توثيق معلقة حالياً",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final String docId = doc['id']?.toString() ?? '';
              return PropertyApprovalTile(docId: docId, data: doc);
            },
          );
        },
      ),
    );
  }
}

// تصميم كارت مراجعة العقار بشكل احترافي ومرتب
class PropertyApprovalTile extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const PropertyApprovalTile({
    super.key,
    required this.docId,
    required this.data,
  });

  Future<void> _updateStatus(
      BuildContext context, String status, String statusName) async {
    try {
      final SupabaseClient supabase = Supabase.instance.client;
      await supabase
          .from('properties')
          .update({'status': status}).eq('id', docId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم $statusName العقار بنجاح'),
            backgroundColor: status == 'verified' ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = data['title'] ?? "بدون عنوان";
    final String price = data['price']?.toString() ?? '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // أيقونة تعبيرية للعقار المعلق
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF003366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home_work_outlined,
                  color: Color(0xFF003366), size: 22),
            ),
            const SizedBox(width: 12),
            // تفاصيل العقار
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF003366),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "السعر: $price ج.م",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // أزرار اتخاذ القرار (قبول / رفض)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon:
                        const Icon(Icons.check, color: Colors.green, size: 20),
                    tooltip: "قبول وتوثيق",
                    onPressed: () =>
                        _updateStatus(context, 'verified', 'توثيق وقبول'),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    tooltip: "رفض الإعلان",
                    onPressed: () => _updateStatus(context, 'rejected', 'رفض'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
