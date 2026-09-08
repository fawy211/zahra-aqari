import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aqari_app/views/login_screen.dart';
import 'package:aqari_app/views/offices_view.dart';
import 'package:aqari_app/views/companies_view.dart';
import 'package:aqari_app/views/subscription_screen.dart';

class HeaderWidget extends StatelessWidget {
  HeaderWidget({super.key});

  // مفتاح للتحكم في فتح القائمة المنبثقة برمجياً عند الضغط على الأيقونة المخصصة
  final GlobalKey<PopupMenuButtonState<String>> _menuKey =
      GlobalKey<PopupMenuButtonState<String>>();

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF002244), Color(0xFF003366), Color(0xFF004080)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // أيقونة مصغرة أو شعار جمالي يعطي طابعاً احترافياً
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // الجانب الأول: النصوص والتفاصيل
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "منصة زهرة العقارية",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Text(
                      "أهلاً بك",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text("•",
                          style:
                              TextStyle(color: Colors.white54, fontSize: 10)),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // الجانب الآخر: زر القائمة الجانبية فقط (بعد إزالة الفلتر)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: PopupMenuButton<String>(
              key: _menuKey,
              color: Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onSelected: (String value) {
                _handleMenuSelection(context, value);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                _buildPopupMenuItem('الدخول إلى حسابك', Icons.login),
                _buildPopupMenuItem(
                    'تسجيل حساب جديد', Icons.person_add_outlined),
                const PopupMenuDivider(),
                _buildPopupMenuItem('سجل الشركات العقارية', Icons.business),
                _buildPopupMenuItem('سجل المكاتب العقارية', Icons.store),
                _buildPopupMenuItem('الاشتراكات', Icons.card_membership),
                const PopupMenuDivider(),
                _buildPopupMenuItem('من نحن', Icons.info_outline),
                _buildPopupMenuItem('الاشتراطات العامة', Icons.gavel),
                _buildPopupMenuItem('اتصل بنا', Icons.phone_outlined),
                const PopupMenuDivider(),
                _buildPopupMenuItem('تسجيل الخروج', Icons.logout, isRed: true),
              ],
              child: IconButton(
                icon: const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 22),
                onPressed: () {
                  _menuKey.currentState?.showButtonMenu();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String text, IconData icon,
      {bool isRed = false}) {
    return PopupMenuItem<String>(
      value: text,
      child: Row(
        children: [
          Icon(icon,
              color: isRed ? Colors.red : const Color(0xFF003366), size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isRed ? Colors.red : Colors.grey[800],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // التوجيهات الفعلية للقائمة المنبثقة
  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'الدخول إلى حسابك':
      case 'تسجيل حساب جديد':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        break;

      case 'سجل الشركات العقارية':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CompaniesView()),
        );
        break;

      case 'سجل المكاتب العقارية':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OfficesView()),
        );
        break;

      case 'الاشتراكات':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SubscriptionScreen()),
        );
        break;

      case 'من نحن':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("من نحن - منصة زهرة",
                style: TextStyle(
                    color: Color(0xFF003366), fontWeight: FontWeight.bold)),
            content: const Text(
              "منصة زهرة العقارية هي منصتك المتكاملة للبحث عن العقارات، والشركات، والمكاتب العقارية باحترافية وسهولة تامة في السوق المصري.",
              style: TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("حسناً",
                    style: TextStyle(color: Color(0xFF003366))),
              ),
            ],
          ),
        );
        break;

      case 'الاشتراطات العامة':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("الاشتراطات العامة",
                style: TextStyle(
                    color: Color(0xFF003366), fontWeight: FontWeight.bold)),
            content: const Text(
              "• لا يجوز تكرار الإعلان خلال مدة 90 يوماً.\n• الالتزام بالدقة في بيانات العقار والأسعار.\n• المسؤولية الكاملة تقع على المعلن.",
              style: TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إغلاق",
                    style: TextStyle(color: Color(0xFF003366))),
              ),
            ],
          ),
        );
        break;

      case 'اتصل بنا':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("اتصل بنا",
                style: TextStyle(
                    color: Color(0xFF003366), fontWeight: FontWeight.bold)),
            content: const Text(
              "يسعدنا تواصلكم معنا عبر البريد الإلكتروني أو الخط الساخن لمنصة زهرة العقارية لدعمكم على مدار الساعة.",
              style: TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("موافق",
                    style: TextStyle(color: Color(0xFF003366))),
              ),
            ],
          ),
        );
        break;

      case 'تسجيل الخروج':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        break;
    }
  }
}
