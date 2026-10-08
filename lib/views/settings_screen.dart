import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/views/login_screen.dart'; // تأكد من مسار شاشة تسجيل الدخول

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  Future<void> _logout(BuildContext context) async {
    try {
      await _supabase.auth.signOut();
      if (context.mounted) {
        // العودة لشاشة تسجيل الدخول وحذف كافة الشاشات السابقة من الذاكرة
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("حدث خطأ أثناء تسجيل الخروج: ${e.toString()}"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "الإعدادات",
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // معلومات المستخدم الحالي إن وجدت
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Color(0xFF003366), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "حساب المستخدم",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email ?? "مسجل بحساب معتمد",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF003366),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // قسم التفضيلات والإعدادات العامة
          const Text(
            "التفضيلات العامة",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: Color(0xFF003366)),
                  ),
                  title: const Text("الإشعارات",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text("استقبال تنبيهات العقارات والرسائل",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  value: _notificationsEnabled,
                  activeColor: const Color(0xFFC5A059),
                  onChanged: (v) {
                    setState(() {
                      _notificationsEnabled = v;
                    });
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.language_rounded,
                        color: Color(0xFF003366)),
                  ),
                  title: const Text("لغة التطبيق",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text("العربية",
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.w600)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    // نافذة تغيير اللغة مستقبلاً
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.dark_mode_rounded,
                        color: Color(0xFF003366)),
                  ),
                  title: const Text("الوضع الليلي",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text("تفعيل المظهر الداكن",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  value: _darkModeEnabled,
                  activeColor: const Color(0xFFC5A059),
                  onChanged: (v) {
                    setState(() {
                      _darkModeEnabled = v;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // قسم الحساب والدعم
          const Text(
            "الدعم والحساب",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.privacy_tip_rounded,
                        color: Color(0xFF003366)),
                  ),
                  title: const Text("سياسة الخصوصية",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.grey),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: Colors.redAccent),
                  ),
                  title: const Text(
                    "تسجيل الخروج",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
