import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // لون خلفية موحد ومريح
      appBar: AppBar(
        title: const Text(
          "سجل العمليات المالية",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF003366),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // استخدام StreamBuilder للاستماع الفوري للبيانات من جدول payments في Supabase وترتيبها تنازلياً حسب التاريخ
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('payments')
            .stream(primaryKey: ['id']).order('paymentDate', ascending: false),
        builder: (context, snapshot) {
          // 1. حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF003366)),
            );
          }

          // 2. معالجة الأخطاء
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
                      "خطأ في التحميل: ${snapshot.error}",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data ?? [];

          // 3. حالة البيانات الفارغة
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off_rounded,
                        size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      "لا توجد عمليات دفع مسجلة حتى الآن",
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ),
            );
          }

          // 4. عرض البيانات
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index];

              // استخراج المبلغ بحماية ضد اختلاف الأنواع (Type Casting Safe)
              final double amount = (data['amount'] != null)
                  ? (data['amount'] is int
                      ? (data['amount'] as int).toDouble()
                      : (data['amount'] is double
                          ? data['amount'] as double
                          : double.tryParse(data['amount'].toString()) ?? 0.0))
                  : 0.0;

              // استخراج الأيام بحماية
              final int days = data['days'] != null
                  ? int.tryParse(data['days'].toString()) ?? 0
                  : 0;

              // استخراج وتحويل التاريخ القادم من Supabase (غالباً ينزل كـ String بصيغة ISO أو DateTime)
              DateTime date;
              if (data['paymentDate'] != null) {
                date = DateTime.tryParse(data['paymentDate'].toString()) ??
                    DateTime.now();
              } else {
                date = DateTime.now();
              }

              final String status = data['status']?.toString() ?? 'completed';

              return PaymentCard(
                amount: amount,
                days: days,
                date: date,
                status: status,
              );
            },
          );
        },
      ),
    );
  }
}

// كارت احترافي لكل عملية دفع متناسق مع تصميم التطبيق
class PaymentCard extends StatelessWidget {
  final double amount;
  final int days;
  final DateTime date;
  final String status;

  const PaymentCard({
    super.key,
    required this.amount,
    required this.days,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    // تنسيق التاريخ والعملة
    final String formattedDate =
        DateFormat('yyyy/MM/dd - hh:mm a').format(date);
    final NumberFormat currencyFormat =
        NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م');

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // أيقونة العملية المالية
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF003366).withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFF003366),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // تفاصيل العملية (المبلغ ومدة التمييز والتاريخ)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currencyFormat.format(amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "مدة التمييز: $days يوم",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // حالة الدفع
            _buildStatusBadge(status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String text;
    Color color;
    Color bgColor;

    switch (status) {
      case 'completed':
        text = 'مكتملة';
        color = Colors.green.shade700;
        bgColor = Colors.green.withOpacity(0.1);
        break;
      case 'pending':
        text = 'قيد المعالجة';
        color = Colors.orange.shade800;
        bgColor = Colors.orange.withOpacity(0.1);
        break;
      case 'failed':
        text = 'مفشلة';
        color = Colors.red.shade700;
        bgColor = Colors.red.withOpacity(0.1);
        break;
      default:
        text = 'غير معروفة';
        color = Colors.grey.shade700;
        bgColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
