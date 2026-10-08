import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/features/property/screens/add_property_screen.dart';

class CompanyDashboardView extends StatelessWidget {
  const CompanyDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final SupabaseClient supabase = Supabase.instance.client;
    final String currentUserId = supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "لوحة تحكم الشركة",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // استخدام Supabase Stream لجلب العقارات الخاصة بالمستخدم الحالي بشكل حي
        stream: supabase
            .from('properties')
            .stream(primaryKey: ['id']).eq('ownerId', currentUserId),
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
                  "حدث خطأ أثناء تحميل البيانات:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            );
          }

          final docs = snapshot.data ?? [];

          // حساب الإحصائيات
          final verifiedCount =
              docs.where((d) => d['status'] == 'verified').length;
          final pendingCount =
              docs.where((d) => d['status'] == 'pending').length;
          final rejectedCount =
              docs.where((d) => d['status'] == 'rejected').length;

          return Column(
            children: [
              // قسم الإحصائيات بتصميم راقٍ
              _buildStatsRow(
                  docs.length, verifiedCount, pendingCount, rejectedCount),

              // قائمة العقارات أو حالة الفراغ
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_work_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              "لم تقم بإضافة عقارات بعد",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "اضغط على زر الإضافة أدناه لنشر عقارك الأول",
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index];
                          final String propertyId =
                              data['id']?.toString() ?? '';
                          return _buildPropertyCard(context, propertyId, data);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
        ),
        label: const Text("إضافة عقار جديد",
            style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // صف الإحصائيات العلوي
  Widget _buildStatsRow(int total, int verified, int pending, int rejected) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _statItem("الكل", total.toString(), const Color(0xFF003366)),
          const SizedBox(width: 8),
          _statItem("موثق", verified.toString(), Colors.green),
          const SizedBox(width: 8),
          _statItem("معلق", pending.toString(), Colors.orange),
          const SizedBox(width: 8),
          _statItem("مرفوض", rejected.toString(), Colors.red),
        ],
      ),
    );
  }

  // تصميم عنصر الإحصائية الفردي
  Widget _statItem(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // تصميم كارت العقار الخاص بالشركة
  Widget _buildPropertyCard(
      BuildContext context, String id, Map<String, dynamic> data) {
    final String title = data['title'] ?? "بدون عنوان";
    final String price = data['price']?.toString() ?? '0';
    final String status = data['status'] ?? 'pending';

    Color statusColor;
    Color statusBgColor;
    String statusText;

    if (status == 'verified') {
      statusColor = Colors.green;
      statusBgColor = Colors.green.withOpacity(0.1);
      statusText = 'موثق';
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusBgColor = Colors.red.withOpacity(0.1);
      statusText = 'مرفوض';
    } else {
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.withOpacity(0.1);
      statusText = 'قيد المراجعة';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
