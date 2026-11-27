import 'package:flutter/material.dart';
import '../services/property_service.dart';
// استيراد مودل البيانات الأساسي الشامل الخاص بك
// (تأكد من تعديل مسار الاستيراد ليطابق ملف الـ PropertyModel الأساسي في مشروعك)
import 'package:aqari_app/models/property_models.dart';

class EditPropertyScreen extends StatefulWidget {
  final PropertyModel property;

  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _finishingController;
  late TextEditingController _floorController;
  late TextEditingController _roomsController;

  final PropertyService _propertyService = PropertyService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.property.title);
    _priceController =
        TextEditingController(text: widget.property.price.toString());

    // جلب القيم بشكل آمن سواء كانت مخزنة في الحقول المباشرة أو داخل الـ metadata لمنع التكرار والخلط
    _finishingController = TextEditingController(
        text: widget.property.finishing.isNotEmpty
            ? widget.property.finishing
            : (widget.property.metadata['finishing']?.toString() ?? ''));

    final floorValue = widget.property.metadata['floor'] ??
        widget.property.metadata['floors'];
    _floorController = TextEditingController(
      text: floorValue is List
          ? floorValue.map((value) => value.toString()).join(', ')
          : (floorValue?.toString() ?? ''),
    );

    _roomsController = TextEditingController(
        text: widget.property.metadata['rooms']?.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _finishingController.dispose();
    _floorController.dispose();
    _roomsController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final propertyId = widget.property.id;
    if (propertyId == null || propertyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("خطأ: معرف العقار غير متوفر"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. تحديث الـ metadata بحرص لتجنب التكرار ودمج القيم الجديدة مع القديمة نظيفة
      final updatedMetadata =
          Map<String, dynamic>.from(widget.property.metadata);
      final floorValue = _floorController.text.trim();
      final roomsValue = _roomsController.text.trim();
      final finishingValue = _finishingController.text.trim();
      // الإصدارات السابقة كانت تحفظ الطوابق بصيغة floors كقائمة.
      // نعتمد floor كمفتاح موحد بعد التعديل حتى لا تظهر قيم قديمة متعارضة.
      updatedMetadata.remove('floors');
      updatedMetadata.remove('الطوابق');
      updatedMetadata['floor'] = floorValue;
      updatedMetadata['rooms'] = roomsValue;
      updatedMetadata['finishing'] = finishingValue;

      // 2. بناء كائن المودل المحدث باستخدام دالة copyWith الموجودة في المودل الأساسي
      final parsedPrice = double.parse(_priceController.text.trim());
      final updatedModel = widget.property.copyWith(
        title: _titleController.text.trim(),
        price: parsedPrice,
        finishing: finishingValue,
        metadata: updatedMetadata,
      );

      // تحديث الأعمدة المباشرة والـ metadata معاً حتى لا تظهر قيم قديمة
      // لأن PropertyModel يقرأ بعض الحقول المباشرة قبل قيم metadata.
      await _propertyService.updateProperty(propertyId, {
        'title': updatedModel.title,
        'price': updatedModel.price,
        'finishing': updatedModel.finishing,
        'metadata': updatedMetadata,
        'floor': floorValue,
        'rooms': roomsValue,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم تحديث الإعلان بنجاح"),
            backgroundColor: Color(0xFF003366),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, updatedModel);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("فشل التحديث: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "تعديل الإعلان",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF003366),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "قم بتعديل بيانات الإعلان لتظهر للمستخدمين بشكل دقيق",
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration:
                    _inputDecoration("عنوان العقار", Icons.title_rounded),
                validator: (value) => value == null || value.trim().isEmpty
                    ? "يرجى إدخال العنوان"
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration:
                    _inputDecoration("السعر", Icons.attach_money_rounded),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || !parsed.isFinite || parsed <= 0) {
                    return "أدخل سعراً رقمياً أكبر من صفر";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _finishingController,
                decoration: _inputDecoration(
                    "التشطيب (مثال: سوبر لوكس)", Icons.check_circle_outline),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _floorController,
                decoration: _inputDecoration("الدور", Icons.layers_rounded),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomsController,
                keyboardType: TextInputType.number,
                decoration:
                    _inputDecoration("عدد الغرف", Icons.meeting_room_rounded),
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
                  onPressed: _isLoading ? null : _saveChanges,
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
                          "حفظ التعديلات",
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
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
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
    );
  }
}
