import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyRegistrationScreen extends StatefulWidget {
  const CompanyRegistrationScreen({super.key});

  @override
  State<CompanyRegistrationScreen> createState() =>
      _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState extends State<CompanyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _crController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _selectedField;

  final List<String> _fields = [
    'تطوير عقاري',
    'تسويق ووساطة عقارية',
    'إدارة ممتلكات',
    'مقاولات بناء',
    'استشارات هندسية',
    'أخرى'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _crController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedField == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى اختيار مجال العمل"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final SupabaseClient supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("المستخدم غير مسجل الدخول");

      // حفظ طلب التوثيق في جدول companies في Supabase
      await supabase.from('companies').insert({
        'ownerId': user.id,
        'companyName': _nameController.text.trim(),
        'crNumber': _crController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'field': _selectedField,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // تحديث بيانات المستخدم الأساسية في جدول users لربطها بالاسم والدور مبدئياً
      await supabase.from('users').upsert({
        'id': user.id,
        'companyName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'company', // تعيين الدور كشركة قيد المراجعة
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم إرسال طلب التوثيق بنجاح!"),
            backgroundColor: Color(0xFF003366),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ أثناء الإرسال: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        title: const Text(
          "تسجيل شركة عقارية جديدة",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "أدخل بيانات شركتك للتوثيق في منصة زهرة",
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            _buildTextField(_nameController, "اسم الشركة", Icons.business),
            _buildTextField(_crController, "رقم السجل التجاري", Icons.badge),
            _buildTextField(_phoneController, "رقم الهاتف", Icons.phone,
                TextInputType.phone),
            _buildTextField(_emailController, "البريد الإلكتروني", Icons.email,
                TextInputType.emailAddress),

            // حقل Dropdown بتصميم احترافي متناسق
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "مجال العمل",
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.category, color: Color(0xFF003366)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF003366), width: 1.5),
                  ),
                ),
                value: _selectedField,
                items: _fields
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedField = val),
              ),
            ),

            const SizedBox(height: 24),

            // زر الإرسال بتصميم فاخر
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _submitRequest,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        "إرسال طلب التوثيق",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      [TextInputType type = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF003366)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF003366), width: 1.5),
          ),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }
}
