import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginMode = true; // للتبديل بين تسجيل الدخول وإنشاء حساب جديد
  bool _obscurePassword = true; // لإظهار/إخفاء كلمة المرور
  bool _isLoading = false; // مؤشر التحميل أثناء الاتصال بـ Supabase

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      if (_isLoginMode) {
        // 1. تسجيل الدخول عبر Supabase
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        _showSnackBar("تم تسجيل الدخول بنجاح", Colors.green);
      } else {
        // 2. إنشاء حساب جديد عبر Supabase Auth
        final AuthResponse response = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {
            'name': _nameController.text
                .trim(), // حفظ الاسم في الـ metadata للمستخدم
          },
        );

        // حفظ بيانات المستخدم الإضافية في جدول profiles متوافقة تماماً مع الـ UserModel
        if (response.user != null) {
          try {
            await supabase.from('profiles').upsert({
              'id': response.user!.id, // الـ UUID القادم من الـ Auth
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'user_type': 'user', // القيمة الافتراضية لنوع المستخدم
              'account_type':
                  'individual', // القيمة الافتراضية لنوع الحساب (فردي)
              'subscription_plan': 'free', // الباقة المجانية
              'ads_count': 0, // عدد الإعلانات البداية
              'is_verified_office': false, // ليس مكتب موثق افتراضياً
              'created_at': DateTime.now().toIso8601String(),
            });
          } catch (profileError) {
            debugPrint("ملاحظة بخصوص جدول profiles: $profileError");
          }
        }

        if (!mounted) return;
        _showSnackBar("تم إنشاء الحساب بنجاح", Colors.green);
      }

      // إعطاء فرصة قصيرة جداً لظهور الـ SnackBar بسلاسة قبل غلق الشاشة
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      // الرجوع الآمن للخلف (الـ ProfileScreen سيحدث نفسه بنفسه بفضل الـ Stream)
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      String errorMessage = "حدث خطأ ما، يجدر المحاولة لاحقاً";

      if (e.message.toLowerCase().contains('invalid login credentials') ||
          e.message.toLowerCase().contains('invalid email or password')) {
        errorMessage = "البريد الإلكتروني أو كلمة المرور غير صحيحة";
      } else if (e.message.toLowerCase().contains('already registered')) {
        errorMessage = "البريد الإلكتروني مستخدم بالفعل لحساب آخر";
      } else if (e.message.toLowerCase().contains('password')) {
        errorMessage = "كلمة المرور ضعيفة جداً أو غير مطابقة للمتطلبات";
      } else if (e.message.toLowerCase().contains('rate limit')) {
        errorMessage = "تم إرسال طلبات كثيرة في وقت قصير، يجدر الانتظار قليلاً";
      } else {
        errorMessage = e.message;
      }

      if (!mounted) return;
      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("خطأ: ${e.toString()}", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final TextEditingController resetEmailController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "استعادة كلمة المرور",
            style: TextStyle(
                color: Color(0xFF003366), fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.",
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "البريد الإلكتروني",
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.email_rounded, color: Color(0xFF003366)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  _showSnackBar("يرجى إدخال بريد إلكتروني صحيح", Colors.red);
                  return;
                }

                try {
                  Navigator.pop(context); // إغلاق النافذة المنسدلة
                  setState(() => _isLoading = true);

                  // إرسال طلب إعادة التعيين عبر Supabase
                  await Supabase.instance.client.auth
                      .resetPasswordForEmail(email);

                  if (!mounted) return;
                  _showSnackBar("تم إرسال رابط استعادة كلمة المرور إلى بريدك",
                      Colors.green);
                } catch (e) {
                  if (!mounted) return;
                  _showSnackBar("حدث خطأ: ${e.toString()}", Colors.red);
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text("إرسال", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
        backgroundColor: const Color(0xFF003366),
        title: Text(
          _isLoginMode ? "تسجيل الدخول - زهرة" : "إنشاء حساب جديد - زهرة",
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 4,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // شعار المنصة
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003366).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.real_estate_agent_rounded,
                        size: 48,
                        color: Color(0xFF003366),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "منصة زهرة العقارية",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // انتقال النصوص بسلاسة
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _isLoginMode
                            ? "مرحباً بك مجدداً، سجل دخولك للمتابعة"
                            : "أنشئ حسابك الجديد وابدأ عرض عقارك",
                        key: ValueKey<bool>(_isLoginMode),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // حقل الاسم (يظهر بسلاسة عند إنشاء حساب جديد)
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: "الاسم الكامل",
                            labelStyle: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                            prefixIcon: const Icon(Icons.person_rounded,
                                color: Color(0xFF003366)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF003366), width: 1.5),
                            ),
                          ),
                          validator: (value) {
                            if (!_isLoginMode &&
                                (value == null || value.isEmpty)) {
                              return "يرجى إدخال الاسم";
                            }
                            return null;
                          },
                        ),
                      ),
                      crossFadeState: _isLoginMode
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 300),
                    ),

                    // حقل البريد الإلكتروني
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "البريد الإلكتروني",
                        labelStyle:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: const Icon(Icons.email_rounded,
                            color: Color(0xFF003366)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
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
                          borderSide: const BorderSide(
                              color: Color(0xFF003366), width: 1.5),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty || !value.contains('@')
                              ? "يرجى إدخال بريد إلكتروني صحيح"
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // حقل كلمة المرور
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "كلمة المرور",
                        labelStyle:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_rounded,
                            color: Color(0xFF003366)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
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
                          borderSide: const BorderSide(
                              color: Color(0xFF003366), width: 1.5),
                        ),
                      ),
                      validator: (value) => value!.length < 6
                          ? "كلمة المرور يجب أن تكون 6 أحرف على الأقل"
                          : null,
                    ),

                    // زر "هل نسيت كلمة المرور؟"
                    if (_isLoginMode) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => _showForgotPasswordDialog(context),
                          child: const Text(
                            "هل نسيت كلمة المرور؟",
                            style: TextStyle(
                              color: Color(0xFF003366),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // زر التنفيذ الأساسي
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                _isLoginMode ? "تسجيل الدخول" : "إنشاء الحساب",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // زر التبديل بين الدخول والتسجيل
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLoginMode = !_isLoginMode;
                              });
                            },
                      child: Text(
                        _isLoginMode
                            ? "ليس لديك حساب؟ سجل الآن"
                            : "لديك حساب بالفعل؟ سجل دخولك",
                        style: const TextStyle(
                            color: Color(0xFF003366),
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
