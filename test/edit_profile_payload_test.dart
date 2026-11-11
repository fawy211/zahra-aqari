import 'package:flutter_test/flutter_test.dart';

import 'package:aqari_app/views/edit_profile_screen.dart';

void main() {
  group('buildProfileUpdateData', () {
    test('sends only columns that the profiles table has', () {
      final data = buildProfileUpdateData(
        name: '  Zahra  ',
        phone: ' 01000000000 ',
        companyName: ' Aqari ',
      );

      expect(data.keys.toSet().difference(kProfilesUpdateColumns), isEmpty);
      expect(data.containsKey('avatar_url'), isFalse);
      expect(data, {
        'name': 'Zahra',
        'phone': '01000000000',
        'company_name': 'Aqari',
      });
    });

    test('leaves an empty company name out of the update', () {
      final data = buildProfileUpdateData(
        name: 'Zahra',
        phone: '01000000000',
        companyName: '   ',
      );

      expect(data, {'name': 'Zahra', 'phone': '01000000000'});
    });
  });
}
