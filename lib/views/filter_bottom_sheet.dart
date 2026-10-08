import 'package:flutter/material.dart';
import 'package:aqari_app/utils/constants_data.dart';
import 'package:aqari_app/features/property/config/app_config.dart';

class PropertyFilterBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic> filters) onApplyFilters;
  final Map<String, dynamic> initialFilters;

  const PropertyFilterBottomSheet({
    super.key,
    required this.onApplyFilters,
    required this.initialFilters,
  });

  @override
  State<PropertyFilterBottomSheet> createState() =>
      _PropertyFilterBottomSheetState();
}

class _PropertyFilterBottomSheetState extends State<PropertyFilterBottomSheet> {
  String? _selectedGov;
  String? _selectedMainCategory;
  String? _selectedType;
  String? _selectedFinishing;
  String? _advertiserType;
  String? _isNegotiable;
  final TextEditingController _cityController = TextEditingController();

  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _minAreaController = TextEditingController();
  final TextEditingController _maxAreaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedGov = _normalizeGovernorate(widget.initialFilters['gov']);
    _selectedMainCategory =
        _normalizeCategory(widget.initialFilters['category'] ??
            widget.initialFilters['categoryCode']);
    _selectedType = widget.initialFilters['type']?.toString();
    _selectedFinishing = _normalizeFinishing(widget.initialFilters['finishing']);
    _advertiserType = _normalizeAdvertiser(widget.initialFilters['advertiser_type']);
    _isNegotiable = _normalizeYesNo(widget.initialFilters['is_negotiable']);

