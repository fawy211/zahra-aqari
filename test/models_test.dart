import 'package:flutter_test/flutter_test.dart';
import 'package:aqari_app/models/Office_Model.dart';
import 'package:aqari_app/models/subscription_plan.dart';

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
}
