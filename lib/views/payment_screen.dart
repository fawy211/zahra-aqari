import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  final String propertyId;

  const PaymentScreen({super.key, required this.propertyId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Future<void> _confirmAndProcess(
      double price, int days, String packageTitle) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "تأكيد الاشتراك",
          style:
              TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold),
        ),
        content: Text(
          price == 0
              ? "هل أنت متأكد من الاشتراك في $packageTitle؟"
              : "هل أنت متأكد من الاشتراك في $packageTitle بقيمة ${NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م').format(price)}؟",
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("إلغاء", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("تأكيد الاشتراك",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // لا يميّز التطبيق الإعلان ولا يُفعِّل الباقة من جهة العميل. يجب تأكيد
      // الدفع من الخادم أولاً، ثم تُكتب الاستحقاقات من جهة موثوقة.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            price == 0
                ? "الخدمة المجانية متاحة لك تلقائياً."
                : "لتفعيل $packageTitle يرجى إتمام عملية الدفع وتأكيدها من الإدارة.",
          ),
          backgroundColor: const Color(0xFF003366),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "الاشتراك فى منصة زهره العقارية",
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
      body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "اختر الباقة المناسبة لاحتياجاتك:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. الخدمة المجانية للمشتركين
                  _buildPackageCard(
                    title: "الخدمة المجانية للمشتركين",
                    price: 0.0,
                    days: 30,
                    icon: Icons.card_giftcard_rounded,
                    features: [
                      "إضافة 3 إعلانات شهرياً",
                      "فيديو خاص بكل إعلان لا تتجاوز مدته 60 ثانية",
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. الباقة العامة
                  _buildPackageCard(
                    title: "الباقة العامة",
                    price: 100.0,
                    days: 30,
                    icon: Icons.star_border_rounded,
                    features: [
                      "إضافة 10 إعلانات شهرياً",
                      "فيديو خاص بكل إعلان لا تتجاوز مدته 180 ثانية",
                      "إمكانية زيادة عدد الإعلانات بتكلفة 10 ج.م لكل إعلان",
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. الباقة المميزة
                  _buildPackageCard(
                    title: "الباقة المميزة",
                    price: 250.0,
                    days: 30,
                    icon: Icons.star_rounded,
                    features: [
                      "إضافة 25 إعلاناً شهرياً",
                      "فيديو خاص بكل إعلان لا تتجاوز مدته 180 ثانية",
                      "إمكانية زيادة عدد الإعلانات بتكلفة 10 ج.م لكل إعلان",
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4. الباقة الذهبية
                  _buildPackageCard(
                    title: "الباقة الذهبية",
                    price: 500.0,
                    days: 30,
                    icon: Icons.workspace_premium_rounded,
                    features: [
                      "إضافة عدد غير محدد من الإعلانات",
                      "تميز عدد 5 إعلانات من اختيار العميل",
                      "فيديو خاص بكل إعلان لا تتجاوز مدته 300 ثانية",
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPackageCard({
    required String title,
    required double price,
    required int days,
    required IconData icon,
    required List<String> features,
  }) {
    final NumberFormat currencyFormat =
        NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م');
    final bool isFree = price == 0;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _confirmAndProcess(price, days, title),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF003366),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF003366),
                      ),
                    ),
                  ),
                  Text(
                    isFree ? "مجاناً" : "${currencyFormat.format(price)} / شهر",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isFree
                          ? Colors.green.shade700
                          : const Color(0xFF003366),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Divider(height: 1),
              ),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isFree ? "اختر الخدمة المجانية" : "اختر الباقة",
                  style: const TextStyle(
                    color: Color(0xFF003366),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
