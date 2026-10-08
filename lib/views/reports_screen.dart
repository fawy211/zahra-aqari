import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _fetchFinancialReports();
  }

  Future<List<Map<String, dynamic>>> _fetchFinancialReports() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('payments')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _refreshReports() async {
    setState(() {
      _reportsFuture = _fetchFinancialReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "التقارير المالية",
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF003366)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "حدث خطأ في تحميل التقارير",
                style: TextStyle(color: Colors.red.shade700),
              ),
            );
          }

          final docs = snapshot.data ?? [];

          // حساب إجمالي المدفوعات المالية
          double totalAmount = 0;
          for (var item in docs) {
            final amount = (item['amount'] ?? 0).toDouble();
            totalAmount += amount;
          }

          final currencyFormat =
              NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م');

          return RefreshIndicator(
            onRefresh: _refreshReports,
            color: const Color(0xFF003366),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. كارت الإجمالي المالي
                _buildSummaryCard(
                  title: "إجمالي المدفوعات والعمليات",
                  value: currencyFormat.format(totalAmount),
                  color: const Color(0xFF003366),
                ),
                const SizedBox(height: 24),

                // 2. عنوان قسم العمليات
                const Text(
                  "سجل العمليات المالية",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. عرض العمليات إن وجدت أو رسالة فارغة
                if (docs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(30),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text(
                          "لا توجد عمليات مالية مسجلة حتى الآن",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                else
                  ...docs.map((item) {
                    final title = item['title'] ?? 'عملية تمييز إعلان / باقة';
                    final amount = (item['amount'] ?? 0).toDouble();
                    final String? createdAt = item['created_at'];

                    String dateStr = "حديثاً";
                    if (createdAt != null) {
                      final DateTime date = DateTime.parse(createdAt).toLocal();
                      dateStr = DateFormat('yyyy/MM/dd - hh:mm a').format(date);
                    }

                    return _buildTransactionItem(
                      title: title,
                      amount: currencyFormat.format(amount),
                      date: dateStr,
                    );
                  }),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.account_balance_wallet_rounded,
                    color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String amount,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF003366).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt_long_rounded,
              color: Color(0xFF003366), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF003366),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            date,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.green.shade700,
          ),
        ),
      ),
    );
  }
}
