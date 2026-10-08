import 'package:aqari_app/features/property/config/app_config.dart';
import 'package:aqari_app/features/property/providers/property_provider.dart';
import 'package:aqari_app/models/property_models.dart';
import 'package:aqari_app/utils/constants_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();

  String? _selectedGov;
  String? _selectedMainCategory;
  String? _selectedType;
  String? _selectedFinishing;
  String? _selectedRooms;
  String? _selectedAgriculturalActivity;
  String? _selectedSoilType;
  String? _selectedIrrigationSystem;

  final List<String> _selectedFloors = [];
  final List<String> _selectedUtilities = [];
  final List<String> _selectedAmenties = [];

  String? _advertiserType;
  String? _isNegotiable;
  String? _contactMethod;
  String? _isFeatured;

  final List<XFile> _selectedImages = [];
  XFile? _selectedVideo;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> _roomsOptions = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '+10'
  ];

  final Map<String, String> _floorsMap = {
    'ground': 'الأرضي',
    'basement': 'البدروم',
    'mezzanine': 'الميزانين',
    '1': 'الدور الأول',
    '2': 'الدور الثاني',
    '3': 'الدور الثالث',
    '4': 'الدور الرابع',
    '5': 'الدور الخامس',
    '6': 'الدور السادس',
    '7': 'الدور السابع',
    '8': 'الدور الثامن',
    '9': 'الدور التاسع',
    '10': 'الدور العاشر',
    'roof': 'الروف / الأخير',
  };

  final Map<String, String> _utilitiesMap = {
    'electricity': 'عداد كهرباء',
    'water': 'عداد مياه',
    'gas': 'عداد غاز',
    'phone': 'خط تليفون أرضى',
  };

  final Map<String, String> _amentiesMap = {
    'elevator': 'اسانسير',
    'garage': 'جراج',
    'balcony': 'شرفة',
    'security': 'امن',
    'garden': 'حديقة خاصة',
    'heating': 'تدفئة',
    'ac': 'تكييف',
    'central_ac': 'تكييف مركزى',
  };

  InputDecoration _customInputDecoration({
    required String labelText,
    String? suffixText,
    TextStyle? suffixStyle,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      suffixText: suffixText,
      suffixStyle: suffixStyle,
      prefixIcon: prefixIcon,
      border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 1.5)),
      enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black54, width: 1.2)),
      focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2.0)),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  bool get _isLandProperty =>
      _selectedType != null &&
      (_selectedType!.contains('أرض') || _selectedType!.contains('زرع'));

  bool get _isResidential =>
      _selectedMainCategory == 'residential' ||
      (_selectedMainCategory != null &&
          _selectedMainCategory!.toLowerCase().contains('سكني'));

  bool get _isAgriculturalLand {
    bool isMainAgricultural = _selectedMainCategory == 'agricultural' ||
        (_selectedMainCategory != null &&
            (_selectedMainCategory!.toLowerCase().contains('زراعى') ||
                _selectedMainCategory!.toLowerCase().contains('زراعي')));

    bool isSubAgriculturalType = _selectedType != null &&
        (_selectedType!.contains('أراضي زراعية') ||
            _selectedType!.contains('ارض زراعية') ||
            _selectedType!.contains('أراضى زراعية'));

    return isMainAgricultural && isSubAgriculturalType;
  }

  bool _isFieldEnabled(String fieldKey) {
    if (_selectedMainCategory == null || _selectedType == null) return false;
    try {
      final categoryInfo = AppConfig.categories[_selectedType];
      if (categoryInfo == null) return false;
      final fields = categoryInfo['fields'] as List<dynamic>?;
      return fields != null && fields.contains(fieldKey);
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty && mounted) {
        setState(() => _selectedImages.addAll(pickedFiles));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ في اختيار الصور: $e")));
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile =
          await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() => _selectedVideo = pickedFile);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ في اختيار الفيديو: $e")));
    }
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final finishingValue =
          _isLandProperty ? 'لا تطبق' : (_selectedFinishing ?? '');

      final List<String> imagePaths =
          _selectedImages.map((img) => img.path).toList();

      final String videoPath = _selectedVideo?.path ?? '';

      final String mainCategoryName = (_selectedMainCategory != null &&
              AppConfig.mainCategories.containsKey(_selectedMainCategory))
          ? AppConfig.mainCategories[_selectedMainCategory]!
          : (_selectedMainCategory ?? '');

      final double priceVal =
          double.tryParse(_priceController.text.trim()) ?? 0.0;
      final double areaVal =
          double.tryParse(_areaController.text.trim()) ?? 0.0;

      final String govKey = _selectedGov ?? '';
      final String govVal = ConstantsData.governorates[govKey] ?? govKey;

      final String cityVal = _cityController.text.trim();
      final String typeVal = _selectedType ?? '';

      final Map<String, dynamic> metadataMap = {
        'governorate': govVal,
        'المحافظة': govVal,
        'city': cityVal,
        'المدينة': cityVal,
        'street': _streetController.text.trim(),
        'الشارع': _streetController.text.trim(),
        'property_type': typeVal,
        'نوع العقار': typeVal,
        'finishing': finishingValue,
        'التشطيب': finishingValue,
        'area': areaVal,
        'المساحة': areaVal,
        'price': priceVal,
        'السعر': priceVal,
        'advertiser_type': _advertiserType ?? '',
        'صفة المعلن': _advertiserType ?? '',
        'is_negotiable': _isNegotiable ?? 'لا',
        'قابل للتفاوض': _isNegotiable ?? 'لا',
        'contact_method': _contactMethod ?? '',
        'طريقة التواصل': _contactMethod ?? '',
        'phone': _phoneController.text.trim(),
        'رقم الهاتف': _phoneController.text.trim(),
        if (_selectedRooms != null) ...{
          'rooms': _selectedRooms,
          'عدد الغرف': _selectedRooms,
        },
        if (_selectedFloors.isNotEmpty) ...{
          'floors': _selectedFloors,
          'الطوابق': _selectedFloors,
        },
        if (_selectedUtilities.isNotEmpty) ...{
          'utilities': _selectedUtilities,
          'المرافق': _selectedUtilities,
        },
        if (_selectedAmenties.isNotEmpty) ...{
          'amenties': _selectedAmenties,
          'الكماليات': _selectedAmenties,
        },
        if (_isAgriculturalLand) ...{
          'agricultural_activity': _selectedAgriculturalActivity ?? '',
          'النشاط الزراعي': _selectedAgriculturalActivity ?? '',
          'soil_type': _selectedSoilType ?? '',
          'نوع التربة': _selectedSoilType ?? '',
          'irrigation_system': _selectedIrrigationSystem ?? '',
          'نظام الري': _selectedIrrigationSystem ?? '',
        }
      };

      final propertyData = {
        'title': _titleController.text.trim().isEmpty
            ? 'عقار جديد'
            : _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': mainCategoryName,
        'type': typeVal,
        'code': _selectedType != null ? AppConfig.getCode(_selectedType!) : '',
        'finishing': finishingValue,
        'price': priceVal,
        'area': areaVal,
        'rooms': (_isResidential || _isFieldEnabled('rooms'))
            ? (_selectedRooms ?? '')
            : '',
        'floor': (_isResidential || _isFieldEnabled('floor'))
            ? List<String>.from(_selectedFloors)
            : <String>[],
        'utilities': (_isResidential || _isFieldEnabled('utilities'))
            ? List<String>.from(_selectedUtilities)
            : <String>[],
        'amenties': (_isResidential || _isFieldEnabled('amenties'))
            ? List<String>.from(_selectedAmenties)
            : <String>[],
        'agricultural_activity':
            _isAgriculturalLand ? (_selectedAgriculturalActivity ?? '') : '',
        'soil_type': _isAgriculturalLand ? (_selectedSoilType ?? '') : '',
        'irrigation_system':
            _isAgriculturalLand ? (_selectedIrrigationSystem ?? '') : '',
        'gov': govVal,
        'city': cityVal,
        'street': _streetController.text.trim(),
        'advertiser_type': _advertiserType ?? '',
        'is_negotiable': _isNegotiable == 'نعم',
        'contact_method': _contactMethod ?? '',
        'phone': _phoneController.text.trim(),
        'is_featured': _isFeatured == 'نعم',
        'images': imagePaths,
        'video': videoPath,
        'metadata': metadataMap,
      };

      const String defaultOwnerId = 'guest_advertiser';
      final newProperty =
          PropertyModel.fromPropertyData(propertyData, defaultOwnerId);

      if (!mounted) return;

      final bool success = await ref
          .read(propertyProvider.notifier)
          .addProperty(newProperty, imagePaths);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم النشر بنجاح على Supabase!")));
        Navigator.pop(context);
      } else {
        _showErrorDialog(
            "فشل في إتمام عملية الحفظ أو الرفع للسيرفر. يرجى التحقق من اتصال الإنترنت أو قيود الجدول.");
      }
    } catch (e, stackTrace) {
      debugPrint("========== خطأ في إرسال العقار ==========");
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      debugPrint("========================================");

      if (!mounted) return;
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String errorDetails) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('تفاصيل الخطأ الدقيق', textDirection: TextDirection.rtl),
        content: SingleChildScrollView(
          child: Text(
            errorDetails,
            style: const TextStyle(color: Colors.red, fontSize: 13),
            textDirection: TextDirection.ltr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showMultiSelectDialog({
    required String title,
    required Map<String, String> itemsMap,
    required List<String> selectedList,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: ListBody(
                  children: itemsMap.entries.map((entry) {
                    bool isSelected = selectedList.contains(entry.key);

                    return CheckboxListTile(
                      title: Text(entry.value),
                      value: isSelected,
                      onChanged: (bool? checked) {
                        setStateDialog(() {
                          if (checked == true) {
                            selectedList.add(entry.key);
                          } else {
                            selectedList.remove(entry.key);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                    child: const Text('تم'),
                    onPressed: () => Navigator.of(context).pop())
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableSubTypes = _selectedMainCategory != null
        ? AppConfig.categorySubTypes[_selectedMainCategory] ?? []
        : [];

    final String areaUnit =
        (_selectedType != null && _selectedType!.contains('زراعية'))
            ? 'فدان'
            : 'م²';

    return Scaffold(
      appBar:
          AppBar(title: const Text("إضافة عقار (Supabase)"), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          "تنبيه هام: لا يجوز تكرار نشر نفس الإعلان خلال مدة 90 يوماً.",
                          style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13))),
                ],
              ),
            ),
            TextFormField(
                controller: _titleController,
                decoration: _customInputDecoration(labelText: "عنوان الإعلان"),
                validator: (val) => val == null || val.isEmpty
                    ? 'يرجى إدخال عنوان الإعلان'
                    : null),
            const SizedBox(height: 16),
            TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration:
                    _customInputDecoration(labelText: "وصف وتفاصيل العقار"),
                validator: (val) => val == null || val.isEmpty
                    ? 'يرجى إدخال وصف العقار'
                    : null),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("وسائط العقار (صور وفيديو)",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: _pickImages,
                                icon: const Icon(Icons.image),
                                label: Text(
                                    "إضافة صور (${_selectedImages.length})"))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: _pickVideo,
                                icon: const Icon(Icons.video_library),
                                label: Text(_selectedVideo == null
                                    ? "إضافة فيديو"
                                    : "تم اختيار الفيديو"))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGov,
              decoration: _customInputDecoration(labelText: "المحافظة"),
              items: ConstantsData.governorates.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedGov = val),
              validator: (val) => val == null ? 'يرجى اختيار المحافظة' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
                controller: _cityController,
                decoration: _customInputDecoration(labelText: "المدينة / الحي"),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'يرجى إدخال المدينة أو الحي'
                    : null),
            const SizedBox(height: 16),
            TextFormField(
                controller: _streetController,
                decoration: _customInputDecoration(labelText: "اسم الشارع"),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'يرجى إدخال اسم الشارع'
                    : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMainCategory,
              decoration: _customInputDecoration(labelText: "التصنيف الرئيسي"),
              items: AppConfig.mainCategories.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedMainCategory = val;
                  _selectedType = null;
                  _selectedFinishing = null;
                  _selectedRooms = null;
                  _selectedAgriculturalActivity = null;
                  _selectedSoilType = null;
                  _selectedIrrigationSystem = null;
                  _selectedFloors.clear();
                  _selectedUtilities.clear();
                  _selectedAmenties.clear();
                });
              },
              validator: (val) =>
                  val == null ? 'يرجى اختيار التصنيف الرئيسي' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration:
                  _customInputDecoration(labelText: "نوع العقار الفرعي"),
              items: availableSubTypes
                  .map((typeName) => DropdownMenuItem<String>(
                      value: typeName, child: Text(typeName)))
                  .toList(),
              onChanged: _selectedMainCategory == null
                  ? null
                  : (val) => setState(() {
                        _selectedType = val;
                        if (_isLandProperty) _selectedFinishing = null;
                        if (!_isAgriculturalLand) {
                          _selectedAgriculturalActivity = null;
                          _selectedSoilType = null;
                          _selectedIrrigationSystem = null;
                        }
                      }),
              validator: (val) => val == null ? 'يرجى اختيار نوع العقار' : null,
            ),
            const SizedBox(height: 16),
            if (!_isLandProperty &&
                (_isResidential || _isFieldEnabled('finishing'))) ...[
              DropdownButtonFormField<String>(
                value: _selectedFinishing,
                decoration: _customInputDecoration(labelText: "مستوى التشطيب"),
                items: const [
                  DropdownMenuItem(
                      value: 'super_lux', child: Text('سوبر لوكس')),
                  DropdownMenuItem(value: 'lux', child: Text('لوكس')),
                  DropdownMenuItem(
                      value: 'semi_finished', child: Text('نصف تشطيب')),
                  DropdownMenuItem(
                      value: 'core_shell', child: Text('على المحارة')),
                ],
                onChanged: (val) => setState(() => _selectedFinishing = val),
                validator: (val) =>
                    val == null ? 'يرجى اختيار مستوى التشطيب' : null,
              ),
              const SizedBox(height: 16),
            ],
            if (_isAgriculturalLand) ...[
              DropdownButtonFormField<String>(
                value: _selectedAgriculturalActivity,
                decoration: _customInputDecoration(labelText: "النشاط"),
                items: const [
                  DropdownMenuItem(value: 'مزروعة', child: Text('مزروعة')),
                  DropdownMenuItem(
                      value: 'غير مزروعة', child: Text('غير مزروعة')),
                ],
                onChanged: (val) =>
                    setState(() => _selectedAgriculturalActivity = val),
                validator: (val) => val == null ? 'يرجى تحديد النشاط' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSoilType,
                decoration: _customInputDecoration(labelText: "نوع التربة"),
                items: const [
                  DropdownMenuItem(value: 'طينية', child: Text('طينية')),
                  DropdownMenuItem(value: 'رملية', child: Text('رملية')),
                  DropdownMenuItem(value: 'جيرية', child: Text('جيرية')),
                  DropdownMenuItem(value: 'اخرى', child: Text('أخرى')),
                ],
                onChanged: (val) => setState(() => _selectedSoilType = val),
                validator: (val) =>
                    val == null ? 'يرجى تحديد نوع التربة' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedIrrigationSystem,
                decoration: _customInputDecoration(labelText: "نظام الري"),
                items: const [
                  DropdownMenuItem(value: 'نيلي', child: Text('نيلي')),
                  DropdownMenuItem(value: 'ابار', child: Text('آبار')),
                  DropdownMenuItem(value: 'اخرى', child: Text('أخرى')),
                ],
                onChanged: (val) =>
                    setState(() => _selectedIrrigationSystem = val),
                validator: (val) => val == null ? 'يرجى تحديد نظام الري' : null,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _customInputDecoration(
                labelText: "السعر",
                suffixText: "ج.م",
                suffixStyle: TextStyle(
                    color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'يرجى إدخال السعر' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _isNegotiable,
              decoration: _customInputDecoration(labelText: "قابل للتفاوض"),
              items: const [
                DropdownMenuItem(value: 'نعم', child: Text('نعم')),
                DropdownMenuItem(value: 'لا', child: Text('لا')),
              ],
              onChanged: (val) => setState(() => _isNegotiable = val),
              validator: (val) =>
                  val == null ? 'يرجى تحديد حالة التفاوض' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _areaController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _customInputDecoration(
                labelText: "المساحة",
                suffixText: areaUnit,
                suffixStyle: TextStyle(
                    color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'يرجى إدخال المساحة' : null,
            ),
            const SizedBox(height: 16),
            if (_isResidential || _isFieldEnabled('rooms')) ...[
              DropdownButtonFormField<String>(
                value: _selectedRooms,
                decoration: _customInputDecoration(labelText: "عدد الغرف"),
                items: _roomsOptions
                    .map((room) =>
                        DropdownMenuItem(value: room, child: Text(room)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedRooms = val),
              ),
              const SizedBox(height: 16),
            ],
            if (_isResidential || _isFieldEnabled('floor')) ...[
              InkWell(
                onTap: () => _showMultiSelectDialog(
                    title: 'اختر الطابق',
                    itemsMap: _floorsMap,
                    selectedList: _selectedFloors),
                child: InputDecorator(
                  decoration: _customInputDecoration(labelText: "الطابق"),
                  child: Text(
                    _selectedFloors.isEmpty
                        ? "اختر الطابق..."
                        : _selectedFloors
                            .map((key) => _floorsMap[key])
                            .join(', '),
                    style: TextStyle(
                        color: _selectedFloors.isEmpty
                            ? Colors.grey.shade600
                            : Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_isResidential || _isFieldEnabled('utilities')) ...[
              InkWell(
                onTap: () => _showMultiSelectDialog(
                    title: 'اختر المرافق العامة',
                    itemsMap: _utilitiesMap,
                    selectedList: _selectedUtilities),
                child: InputDecorator(
                  decoration:
                      _customInputDecoration(labelText: "المرافق العامة"),
                  child: Text(
                    _selectedUtilities.isEmpty
                        ? "اختر المرافق العامة..."
                        : _selectedUtilities
                            .map((key) => _utilitiesMap[key])
                            .join(', '),
                    style: TextStyle(
                        color: _selectedUtilities.isEmpty
                            ? Colors.grey.shade600
                            : Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_isResidential || _isFieldEnabled('amenties')) ...[
              InkWell(
                onTap: () => _showMultiSelectDialog(
                    title: 'اختر الكماليات',
                    itemsMap: _amentiesMap,
                    selectedList: _selectedAmenties),
                child: InputDecorator(
                  decoration: _customInputDecoration(labelText: "الكماليات"),
                  child: Text(
                    _selectedAmenties.isEmpty
                        ? "اختر الكماليات..."
                        : _selectedAmenties
                            .map((key) => _amentiesMap[key])
                            .join(', '),
                    style: TextStyle(
                        color: _selectedAmenties.isEmpty
                            ? Colors.grey.shade600
                            : Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<String>(
              value: _advertiserType,
              decoration: _customInputDecoration(labelText: "صفة المعلن"),
              items: const [
                DropdownMenuItem(value: 'مالك', child: Text('مالك')),
                DropdownMenuItem(value: 'وسيط', child: Text('وسيط (سمسار)')),
                DropdownMenuItem(value: 'شركة', child: Text('شركة عقارية')),
              ],
              onChanged: (val) => setState(() => _advertiserType = val),
              validator: (val) => val == null ? 'يرجى تحديد صفة المعلن' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _contactMethod,
              decoration:
                  _customInputDecoration(labelText: "طريقة التواصل المفضلة"),
              items: const [
                DropdownMenuItem(value: 'whatsapp', child: Text('واتساب')),
                DropdownMenuItem(value: 'call', child: Text('مكالمات')),
                DropdownMenuItem(value: 'chat', child: Text('شات')),
                DropdownMenuItem(value: 'all', child: Text('الكل')),
              ],
              onChanged: (val) => setState(() => _contactMethod = val),
              validator: (val) =>
                  val == null ? 'يرجى تحديد طريقة التواصل' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _customInputDecoration(labelText: "رقم الهاتف"),
              validator: (val) {
                if (val == null || val.isEmpty) return 'يرجى إدخال رقم الهاتف';
                if (!RegExp(r'^01[0125][0-9]{8}$').hasMatch(val)) {
                  return 'يرجى إدخال رقم هاتف مصري صحيح (11 رقماً)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitProperty,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "نشر الإعلان",
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
}
