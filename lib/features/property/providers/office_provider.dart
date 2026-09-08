import 'package:flutter/foundation.dart';
import 'package:aqari_app/models/Office_Model.dart';
import 'package:aqari_app/services/Office_Service.dart';
import 'dart:async'; // نحتاجها لإدارة الـ StreamSubscription

class OfficeProvider with ChangeNotifier {
  final OfficeService _officeService = OfficeService();

  List<OfficeModel> _offices = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<OfficeModel>>? _officesSubscription;

  List<OfficeModel> get offices => _offices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  OfficeProvider() {
    // جلب المكاتب تلقائياً عند إنشاء الـ Provider
    fetchOffices();
  }

  // الاستماع للـ Stream وتحديث الحالة فوراً مع منع تكرار الاتصالات
  void fetchOffices() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // إلغاء أي اشتراك قديم قبل بدء واحد جديد
    _officesSubscription?.cancel();

    try {
      _officesSubscription = _officeService.getOffices().listen(
        (officesList) {
          _offices = officesList;
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // إلغاء الاشتراك عندما يتم تدمير الـ Provider لحماية الذاكرة
    _officesSubscription?.cancel();
    super.dispose();
  }
}
