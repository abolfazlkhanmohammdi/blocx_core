import 'dart:convert';
import 'dart:io';

/// Fails when README.md mentions a Blocx*/BlocX* identifier that is not declared in
/// lib/ (or in the packages listed in tool/readme_extra_packages.txt), or contains a
/// token listed in tool/readme_forbidden.txt.
///
/// Mentions of identifiers that live in a package that is NOT a dependency (for example
/// flutter_blocx classes named in the blocx_core README) go into tool/readme_allowlist.txt.
Future<void> main() async {
  final readme = File('README.md').readAsStringSync();

  Set<String> readList(String path) {
    final file = File(path);
    if (!file.existsSync()) return <String>{};
    return file
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toSet();
  }

  final source = StringBuffer();
  void addDartFilesOf(Directory dir) {
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        source.writeln(entity.readAsStringSync());
      }
    }
  }

  addDartFilesOf(Directory('lib'));

  // Optional: also look inside dependencies (resolved through .dart_tool/package_config.json).
  final extraPackages = readList('tool/readme_extra_packages.txt');
  if (extraPackages.isNotEmpty) {
    final configFile = File('.dart_tool/package_config.json');
    if (!configFile.existsSync()) {
      stderr.writeln(
        'Run `dart pub get` / `flutter pub get` first (.dart_tool/package_config.json is missing).',
      );
      exit(2);
    }
    final config =
        jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    for (final package
        in (config['packages'] as List).cast<Map<String, dynamic>>()) {
      if (!extraPackages.contains(package['name'])) continue;
      var rootUriStr = package['rootUri'] as String;
      if (!rootUriStr.endsWith('/')) rootUriStr += '/';
      final root = configFile.absolute.uri.resolve(rootUriStr);
      final libUri = root.resolve((package['packageUri'] as String?) ?? 'lib/');
      addDartFilesOf(Directory.fromUri(libUri));
    }
  }
  final libSource = source.toString();

  final allow = readList('tool/readme_allowlist.txt');
  final forbidden = readList('tool/readme_forbidden.txt');
  final problems = <String>[];

  final idPattern = RegExp(r'\b(?:Blocx|BlocX)[A-Za-z0-9_]+\b');
  final seen = <String>{};
  for (final match in idPattern.allMatches(readme)) {
    final id = match.group(0)!;
    if (!seen.add(id) || allow.contains(id)) continue;
    final declared = RegExp('\\b${RegExp.escape(id)}\\b').hasMatch(libSource);
    if (!declared) {
      problems.add(
        'README mentions `$id`, which is not declared in lib/ or the listed packages',
      );
    }
  }

  for (final token in forbidden) {
    if (RegExp('\\b${RegExp.escape(token)}\\b').hasMatch(readme)) {
      problems.add(
        'README contains forbidden (renamed or nonexistent) token `$token`',
      );
    }
  }

  if (problems.isNotEmpty) {
    stderr.writeln(problems.join('\n'));
    exit(1);
  }
  stdout.writeln('README identifiers OK (${seen.length} checked).');
}
