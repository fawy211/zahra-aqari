import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddDelegateScreen extends StatefulWidget {
  final String companyId;

  const AddDelegateScreen({super.key, required this.companyId});

  @override
  State<AddDelegateScreen> createState() => _AddDelegateScreenState();
}

class _AddDelegateScreenState extends State<AddDelegateScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  bool canAddProperties = false;
  bool canReplyToMessages = false;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "دعوة مندوب جديد",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "أدخل البريد الإلكتروني المرتبط بحساب المندوب. سيتم إنشاء دعوة داخل النظام، لكن لن يُرسل بريد إلكتروني تلقائياً حالياً، ولن تُمنح الصلاحيات قبل قبول الدعوة من حساب المندوب.",
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: "البريد الإلكتروني",
                prefixIcon:
                    const Icon(Icons.email_outlined, color: Color(0xFF003366)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(email)
                    ? null
                    : "يرجى إدخال بريد إلكتروني صحيح";
              },
            ),
            const SizedBox(height: 24),
            const Text(
              "الصلاحيات المطلوبة",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 12),
            _permissionTile(
              title: "إضافة عقارات",
              subtitle: "السماح للمندوب بإضافة عقارات باسم الشركة",
              icon: Icons.home_work_outlined,
              value: canAddProperties,
              onChanged: (value) =>
                  setState(() => canAddProperties = value),
            ),
            const SizedBox(height: 12),
            _permissionTile(
              title: "الرد على الرسائل",
              subtitle: "السماح للمندوب بالرد على استفسارات العملاء",
              icon: Icons.chat_bubble_outline,
              value: canReplyToMessages,
              onChanged: (value) =>
                  setState(() => canReplyToMessages = value),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _sendInvitation,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "إنشاء الدعوة",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        secondary: Icon(icon, color: const Color(0xFF003366)),
        activeColor: const Color(0xFF003366),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showMessage("يرجى تسجيل الدخول أولاً", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // لا نعتمد على companyId المرسل من الواجهة وحده:
      // قاعدة البيانات تتحقق أيضاً من أن المستخدم مدير مساحة العمل.
      final workspace = await _supabase
          .from('workspaces')
          .select('id')
          .eq('company_id', widget.companyId)
          .eq('workspace_type', 'company')
          .maybeSingle();

      if (workspace == null) {
        throw Exception("لم يتم العثور على مساحة عمل الشركة");
      }

      final email = emailController.text.trim().toLowerCase();
      if (user.email != null && user.email!.trim().toLowerCase() == email) {
        throw Exception("لا يمكنك دعوة بريدك الإلكتروني كعضو في فريقك");
      }
      final expiresAt =
          DateTime.now().toUtc().add(const Duration(days: 7)).toIso8601String();

      await _supabase.from('workspace_invites').insert({
        'workspace_id': workspace['id'],
        'email': email,
        'role': 'broker',
        'permissions': {
          'can_add_properties': canAddProperties,
          'can_reply_to_messages': canReplyToMessages,
        },
        'invited_by': user.id,
        'status': 'pending',
        'expires_at': expiresAt,
      });

      if (!mounted) return;
      _showMessage(
        "تم إنشاء الدعوة داخل النظام. لم يتم إرسال بريد إلكتروني تلقائياً، ويجب استكمال قبولها من حساب المندوب.",
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        _showMessage(
          "تعذر إرسال الدعوة: ${error.toString()}",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
