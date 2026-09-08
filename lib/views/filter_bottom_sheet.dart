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

  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _minAreaController = TextEditingController();
  final TextEditingController _maxAreaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedGov = widget.initialFilters['gov'];
    _selectedMainCategory = widget.initialFilters['category'] ??
        widget.initialFilters['categoryCode'];
    _selectedType = widget.initialFilters['type'];
    _selectedFinishing = widget.initialFilters['finishing'];
    _advertiserType = widget.initialFilters['advertiser_type'];
    _isNegotiable = widget.initialFilters['is_negotiable'];

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
      _minPriceController.clear();
      _maxPriceController.clear();
      _minAreaController.clear();
      _maxAreaController.clear();
    });
  }

  void _apply() {
    final filters = {
      'gov': _selectedGov,
      'category': _selectedMainCategory,
      'type': _selectedType,
      'finishing': _selectedFinishing,
      'advertiser_type': _advertiserType,
      'is_negotiable': _isNegotiable,
      'min_price': _minPriceController.text.trim(),
      'max_price': _maxPriceController.text.trim(),
      'min_area': _minAreaController.text.trim(),
      'max_area': _maxAreaController.text.trim(),
    };
    widget.onApplyFilters(filters);
    Navigator.pop(context);
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

                  // Finishing
                  DropdownButtonFormField<String>(
                    value: _selectedFinishing,
                    decoration: _inputDec("مستوى التشطيب"),
                    items: const [
                      DropdownMenuItem(
                          value: 'سوبر لوكس', child: Text('سوبر لوكس')),
                      DropdownMenuItem(value: 'لوكس', child: Text('لوكس')),
                      DropdownMenuItem(
                          value: 'نصف تشطيب', child: Text('نصف تشطيب')),
                      DropdownMenuItem(
                          value: 'على المحارة', child: Text('على المحارة')),
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
