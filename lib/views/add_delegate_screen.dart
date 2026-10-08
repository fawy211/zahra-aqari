import 'package:flutter/foundation.dart';
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
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool canAddProperties = false;
  bool canReplyToMessages = false;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "إضافة مندوب جديد",
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
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 10),
            // حقل اسم المندوب
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "اسم المندوب",
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon:
                    const Icon(Icons.person_outline, color: Color(0xFF003366)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Color(0xFF003366), width: 1.5),
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? "يرجى إدخال اسم المندوب"
                  : null,
            ),
            const SizedBox(height: 16),
            // حقل البريد الإلكتروني
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "البريد الإلكتروني",
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon:
                    const Icon(Icons.email_outlined, color: Color(0xFF003366)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Color(0xFF003366), width: 1.5),
                ),
              ),
              validator: (v) => v == null || !v.contains('@')
                  ? "يرجى إدخال بريد إلكتروني صحيح"
                  : null,
            ),
            const SizedBox(height: 24),
            const Text(
              "صلاحيات المندوب",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 12),
            // كارت صلاحية إضافة العقارات
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                title: const Text("إضافة عقارات",
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text(
                    "السماح للمندوب بإضافة عقارات جديدة باسم الشركة",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                secondary: const Icon(Icons.home_work_outlined,
                    color: Color(0xFF003366)),
                activeColor: const Color(0xFF003366),
                value: canAddProperties,
                onChanged: (val) => setState(() => canAddProperties = val),
              ),
            ),
            const SizedBox(height: 12),
            // كارت صلاحية الرد على الرسائل
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                title: const Text("الرد على الرسائل",
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text(
                    "السماح للمندوب بالتواصل والرد على استفسارات العملاء",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                secondary: const Icon(Icons.chat_bubble_outline,
                    color: Color(0xFF003366)),
                activeColor: const Color(0xFF003366),
                value: canReplyToMessages,
                onChanged: (val) => setState(() => canReplyToMessages = val),
              ),
            ),
            const SizedBox(height: 32),
            // زر الحفظ بتصميم احترافي
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : () => _saveDelegate(context),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        "حفظ المندوب وصلاحياته",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDelegate(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // إدراج البيانات في جدول company_delegates في Supabase
      await _supabase.from('company_delegates').insert({
        'name': nameController.text.trim(),
        'email': emailController.text.trim().toLowerCase(),
        'company_id': widget.companyId,
        'can_add_properties': canAddProperties,
        'can_reply_to_messages': canReplyToMessages,
        // عمود created_at سيتم تعيينه تلقائياً في قاعدة البيانات إذا تم ضبط القيمة الافتراضية لـ now()
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم إضافة المندوب وصلاحياته بنجاح"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("خطأ أثناء حفظ المندوب: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("حدث خطأ أثناء الحفظ: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
