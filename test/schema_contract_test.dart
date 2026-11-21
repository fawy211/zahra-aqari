// Contract test between this Flutter client and the live Supabase project
// qttlxhavrfqiwhqzxtmx.
//
// Run it with:
//   flutter test test/schema_contract_test.dart
//
// The repository has no CI, so run this test by hand whenever you add a table
// name, a column name, or a model field under lib/. It needs network access to
// the project.
//
// The test reads the project URL and the publishable key from
// lib/supabase_options.dart, so it always probes the project that the app
// talks to. It only reads: every probe ends with limit=0 and no row is
// returned or written.
//
// How the test learns the schema. The project does not let this key read the
// OpenAPI root (it answers 401 "Secret API key required"), so the only schema
// source is PostgREST. A probe names the columns of one table. PostgREST
// answers HTTP 400 with code 42703 and "column <table>.<column> does not
// exist" for the first name it does not know, so the probe drops that name and
// repeats until the answer is 200. Every dropped name is a column the client
// reads and the project lacks. A table the project lacks answers HTTP 404 with
// code PGRST205 (or 42P01 on older PostgREST), which is drift too.
//
// What the test reads:
//   * every `.from('<table>')` call on a Supabase client in lib/**. A call on
//     a storage bucket (`supabase.storage.from(...)`) names a bucket and a
//     Dart collection conversion (`Map<String, dynamic>.from(...)`,
//     `List<String>.from(...)`) names no table, so both are skipped.
//   * every `map['<column>']` key in lib/models/**. A model file holds no
//     table name, so _modelTables records the table whose rows each model maps
//     and the call site that passes the rows. A new model file with map keys
//     that is in neither _modelTables nor _modelsWithoutRowSource fails the
//     test, so the mapping cannot be forgotten.
// Column names in write payloads and filter arguments of lib/views and
// lib/services are out of scope: this test reads the two sources above only.
//
// knownDrift holds the drift that main carries today, so the test can pass
// before the fixes land. Each entry says what removes it. An entry that the
// project no longer reproduces fails the second test, so the list cannot
// outlive its fixes.

import 'dart:convert';
import 'dart:io';

