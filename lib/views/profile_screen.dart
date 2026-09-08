import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aqari_app/models/user_model.dart';
import 'package:aqari_app/views/edit_profile_screen.dart';
import 'package:aqari_app/views/company_registration_screen.dart';
import 'package:aqari_app/views/admin_panel_screen.dart';
import 'package:aqari_app/views/chat_list_screen.dart';
import 'package:aqari_app/views/favorites_view.dart';
import 'package:aqari_app/views/payment_history_screen.dart';
import 'package:aqari_app/views/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSubscription;

  User? _currentUser;
  bool _isLoadingData = false;
  UserModel? _userModel;
  Map<String, dynamic> _walletData = {'balance': 0, 'currency': 'ج.م'};

  @override
  void initState() {
    super.initState();
    _currentUser = supabase.auth.currentUser;
    if (_currentUser != null) {
      _loadUserData(_currentUser!.id, _currentUser!.email ?? '');
    }

    // مراقبة دقيقة لتغيرات تسجيل الدخول/الخروج
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        _currentUser = data.session?.user ?? supabase.auth.currentUser;
        if (_currentUser != null) {
          _loadUserData(_currentUser!.id, _currentUser!.email ?? '');
        } else {
          _userModel = null;
          _walletData = {'balance': 0, 'currency': 'ج.م'};
        }
      });
    });
  }

  Future<void> _loadUserData(String userId, String email) async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);

    try {
      // 1. جلب بيانات الـ Profile
      Map<String, dynamic>? profileRes;
      try {
        profileRes = await supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
      } catch (_) {
        profileRes = null;
      }

      if (profileRes != null) {
        _userModel = UserModel.fromMap(profileRes, userId);
      } else {
        _userModel = UserModel(
          uid: userId,
          email: email,
          name: email.split('@')[0],
        );
      }

      // 2. جلب بيانات المحفظة
      try {
        final walletRes = await supabase
            .from('wallets')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        if (walletRes != null) {
          _walletData = walletRes;
        }
      } catch (_) {
        _walletData = {'balance': 0, 'currency': 'ج.م'};
      }
    } catch (_) {
      _userModel = UserModel(uid: userId, email: email, name: 'مستخدم');
      _walletData = {'balance': 0, 'currency': 'ج.م'};
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الطريقة الآمنة نهائياً: لو المستخدم غير مسجل دخول، اعرض شاشة تسجيل الدخول فوراً
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("حسابي",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF003366),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle_outlined,
                    size: 80, color: Color(0xFF003366)),
                const SizedBox(height: 16),
                const Text(
                  "يرجى تسجيل الدخول لعرض حسابك والتحكم بإعداداتك",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text("تسجيل الدخول",
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // لو جارٍ تحميل البيانات، اعرض مؤشر تحميل نظيف داخل Scaffold من غير شاشات سوداء
    if (_isLoadingData || _userModel == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("حسابي",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF003366),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF003366)),
        ),
      );
    }

    final bool isAdmin = _userModel!.accountType == 'admin';
    final balance = _walletData['balance'] ?? 0;
    final currency = _walletData['currency'] ?? 'ج.م';
    final email = _currentUser!.email ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "حسابي",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF003366),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildProfileHeader(_userModel!, email),
          const SizedBox(height: 20),
          _buildWalletCard(balance, currency),
          const SizedBox(height: 20),
          const _SectionTitle("الإعدادات العامة"),
          _ProfileTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: "رسائلي",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
            ),
          ),
          _ProfileTile(
            icon: Icons.favorite_border_rounded,
            title: "عقاراتي المفضلة",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FavoritesView()),
            ),
          ),
          _ProfileTile(
            icon: Icons.receipt_long_rounded,
            title: "سجل العمليات المالية",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
            ),
          ),
          _ProfileTile(
            icon: Icons.edit_rounded,
            title: "تعديل الملف الشخصي",
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    userData: _userModel!.toMap(),
                  ),
                ),
              );
              if (_currentUser != null) {
                _loadUserData(_currentUser!.id, _currentUser!.email ?? '');
              }
            },
          ),
          if (isAdmin) ...[
            const SizedBox(height: 10),
            const _SectionTitle("لوحة الإدارة"),
            _ProfileTile(
              icon: Icons.admin_panel_settings_rounded,
              title: "لوحة تحكم المسؤول",
              color: Colors.red.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const _SectionTitle("حساب الشركات"),
          _ProfileTile(
            icon: Icons.business_rounded,
            title: "توثيق شركتي",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CompanyRegistrationScreen()),
            ),
          ),
          const SizedBox(height: 20),
          _ProfileTile(
            icon: Icons.logout_rounded,
            title: "تسجيل الخروج",
            color: Colors.red.shade700,
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel userModel, String email) {
    final String displayName =
        userModel.name.isNotEmpty ? userModel.name : email.split('@')[0];
    final String initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : "U";

    return Column(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundColor: const Color(0xFF003366).withOpacity(0.1),
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003366),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildWalletCard(num balance, String currency) {
    return Card(
      elevation: 0,
      color: const Color(0xFF003366),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "الرصيد المتاح",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$balance $currency",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "تسجيل الخروج",
          style:
              TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold),
        ),
        content: Text(
          "هل أنت متأكد من رغبتك في تسجيل الخروج؟",
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("إلغاء", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("تسجيل الخروج",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await supabase.auth.signOut();
    }
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color tileColor = color ?? const Color(0xFF003366);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tileColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: tileColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: tileColor == Colors.red.shade700
                ? Colors.red.shade700
                : const Color(0xFF003366),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return PageStorageKey(title) == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          );
  }
}
