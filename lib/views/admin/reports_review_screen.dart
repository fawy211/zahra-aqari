import 'package:flutter/material.dart';
import '../../models/property_models.dart';
import '../../services/admin_service.dart';

class ReportsReviewScreen extends StatelessWidget {
  final AdminService _adminService = AdminService();

  ReportsReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "مراجعة البلاغات",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFB71C1C), // أحمر داكن احترافي
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<PropertyModel>>(
        stream: _adminService.getReportedProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "حدث خطأ أثناء تحميل البلاغات:\n${snapshot.error}",
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
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    "لا توجد بلاغات حالياً",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final properties = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return _buildReportCard(context, property);
            },
          );
        },
      ),
    );
  }

  // تصميم كارت البلاغ بشكل أنيق وبارز
  Widget _buildReportCard(BuildContext context, PropertyModel property) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToDetail(context, property),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // مؤشر تحذيري لعدد البلاغات
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flag, color: Colors.red, size: 20),
                    Text(
                      "${property.reportCount}",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // تفاصيل العقار المبلغ عنه
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF003366),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "السعر: ${property.price} ج.م",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // شاشة تفاصيل العقار المبلغ عنه للمراجعة واتخاذ القرار
  void _navigateToDetail(BuildContext context, PropertyModel property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              "تفاصيل البلاغ والمراجعة",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF003366),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("السعر: ${property.price} ج.م",
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          Chip(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            label: Text(
                              "عدد البلاغات: ${property.reportCount}",
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "بيانات إضافية:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF003366)),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: property.metadata.isEmpty
                        ? const Center(
                            child: Text("لا توجد بيانات إضافية",
                                style: TextStyle(color: Colors.grey)),
                          )
                        : ListView(
                            children: property.metadata.entries
                                .map((e) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("${e.key}: ",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87)),
                                          Expanded(
                                            child: Text("${e.value}",
                                                style: TextStyle(
                                                    color: Colors.grey[700])),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // أزرار اتخاذ القرار (اعتماد / حذف)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("اعتماد الإعلان",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _adminService.resolveReport(property.id!,
                              delete: false);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "تم اعتماد الإعلان وإزالة البلاغات بنجاح")),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("حذف العقار",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        onPressed: () =>
                            _showDeleteConfirm(context, property.id!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // نافذة تأكيد الحذف بتصميم تحذيري أنيق
  void _showDeleteConfirm(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("تأكيد الحذف النهائي"),
          ],
        ),
        content: const Text(
          "هل أنت متأكد أنك تريد حذف هذا العقار نهائياً من المنصة؟ لا يمكن التراجع عن هذا الإجراء.",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              _adminService.resolveReport(id, delete: true);
              Navigator.pop(context); // إغلاق الـ Dialog
              Navigator.pop(context); // إغلاق شاشة التفاصيل
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم حذف العقار بنجاح")),
              );
            },
            child: const Text("حذف نهائي"),
          ),
        ],
      ),
    );
  }
}
