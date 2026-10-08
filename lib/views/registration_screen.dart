import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _nameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'individual';

  @override
  void dispose() {
    _nameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. إنشاء الحساب باستخدام Supabase Auth
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          if (_selectedRole != 'individual')
            'company_name': _companyNameController.text.trim(),
        },
      );

      final user = res.user;

      if (user != null) {
        // 2. حفظ بيانات الحساب في جدول profiles الموحد.
        // هذه هي الأعمدة الموجودة في مخطط Supabase الحالي؛ أما بيانات
        // الشركة والهاتف فتظل في Auth metadata إلى أن نثبت أعمدتها في قاعدة
        // البيانات، حتى لا ينجح إنشاء Auth ثم يفشل إدخال الملف الشخصي.
        await supabase.from('profiles').upsert({
          'id': user.id,
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'user_type': _selectedRole,
          'account_type': _selectedRole,
          'subscription_plan': 'free',
          'ads_count': 0,
          'is_verified_office': false,
          'created_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          _showSnackBar("تم إنشاء الحساب بنجاح", Colors.green);
          Navigator.pop(context);
        }
      }
    } on AuthException catch (e) {
      String errorMessage = "حدث خطأ أثناء إنشاء الحساب";
      if (e.message.contains('already registered') ||
          e.message.contains('User already registered')) {
        errorMessage = "البريد الإلكتروني مستخدم بالفعل لحساب آخر";
      } else if (e.message.contains('Password should be')) {
        errorMessage = "كلمة المرور ضعيفة جداً";
      } else {
        errorMessage = e.message;
      }
      _showSnackBar(errorMessage, Colors.red.shade700);
    } catch (e) {
      _showSnackBar("خطأ: ${e.toString()}", Colors.red.shade700);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "إنشاء حساب جديد",
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "أهلاً بك في زهرة العقاري",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "قم بإنشاء حسابك لاستكشاف العقارات والتواصل مع الملاك",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // نوع الحساب
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: "نوع الحساب",
                  labelStyle: const TextStyle(color: Color(0xFF003366)),
                  prefixIcon:
                      const Icon(Icons.badge_rounded, color: Color(0xFF003366)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF003366), width: 1.5),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'individual',
                    child: Text('مستخدم فرد'),
                  ),
                  DropdownMenuItem(
                    value: 'office',
                    child: Text('مكتب عقاري'),
                  ),
                  DropdownMenuItem(
                    value: 'company',
                    child: Text('شركة عقارية'),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 16),

              // الاسم الكامل
              _buildTextField(
                controller: _nameController,
                label: "الاسم الكامل",
                icon: Icons.person_rounded,
                validator: (v) =>
                    v == null || v.isEmpty ? 'يرجى إدخال الاسم الكامل' : null,
              ),

              // حقل اسم الشركة/المكتب يظهر بسلاسة عند اختيار حساب تجاري
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: _buildTextField(
                    controller: _companyNameController,
                    label: "اسم الشركة/المكتب",
                    icon: Icons.business_rounded,
                    validator: (v) {
                      if (_selectedRole != 'individual' &&
                          (v == null || v.isEmpty)) {
                        return 'يرجى إدخال اسم الشركة أو المكتب';
                      }
                      return null;
                    },
                  ),
                ),
                crossFadeState: _selectedRole == 'individual'
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 300),
              ),

              // البريد الإلكتروني
              _buildTextField(
                controller: _emailController,
                label: "البريد الإلكتروني",
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty || !v.contains('@')) {
                    return 'يرجى إدخال بريد إلكتروني صحيح';
                  }
                  return null;
                },
              ),

              // رقم الهاتف
              _buildTextField(
                controller: _phoneController,
                label: "رقم الهاتف",
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty || v.length < 10) {
                    return 'يرجى إدخال رقم هاتف صحيح';
                  }
                  return null;
                },
              ),

              // كلمة المرور مع زر إظهار/إخفاء
              _buildTextField(
                controller: _passwordController,
                label: "كلمة المرور",
                icon: Icons.lock_rounded,
                obscure: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // زر التسجيل
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _register,
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
                          "تسجيل الحساب",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          prefixIcon: Icon(icon, color: const Color(0xFF003366)),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF003366), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
        ),
        validator: validator ??
            (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }
}