import 'package:aqari_app/supabase_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  late Map<String, Set<String>> tablesBySource;
  late Map<String, Set<String>> columnsByModel;

  setUpAll(() {
    final _References references = _scanLib(Directory('lib'));
    tablesBySource = references.tablesBySource;
    columnsByModel = references.columnsByModel;
  });

  test(
    'every table and column the client names exists in the Supabase project',
    () async {
      final List<_Drift> observed =
          await _liveDrift(tablesBySource, columnsByModel);
      final Map<String, _KnownDrift> known = <String, _KnownDrift>{
        for (final _KnownDrift entry in _knownDrift) entry.id: entry,
      };

      final List<String> unexpected = <String>[];
      for (final _Drift drift in observed) {
        final _KnownDrift? entry = known[drift.id];
        if (entry == null) {
          unexpected.addAll(drift.describe('add the table and the column to '
              'the project, or correct the name in the client'));
          continue;
        }
        if (drift.tableMissing != entry.tableMissing) {
          unexpected.add(drift.tableMissing
              ? 'table "${drift.table}" disappeared from the project '
                  '(${drift.source})'
              : 'table "${drift.table}" exists again, so the client can read '
                  'it (${drift.source}). Remove the knownDrift entry.');
        }
        final Set<String> newColumns = drift.columns.difference(entry.columns);
        for (final String column in newColumns) {
          unexpected.add('column "${drift.table}.$column" does not exist '
              '(${drift.source}). Correct the name in the client, or add the '
              'column to the project.');
        }
      }

      expect(
        unexpected,
        isEmpty,
        reason: 'The client reads schema elements that the project '
            'qttlxhavrfqiwhqzxtmx does not have. This request fails for users '
            'as a PostgREST 400 error or as a field that stays null:\n'
            '${unexpected.map((String line) => '  - $line').join('\n')}',
      );
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test(
    'knownDrift holds only drift that the project still has',
    () async {
      final List<_Drift> observed =
          await _liveDrift(tablesBySource, columnsByModel);
      final Map<String, _Drift> seen = <String, _Drift>{
        for (final _Drift drift in observed) drift.id: drift,
      };

      final List<String> stale = <String>[];
      for (final _KnownDrift entry in _knownDrift) {
        final _Drift? drift = seen[entry.id];
        if (drift == null) {
          stale.add('"${entry.table}" in ${entry.source} is no longer read by '
              'the client, or the project now has it (${entry.removedBy}). '
              'Delete this knownDrift entry.');
          continue;
        }
        if (drift.tableMissing) {
          if (!entry.tableMissing) {
            stale.add('table "${entry.table}" is gone, so its columns cannot '
                'be checked; mark the entry tableMissing (${entry.removedBy}).');
          }
          continue;
        }
        final Set<String> fixed = entry.columns.difference(drift.columns);
        for (final String column in fixed) {
          stale.add('column "${entry.table}.$column" in ${entry.source} exists '
              'now (${entry.removedBy}). Delete it from the knownDrift entry.');
        }
      }

      expect(
        stale,
        isEmpty,
        reason: 'knownDrift lists drift that the project no longer has, so the '
            'list outlived its fixes:\n'
            '${stale.map((String line) => '  - $line').join('\n')}',
      );
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

/// Tables whose rows each model maps, with the call site that passes the rows.
///
/// The test cannot derive this link from a source file, because a model holds
/// no table name, so the link is written down here.
const Map<String, String> _modelTables = <String, String>{
  // CompanyService._supabase.from('companies') -> CompanyModel.fromMap.
  'lib/models/Company_Model.dart': 'companies',
  // OfficeService._supabase.from('offices') -> OfficeModel.fromMap.
  'lib/models/Office_Model.dart': 'offices',
  // property_service.from('properties') -> PropertyModel.fromMap.
  'lib/models/property_models.dart': 'properties',
  // profile_screen.from('profiles') -> UserModel.fromMap.
  'lib/models/user_model.dart': 'profiles',
};

/// Model files that read no row, so no table owns their map keys.
const Set<String> _modelsWithoutRowSource = <String>{
  // DelegateModel.fromMap has no caller in lib/.
  'lib/models/delegate_model.dart',
};

/// Drift that main carries today. Every entry names what removes it.
const List<_KnownDrift> _knownDrift = <_KnownDrift>[
  // Tables the project does not have.
  _KnownDrift(
    table: 'users',
    source: 'lib/views/company_registration_screen.dart',
    tableMissing: true,
    removedBy: 'PR #4 writes the company owner to profiles',
  ),
  _KnownDrift(
    table: 'users',
    source: 'lib/views/subscription_screen.dart',
    tableMissing: true,
    removedBy: 'PR #8 writes the plan to profiles, and PR #1 deletes the write',
  ),
  _KnownDrift(
    table: 'users',
    source: 'lib/views/Company_Admin_Dashboard.dart',
    tableMissing: true,
    removedBy: 'nothing yet: no open pull request or record corrects this read',
  ),
  _KnownDrift(
    table: 'users',
    source: 'lib/views/company_profile_view.dart',
    tableMissing: true,
    removedBy: 'nothing yet: no open pull request or record corrects this read',
  ),
  _KnownDrift(
    table: 'app_settings',
    source: 'lib/services/settings_service.dart',
    tableMissing: true,
    removedBy: 'nothing yet: no open pull request or record corrects this read',
  ),
  _KnownDrift(
    table: 'company_delegates',
    source: 'lib/views/add_delegate_screen.dart',
    tableMissing: true,
    removedBy: 'nothing yet: no open pull request or record corrects this read',
  ),
  _KnownDrift(
    table: 'pages',
    source: 'lib/views/info_pages_view.dart',
    tableMissing: true,
    removedBy: 'nothing yet: no open pull request or record corrects this read',
  ),

  // Columns the project does not have, read by the models.
  _KnownDrift(
    table: 'companies',
    source: 'lib/models/Company_Model.dart',
    columns: <String>{
      'email',
      'phone',
      'logo',
      'address',
      'description',
      'projectsCount',
      'isVerified',
      'createdAt',
    },
    removedBy: 'nothing yet: no open pull request or record corrects this map',
  ),
  _KnownDrift(
    table: 'offices',
    source: 'lib/models/Office_Model.dart',
    columns: <String>{
      'phone',
      'email',
      'logo',
      'address',
      'propertiesCount',
      'properties_count',
      'isVerified',
      'is_verified',
      'createdAt',
    },
    removedBy: 'nothing yet: no open pull request or record corrects this map',
  ),
  _KnownDrift(
    table: 'properties',
    source: 'lib/models/property_models.dart',
    columns: <String>{
      'categoryCode',
      'ownerId',
      'companyId',
      'company_id',
      'isFeatured',
      'isReported',
      'reportCount',
    },
    removedBy: 'nothing yet: no open pull request or record corrects this map',
  ),
  _KnownDrift(
    table: 'profiles',
    source: 'lib/models/user_model.dart',
    columns: <String>{
      'full_name',
      'accountType',
      'subscriptionPlan',
      'adsCount',
      'isVerifiedOffice',
    },
    removedBy: 'nothing yet: no open pull request or record corrects this map',
  ),
];

/// A `.from('<table>')` call in lib/.
final RegExp _fromCall = RegExp(r"\.from\(\s*'([^']+)'\s*\)");

/// A `map['<column>']` read in lib/models/.
final RegExp _mapKey = RegExp(r"\bmap\[\s*'([^']+)'\s*\]");

/// Receivers of `.from(` that name no table of the project.
const Set<String> _collectionTypes = <String>{'List', 'Map', 'Set', 'Iterable'};

class _References {
  _References(this.tablesBySource, this.columnsByModel);

  /// Table name -> the lib/ files that name it.
  final Map<String, Set<String>> tablesBySource;

  /// Model file -> the column names that it reads.
  final Map<String, Set<String>> columnsByModel;
}

class _Drift {
  _Drift({
    required this.table,
    required this.source,
    this.tableMissing = false,
    Set<String>? columns,
  }) : columns = columns ?? <String>{};

  final String table;

  /// Path of the lib/ file that names the table or reads the column.
  final String source;

  /// True when the project has no such table, so no column was checked.
  final bool tableMissing;

  /// Columns of [table] that the project does not have.
  final Set<String> columns;

  String get id => '$table|$source';

  /// One line per missing element, for the failure message.
  List<String> describe(String action) {
    if (tableMissing) {
      return <String>['table "$table" does not exist ($source). $action.'];
    }
    return columns
        .map((String column) =>
            'column "$table.$column" does not exist ($source). $action.')
        .toList();
  }
}

class _KnownDrift {
  const _KnownDrift({
    required this.table,
    required this.source,
    this.tableMissing = false,
    this.columns = const <String>{},
    required this.removedBy,
  });

  final String table;
  final String source;
  final bool tableMissing;
  final Set<String> columns;

  /// What removes this entry: an open pull request, or the fact that nothing
  /// does yet.
  final String removedBy;

  String get id => '$table|$source';
}

_References _scanLib(Directory libDirectory) {
  final Map<String, Set<String>> tablesBySource = <String, Set<String>>{};
  final Map<String, Set<String>> columnsByModel = <String, Set<String>>{};
  final List<File> files = libDirectory
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) => file.path.endsWith('.dart'))
      .toList();

  if (files.isEmpty) {
    fail('No Dart file under ${libDirectory.path}. Run this test from the '
        'package root: flutter test test/schema_contract_test.dart');
  }

  for (final File file in files) {
    final String path = _libRelativePath(file.path);
    final String source = file.readAsStringSync();
    for (final RegExpMatch match in _fromCall.allMatches(source)) {
      if (!_isTableCall(source, match.start)) {
        continue;
      }
      tablesBySource
          .putIfAbsent(match.group(1)!, () => <String>{})
          .add(path);
    }
    if (!path.startsWith('lib/models/')) {
      continue;
    }
    final Set<String> keys = <String>{
      for (final RegExpMatch match in _mapKey.allMatches(source))
        match.group(1)!,
    };
    if (keys.isEmpty) {
      continue;
    }
    if (!_modelTables.containsKey(path) &&
        !_modelsWithoutRowSource.contains(path)) {
      fail('$path reads row fields but the test knows no table for it. Add it '
          'to _modelTables with the table whose rows it maps, or to '
          '_modelsWithoutRowSource with the reason it maps no row.');
    }
    columnsByModel[path] = keys;
  }

  return _References(tablesBySource, columnsByModel);
}

/// The path of a scanned file from `lib/` on, so that knownDrift entries and
/// messages hold a path that does not depend on the machine.
String _libRelativePath(String path) {
  final String normalized = path.replaceAll(r'\', '/');
  final int index = normalized.indexOf('lib/');
  return index < 0 ? normalized : normalized.substring(index);
}

/// True when the `.from(` at [dotIndex] reads a table of the project.
bool _isTableCall(String source, int dotIndex) {
  final int start = dotIndex - 40 < 0 ? 0 : dotIndex - 40;
  final String receiver =
      source.substring(start, dotIndex).replaceFirst(RegExp(r'\s+$'), '');
  // supabase.storage.from(...) names a bucket.
  if (receiver.endsWith('storage')) {
    return false;
  }
  // Map<String, dynamic>.from(...) and List<String>.from(...) name no table.
  if (receiver.endsWith('>')) {
    return false;
  }
  final String? word = RegExp(r'\w+$').stringMatch(receiver);
  return !_collectionTypes.contains(word);
}

/// The drift that the live project answers for the tables and columns read by
/// the client.
Future<List<_Drift>> _liveDrift(
  Map<String, Set<String>> tablesBySource,
  Map<String, Set<String>> columnsByModel,
) async {
  final Map<String, Set<String>> columnsByTable = <String, Set<String>>{};
  for (final MapEntry<String, Set<String>> entry in columnsByModel.entries) {
    final String? table = _modelTables[entry.key];
    if (table == null) {
      continue;
    }
    columnsByTable.putIfAbsent(table, () => <String>{}).addAll(entry.value);
  }

  final Set<String> tables = <String>{
    ...tablesBySource.keys,
    ...columnsByTable.keys,
  };
  final Set<String> missingTables = <String>{};
  final Map<String, Set<String>> missingColumns = <String, Set<String>>{};

  final http.Client client = http.Client();
  try {
    for (final String table in tables.toList()..sort()) {
      await _probe(
        client,
        table,
        columnsByTable[table] ?? const <String>{},
        missingTables,
        missingColumns,
      );
    }
  } finally {
    client.close();
  }

  final List<_Drift> drift = <_Drift>[];
  for (final String table in missingTables.toList()..sort()) {
    // A missing table is drift for each file that reads it, so that the entry
    // that names a pull request disappears when that file stops reading it.
    for (final String source in (tablesBySource[table] ?? const <String>{})
        .toList()
      ..sort()) {
      drift.add(_Drift(table: table, source: source, tableMissing: true));
    }
  }
  for (final MapEntry<String, Set<String>> entry in columnsByModel.entries) {
    final String? table = _modelTables[entry.key];
    if (table == null) {
      continue;
    }
    final Set<String> missing = entry.value.intersection(
      missingColumns[table] ?? const <String>{},
    );
    if (missing.isEmpty) {
      continue;
    }
    drift.add(
      _Drift(table: table, source: entry.key, columns: missing),
    );
  }
  return drift;
}

/// Probes one table, removes each name that PostgREST rejects, and records the
/// rejections in [missingTables] or [missingColumns].
Future<void> _probe(
  http.Client client,
  String table,
  Set<String> candidates,
  Set<String> missingTables,
  Map<String, Set<String>> missingColumns,
) async {
  // With no candidate column, select=* still shows whether the table exists.
  final List<String> remaining = candidates.toList()..sort();
  while (true) {
    final String select = remaining.isEmpty ? '*' : remaining.join(',');
    final Uri uri = Uri.parse('${SupabaseConfig.url}/rest/v1/$table'
        '?select=$select&limit=0&apikey=${SupabaseConfig.anonKey}');
    final http.Response response = await _get(client, uri, table);

    if (response.statusCode == 200) {
      return;
    }
    final Map<String, dynamic>? body = _jsonObject(response.body);
    final String code = body?['code']?.toString() ?? '';
    final String message = body?['message']?.toString() ?? response.body;

    // The project has no such table. 42P01 is the SQL state, PGRST205 the code
    // that recent PostgREST builds answer with.
    if (code == '42P01' || code == 'PGRST205') {
      missingTables.add(table);
      return;
    }
    if (code == '42703') {
      final String? column = _missingColumnName(message);
      if (column == null || !remaining.remove(column)) {
        fail('The probe for table "$table" answered code 42703 with a message '
            'that names no requested column: $message');
      }
      missingColumns.putIfAbsent(table, () => <String>{}).add(column);
      continue;
    }
    fail('The probe for table "$table" answered HTTP ${response.statusCode} '
        'with code "$code": $message');
  }
}

Future<http.Response> _get(
  http.Client client,
  Uri uri,
  String table,
) async {
  try {
    return await client.get(uri).timeout(const Duration(seconds: 20));
  } catch (error) {
    fail('Cannot reach ${SupabaseConfig.url} to check table "$table": $error. '
        'Check the network connection and the key in lib/supabase_options.dart.');
  }
}

/// The column that PostgREST names in `column <table>.<column> does not exist`.
String? _missingColumnName(String message) {
  final RegExpMatch? match =
      RegExp(r'column [^\s]+\.(\S+) does not exist').firstMatch(message);
  return match?.group(1);
}

Map<String, dynamic>? _jsonObject(String body) {
  try {
    final Object? decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}