    _cityController.text = widget.initialFilters['city']?.toString() ?? '';
    _minPriceController.text =
        widget.initialFilters['min_price']?.toString() ?? '';
    _maxPriceController.text =
        widget.initialFilters['max_price']?.toString() ?? '';
    _minAreaController.text =
        widget.initialFilters['min_area']?.toString() ?? '';
    _maxAreaController.text =
        widget.initialFilters['max_area']?.toString() ?? '';
  }

  @override
  void dispose() {
    _cityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minAreaController.dispose();
    _maxAreaController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedGov = null;
      _selectedMainCategory = null;
      _selectedType = null;
      _selectedFinishing = null;
      _advertiserType = null;
      _isNegotiable = null;
      _cityController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _minAreaController.clear();
      _maxAreaController.clear();
    });
  }

  void _apply() {
    final minPriceText = _minPriceController.text.trim();
    final maxPriceText = _maxPriceController.text.trim();
    final minAreaText = _minAreaController.text.trim();
    final maxAreaText = _maxAreaController.text.trim();
    final minPrice = _parseNumber(minPriceText);
    final maxPrice = _parseNumber(maxPriceText);
    final minArea = _parseNumber(minAreaText);
    final maxArea = _parseNumber(maxAreaText);

    if ((minPriceText.isNotEmpty && minPrice == null) ||
        (maxPriceText.isNotEmpty && maxPrice == null) ||
        (minAreaText.isNotEmpty && minArea == null) ||
        (maxAreaText.isNotEmpty && maxArea == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل أرقامًا صحيحة للسعر والمساحة')),
      );
      return;
    }

    if ((minPrice != null && maxPrice != null && minPrice > maxPrice) ||
        (minArea != null && maxArea != null && minArea > maxArea)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تأكد أن الحد الأدنى لا يتجاوز الحد الأعلى'),
        ),
      );
      return;
    }

    final candidates = <String, dynamic>{
      'gov': _selectedGov,
      'category': _selectedMainCategory,
      'type': _selectedType,
      'finishing': _selectedFinishing,
      'city': _cityController.text.trim(),
      'advertiser_type': _advertiserType,
      'is_negotiable': _isNegotiable,
      'min_price': minPrice?.toString(),
      'max_price': maxPrice?.toString(),
      'min_area': minArea?.toString(),
      'max_area': maxArea?.toString(),
    };
    final filters = Map<String, dynamic>.fromEntries(
      candidates.entries.where((entry) =>
          entry.value != null && entry.value.toString().trim().isNotEmpty),
    );
    widget.onApplyFilters(filters);
    Navigator.pop(context);
  }

  String? _normalizeGovernorate(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (ConstantsData.governorates.containsKey(text)) return text;
    final matches = ConstantsData.governorates.entries
        .where((entry) => entry.value == text)
        .map((entry) => entry.key)
        .toList();
    return matches.isEmpty ? null : matches.first;
  }

  String? _normalizeCategory(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (AppConfig.mainCategories.containsKey(text)) return text;
    final matches = AppConfig.mainCategories.entries
        .where((entry) => entry.value == text)
        .map((entry) => entry.key)
        .toList();
    return matches.isEmpty ? null : matches.first;
  }

  String? _normalizeFinishing(dynamic value) {
    if (value == null) return null;
    const aliases = <String, String>{
      'finished': 'متشطب',
      'semi_finished': 'نصف تشطيب',
      'core_shell': 'على المحارة',
      'unfinished': 'بدون تشطيب',
      'lux': 'لوكس',
      'super_lux': 'سوبر لوكس',
      'ultra_super_lux': 'الترا سوبر لوكس',
    };
    final text = value.toString().trim();
    return aliases[text.toLowerCase()] ?? text;
  }

  String? _normalizeAdvertiser(dynamic value) {
    if (value == null) return null;
    const aliases = <String, String>{
      'owner': 'مالك',
      'agent': 'وسيط',
      'company': 'شركة',
    };
    final text = value.toString().trim();
    return aliases[text.toLowerCase()] ?? text;
  }

  String? _normalizeYesNo(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim().toLowerCase();
    if (text == 'نعم' || text == 'yes' || text == 'true' || text == '1') {
      return 'نعم';
    }
    if (text == 'لا' || text == 'no' || text == 'false' || text == '0') {
      return 'لا';
    }
    return null;
  }

  double? _parseNumber(String input) {
    final normalized = input
        .trim()
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll('٫', '.')
        .replaceAll('٬', '')
        .replaceAll(',', '');
    final number = double.tryParse(normalized);
    if (number == null || !number.isFinite || number < 0) return null;
    return number;
  }

  @override
  Widget build(BuildContext context) {
    final availableSubTypes = _selectedMainCategory != null
        ? AppConfig.categorySubTypes[_selectedMainCategory] ?? []
        : [];

    if (_selectedType != null && !availableSubTypes.contains(_selectedType)) {
      _selectedType = null;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header & Reset
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "تصفية البحث المتقدم",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text("إعادة ضبط",
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),

          // Scrollable Filter Fields
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Governorate
                  DropdownButtonFormField<String>(
                    value: _selectedGov,
                    decoration: _inputDec("المحافظة"),
                    items: ConstantsData.governorates.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedGov = val),
                  ),
                  const SizedBox(height: 12),

                  // Main Category
                  DropdownButtonFormField<String>(
                    value: _selectedMainCategory,
                    decoration: _inputDec("التصنيف الرئيسي"),
                    items: AppConfig.mainCategories.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedMainCategory = val;
                        _selectedType = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Sub Type
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: _inputDec("نوع العقار الفرعي"),
                    items: availableSubTypes
                        .map((typeName) => DropdownMenuItem<String>(
                              value: typeName,
                              child: Text(typeName),
                            ))
                        .toList(),
                    onChanged: _selectedMainCategory == null
                        ? null
                        : (val) => setState(() => _selectedType = val),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _cityController,
                    textInputAction: TextInputAction.search,
                    decoration: _inputDec("المدينة (اختياري)"),
                  ),
                  const SizedBox(height: 12),

                  // Finishing
                  DropdownButtonFormField<String>(
                    value: _selectedFinishing,
                    decoration: _inputDec("مستوى التشطيب"),
                    items: const [
                      DropdownMenuItem(value: 'متشطب', child: Text('متشطب')),
                      DropdownMenuItem(
                          value: 'سوبر لوكس', child: Text('سوبر لوكس')),
                      DropdownMenuItem(value: 'لوكس', child: Text('لوكس')),
                      DropdownMenuItem(
                          value: 'نصف تشطيب', child: Text('نصف تشطيب')),
                      DropdownMenuItem(
                          value: 'على المحارة', child: Text('على المحارة')),
                      DropdownMenuItem(
                          value: 'بدون تشطيب', child: Text('بدون تشطيب')),
                      DropdownMenuItem(
                          value: 'الترا سوبر لوكس',
                          child: Text('الترا سوبر لوكس')),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedFinishing = val),
                  ),
                  const SizedBox(height: 12),

                  // Price Range
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDec("أقل سعر (ج.م)"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDec("أعلى سعر (ج.م)"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Area Range
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minAreaController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDec("أقل مساحة"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _maxAreaController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDec("أكبر مساحة"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Advertiser Type
                  DropdownButtonFormField<String>(
                    value: _advertiserType,
                    decoration: _inputDec("صفة المعلن"),
                    items: const [
                      DropdownMenuItem(value: 'مالك', child: Text('مالك')),
                      DropdownMenuItem(
                          value: 'وسيط', child: Text('وسيط (سمسار)')),
                      DropdownMenuItem(
                          value: 'شركة', child: Text('شركة عقارية')),
                    ],
                    onChanged: (val) => setState(() => _advertiserType = val),
                  ),
                  const SizedBox(height: 12),

                  // Is Negotiable
                  DropdownButtonFormField<String>(
                    value: _isNegotiable,
                    decoration: _inputDec("قابل للتفاوض"),
                    items: const [
                      DropdownMenuItem(value: 'نعم', child: Text('نعم')),
                      DropdownMenuItem(value: 'لا', child: Text('لا')),
                    ],
                    onChanged: (val) => setState(() => _isNegotiable = val),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Apply Button
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _apply,
              child: const Text(
                "تطبيق الفلتر",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 1.2),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black54, width: 1.0),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF003366), width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
