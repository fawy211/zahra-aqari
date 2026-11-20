import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final String manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final String infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

  test('the Android queries element declares the schemes passed to canLaunchUrl', () {
    final String? queries = RegExp(r'<queries>([\s\S]*?)</queries>').firstMatch(manifest)?.group(1);
    expect(queries, isNotNull, reason: 'AndroidManifest.xml holds no <queries> element');

    final Iterable<String?> viewSchemes = RegExp(
      r'<intent>\s*<action android:name="android.intent.action.VIEW"\s*/>\s*'
      r'<data android:scheme="([^"]+)"\s*/>\s*</intent>',
    ).allMatches(queries!).map((RegExpMatch match) => match.group(1));

    expect(viewSchemes, containsAll(<String>['tel', 'https']));
  });

  test('LSApplicationQueriesSchemes declares the same schemes', () {
    final String? block = RegExp(
      r'<key>LSApplicationQueriesSchemes</key>\s*<array>([\s\S]*?)</array>',
    ).firstMatch(infoPlist)?.group(1);
    expect(block, isNotNull, reason: 'Info.plist declares no LSApplicationQueriesSchemes');

    final Iterable<String?> schemes =
        RegExp(r'<string>([^<]+)</string>').allMatches(block!).map((RegExpMatch m) => m.group(1));

    expect(schemes, containsAll(<String>['tel', 'https']));
  });
}
