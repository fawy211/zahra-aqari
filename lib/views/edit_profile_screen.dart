import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _companyNameController;

  bool _isLoading = false;
  File? _selectedImageFile; // لتخزين الصورة المحلية المختارة
  String? _currentAvatarUrl; // رابط الصورة الحالي من قاعدة البيانات

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.userData['name'] ?? widget.userData['fullName'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userData['phone'] ?? widget.userData['phoneNumber'] ?? '',
    );
    _companyNameController = TextEditingController(
      text: widget.userData['company_name'] ??
          widget.userData['companyName'] ??
          '',
    );
    // جلب رابط الصورة الشخصية القديمة إن وجد
    _currentAvatarUrl =
        widget.userData['avatar_url'] ?? widget.userData['image'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  // دالة اختيار الصورة من المعرض
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // ضغط بسيط للجودة لتسريع الرفع
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("خطأ في اختيار الصورة: $e");
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    final SupabaseClient supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      setState(() => _isLoading = true);
      try {
        String? uploadedAvatarUrl = _currentAvatarUrl;

        // إذا قام المستخدم باختيار صورة جديدة، نقوم برفعها لـ Supabase Storage أولاً
        if (_selectedImageFile != null) {
          final fileName =
              'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storagePath = 'avatars/$fileName';

          // رفع الملف إلى Bucket مخصص ولنفترض اسمه 'profiles_bucket' (يمكنك تغييره حسب اسم البكت لديك)
          await supabase.storage
              .from('profiles_bucket')
              .upload(storagePath, _selectedImageFile!);

          // الحصول على الرابط العام للصورة المرفوعة
          uploadedAvatarUrl = supabase.storage
              .from('profiles_bucket')
              .getPublicUrl(storagePath);
        }

        final Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          if (uploadedAvatarUrl != null) 'avatar_url': uploadedAvatarUrl,
        };

        if (_companyNameController.text.trim().isNotEmpty) {
          updateData['company_name'] = _companyNameController.text.trim();
        }

        await supabase.from('profiles').update(updateData).eq('id', user.id);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم التحديث بنجاح"),
            backgroundColor: Color(0xFF003366),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true); // إرجاع true لتحديث الشاشة السابقة
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("فشل الحفظ: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userType = widget.userData['user_type'] ?? '';
    final bool isCompany = userType == 'company' ||
        userType == 'office' ||
        (widget.userData['company_name'] != null &&
            widget.userData['company_name'].toString().isNotEmpty) ||
        (widget.userData['companyName'] != null &&
            widget.userData['companyName'].toString().isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "تعديل الملف الشخصي",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // تصميم قسم صورة البروفايل الشخصي
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _selectedImageFile != null
                        ? FileImage(_selectedImageFile!) as ImageProvider
                        : (_currentAvatarUrl != null &&
                                _currentAvatarUrl!.isNotEmpty
                            ? NetworkImage(_currentAvatarUrl!) as ImageProvider
                            : null),
                    child: (_selectedImageFile == null &&
                            (_currentAvatarUrl == null ||
                                _currentAvatarUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF003366),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "اضغط على أيقونة الكاميرا لتغيير صورة الملف الشخصي (اختياري)",
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nameController,
              label: "الاسم الكامل",
              icon: Icons.person_outline_rounded,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'لا يمكن ترك الاسم فارغاً'
                  : null,
            ),
            if (isCompany) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _companyNameController,
                label: "اسم الشركة / المكتب العقاري",
                icon: Icons.business_outlined,
              ),
            ],
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: "رقم الهاتف",
              icon: Icons.phone_outlined,
              type: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _saveData,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "حفظ التغييرات",
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
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
      validator: validator,
    );
  }
}
