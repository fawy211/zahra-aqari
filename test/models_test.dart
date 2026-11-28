import 'package:flutter_test/flutter_test.dart';
import 'package:aqari_app/models/Office_Model.dart';
import 'package:aqari_app/models/property_models.dart';
import 'package:aqari_app/models/subscription_plan.dart';
import 'package:aqari_app/models/user_model.dart';

void main() {
  group('OfficeModel', () {
    test('parses the public office directory fields', () {
      final office = OfficeModel.fromMap({
        'id': 'office-1',
        'name': 'مكتب النور',
        'location': 'الجيزة',
        'phone': '01000000000',
        'logo': 'https://example.com/logo.png',
        'created_at': '2026-11-27T10:00:00Z',
      });

      expect(office.id, 'office-1');
      expect(office.name, 'مكتب النور');
      expect(office.address, 'الجيزة');
      expect(office.phone, '01000000000');
      expect(office.logo, 'https://example.com/logo.png');
      expect(office.email, isNull);
    });

    test('serializes optional office details into metadata', () {
      final office = OfficeModel(
        name: 'مكتب تجريبي',
        phone: '01111111111',
        email: 'office@example.com',
        address: 'القاهرة',
        propertiesCount: 4,
        isVerified: true,
      );

      final data = office.toMap();
      final metadata = data['metadata'] as Map<String, dynamic>;

      expect(data['name'], 'مكتب تجريبي');
      expect(data['location'], 'القاهرة');
      expect(metadata['contact_phone'], '01111111111');
      expect(metadata['contact_email'], 'office@example.com');
      expect(metadata['properties_count'], 4);
      expect(metadata['is_verified'], isTrue);
      expect(data.containsKey('owner_id'), isFalse);
      expect(data.containsKey('company_id'), isFalse);
    });
  });

  group('PropertyModel', () {
    test('keeps company ownership metadata without adding a database column', () {
      final property = PropertyModel(
        title: 'شقة للاختبار',
        description: 'وصف',
        categoryCode: 'residential',
        type: 'شقة',
        finishing: 'كامل',
        price: 1500000,
        area: 120,
        gov: 'الجيزة',
        city: 'الهرم',
        street: 'شارع تجريبي',
        advertiserType: 'شركة',
        phone: '01000000000',
        images: const [],
        ownerId: 'owner-1',
        companyId: 'company-1',
        metadata: const {'rooms': '3'},
      );

      final data = property.toMap();
      expect(data['owner_id'], 'owner-1');
      expect(data.containsKey('company_id'), isFalse);
      expect(data['metadata']['company_id'], 'company-1');
      expect(data['metadata']['rooms'], '3');
    });

    test('reads company ownership from metadata', () {
      final property = PropertyModel.fromMap({
        'id': 'property-1',
        'title': 'شقة',
        'owner_id': 'owner-1',
        'metadata': {'company_id': 'company-1'},
      });

      expect(property.companyId, 'company-1');
      expect(property.ownerId, 'owner-1');
    });
  });

  group('SubscriptionPlan', () {
    test('keeps the configured limits and price', () {
      const plan = SubscriptionPlan(
        id: 'companies',
        name: 'شركات',
        price: 500,
        maxAdsPerMonth: 20,
        maxVideoDuration: 300,
      );

      expect(plan.price, 500);
      expect(plan.maxAdsPerMonth, 20);
      expect(plan.maxVideoDuration, 300);
    });
  });

  group('UserModel', () {
    test('round-trips profile contact and avatar fields', () {
      final user = UserModel(
        uid: 'user-1',
        email: 'user@example.com',
        name: 'مستخدم تجريبي',
        accountType: 'company',
        userType: 'company',
        phone: '01000000000',
        companyName: 'شركة زهرة',
        avatarPath: 'user-1/avatar.png',
      );

      final restored = UserModel.fromMap(user.toMap(), user.uid);
      expect(restored.phone, '01000000000');
      expect(restored.companyName, 'شركة زهرة');
      expect(restored.avatarPath, 'user-1/avatar.png');
      expect(restored.accountType, 'company');
    });

    test('copyWith preserves profile fields when changing the name', () {
      final user = UserModel(
        uid: 'user-1',
        email: 'user@example.com',
        phone: '01000000000',
        companyName: 'شركة زهرة',
        avatarPath: 'user-1/avatar.png',
      );

      final updated = user.copyWith(name: 'اسم جديد');
      expect(updated.name, 'اسم جديد');
      expect(updated.phone, user.phone);
      expect(updated.companyName, user.companyName);
      expect(updated.avatarPath, user.avatarPath);
    });
  });


}
