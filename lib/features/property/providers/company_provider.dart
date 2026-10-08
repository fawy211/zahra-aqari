import 'package:flutter/foundation.dart';
import 'package:aqari_app/models/Company_Model.dart';
import 'package:aqari_app/services/Company_Service.dart';
import 'dart:async'; // نحتاجها للتحكم في الـ StreamSubscription

class CompanyProvider with ChangeNotifier {
  final CompanyService _companyService = CompanyService();

  List<CompanyModel> _companies = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<CompanyModel>>? _companiesSubscription;

  List<CompanyModel> get companies => _companies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CompanyProvider() {
    // البدء في جلب البيانات فور إنشاء الـ Provider تلقائياً
    fetchCompanies();
  }

  // الاستماع للـ Stream وتحديث الحالة فوراً مع منع التكرار
  void fetchCompanies() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // إلغاء أي اشتراك سابق لمنع تسريب الذاكرة
    _companiesSubscription?.cancel();

    try {
      _companiesSubscription = _companyService.getCompanies().listen(
        (companiesList) {
          _companies = companiesList;
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
    // إلغاء الاستماع عند تدمير الـ Provider لحماية الذاكرة
    _companiesSubscription?.cancel();
    super.dispose();
  }
}
