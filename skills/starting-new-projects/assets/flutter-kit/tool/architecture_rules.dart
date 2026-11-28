/// The project's written rules as code. test/architecture/ runs them over the
/// strict files of lib/, test/ and tool/,
/// so a violation fails CI instead of waiting for a reviewer.
///
/// To change a rule, change it here and in docs/ARCHITECTURE.md in one pull
/// request. Never add an exemption for a single file.
library;

import 'legacy_paths.dart';

/// The Dart package name, as it appears in `package:` imports.
const kitPackage = 'kit_app';

const maxFileLines = 400;

class Violation {
  const Violation(this.path, this.line, this.rule);
  final String path;
  final int line;
  final String rule;

  @override
  String toString() => '$path:$line $rule';
}

/// The folders of the old layered layout. New code never imports them, so a
/// project that adopts old code can keep it in these folders safely.
const _oldLayoutFolders = ['business_logic', 'data', 'presentation'];

/// `import 'x';` and `export 'x';` with the path captured. Matches the whole
/// text, so a directive that dart format wraps is still caught.
final _directive = RegExp(r"""\b(?:import|export)\s+['"]([^'"]+)['"]""");

/// A URL written into code, anywhere in a string. Hosts come from Env.
final _url = RegExp('https?://');

/// A literal host handed to `Uri`: `Uri.https('h', ...)`, `Uri.http('h')`
/// or `Uri(host: 'h')`. It matches the whole text, so a call that dart
/// format wraps is still caught.
final _uriHost = RegExp(
  r"""\bUri\s*\.\s*https?\s*\(\s*r?['"]|\bhost\s*:\s*r?['"]""",
);

/// The string literals of one line, left to right, up to a `//` comment.
Iterable<String> _literals(String line) sync* {
  var i = 0;
  while (i < line.length) {
    final c = line[i];
    if (c == '/' && i + 1 < line.length && line[i + 1] == '/') return;
    if (c != "'" && c != '"') {
      i++;
      continue;
    }
    final start = ++i;
    while (i < line.length && line[i] != c) {
      i += line[i] == r'\' ? 2 : 1;
    }
    yield line.substring(start, i.clamp(start, line.length));
    i++;
  }
}

/// The line index of [offset] in [text].
int _lineOf(String text, int offset) =>
    '\n'.allMatches(text.substring(0, offset)).length;
final _ignore = RegExp(r'//\s*ignore(_for_file)?:');
final _skippedTest = RegExp(r'\bskip\s*:|@Skip\b');
final _platformCheck = RegExp(r'\bkIsWeb\b|\bPlatform\.is[A-Z]');

// Styled code reads the theme and the kit tokens. These match the whole
// file text, so a call that dart format wraps after "(" is still caught.
final _rawColour = RegExp(
  r'\bColor\s*\(\s*0x|\bColor\s*\.\s*from(?:ARGB|RGBO)?\s*\('
  r'|\bColors\s*\.\s*(?!transparent\b)\w+',
);
final _inlineTextStyle = RegExp(
  r'\bTextStyle\s*\(|\bfontSize\s*:|\bfontFamily\s*:|\bfontWeight\s*:',
);
final _rawDimension = RegExp(
  r'\b(?:(?:min|max)(?:Height|Width)|height|width|radius|elevation|size'
  r'|dimension)\s*:\s*-?\d'
  r'|\bEdgeInsets(?:Directional)?\s*\.\s*\w+\s*\([^)]*\d'
  r'|\b(?:Border)?Radius\s*\.\s*circular\s*\(\s*\d',
);
final _nonDirectional = RegExp(
  r'\bEdgeInsets\s*\.\s*(?:only|fromLTRB)\s*\('
  r'|\bAlignment\s*\.\s*(?:top|center|bottom)(?:Left|Right)\b'
  r'|\bTextAlign\s*\.\s*(?:left|right)\b'
  r'|\bPositioned\s*\('
  r'|\bBorderRadius\s*\.\s*(?:only|horizontal)\s*\(',
);
final _rawMotion = RegExp(r'\bDuration\s*\(|\bCurves\s*\.\s*\w+');
final _intlFormat = RegExp(r'\b(?:DateFormat|NumberFormat)\s*[.(]');
final _intlConstructor = RegExp(
  r'\b(?:DateFormat|NumberFormat)\s*(?:\.\s*\w+\s*)?\(',
);
final _textInterpolation = RegExp(
  r'\b(?:Text|SelectableText)(?:\s*\.\s*rich)?\s*\(\s*'
  r'(?:(?:const\s+)?TextSpan\s*\(\s*text\s*:\s*)?'
  r'''(?:'[^']*(?<!\\)\$|"[^"]*(?<!\\)\$)'''
  r'|\b(?:Text|SelectableText)(?:\s*\.\s*rich)?\s*\([^)]*\.toString\s*\(',
);
final _googleFonts = RegExp(r'''import\s+['"]package:google_fonts/''');
final _presentation = RegExp('^lib/features/[^/]+/presentation/');

/// Plugins that exist on some platforms only, and platform checks, live here.
const platformDir = 'lib/core/platform/';

/// The only home of DateFormat and NumberFormat.
const l10nDir = 'lib/core/l10n/';
const apiFormatsPath = 'lib/core/l10n/api_formats.dart';

const featuresDir = 'lib/features/';

/// The kit obeys the rules it imposes on features.
const kitDirs = ['lib/core/widgets/', 'lib/app/shell/', 'lib/app/kit_gallery/'];

/// Colours, text styles, sizes and direction come from lib/core/theme.
bool isStyled(String path) =>
    path.startsWith(featuresDir) || kitDirs.any(path.startsWith);

/// Motion comes from Motion; a data layer's cache time is not motion.
bool isMotionScoped(String path) =>
    _presentation.hasMatch(path) || kitDirs.any(path.startsWith);

/// The path inside `lib/` that [target] points at, or null when it is not a
/// file of this package. [from] is the importing file, relative to the root.
String? _libPath(String from, String target) {
  const prefix = 'package:$kitPackage/';
  if (target.startsWith(prefix)) {
    return 'lib/${target.substring(prefix.length)}';
  }
  if (target.contains(':')) return null;
  return Uri.parse(from).resolve(target).path;
}

/// Whether the import of [target] from [from] reaches old-layout code.
bool isLegacyImport(String from, String target) {
  final lib = _libPath(from, target);
  if (lib == null) return false;
  return isLegacy(lib) ||
      _oldLayoutFolders.any((d) => lib.startsWith('lib/$d/'));
}

/// Whether a file in one feature imports a file of a different feature.
bool importsAnotherFeature(String from, String target) {
  final lib = _libPath(from, target);
  if (lib == null || !lib.startsWith(featuresDir)) return false;
  String featureOf(String p) =>
      p.substring(featuresDir.length).split('/').first;
  return featureOf(lib) != featureOf(from);
}

const coreDir = 'lib/core/';

/// Whether a core file imports a feature. Core is the base: one upward
/// import and nothing can move or be deleted on its own.
bool coreImportsFeature(String from, String target) {
  if (!from.startsWith(coreDir)) return false;
  final lib = _libPath(from, target);
  return lib != null && lib.startsWith(featuresDir);
}

/// Packages that are HTTP, storage or platform SDKs. A screen reads a state
/// holder instead, so tests use a double and a source can change alone.
const _dataPackages = [
  'dio',
  'http',
  'shared_preferences',
  'flutter_secure_storage',
  'sqflite',
  'hive',
  'firebase_core',
  'cloud_firestore',
  'firebase_auth',
];

/// Whether a presentation file reaches a data source, a repository
/// implementation, or an HTTP, storage or SDK package. Data models are fine:
/// they are plain values the state carries.
bool presentationImportsData(String from, String target) {
  if (!_presentation.hasMatch(from)) return false;
  if (target.startsWith('package:')) {
    final package = target.substring('package:'.length).split('/').first;
    if (_dataPackages.contains(package)) return true;
  }
  final lib = _libPath(from, target);
  if (lib == null || !lib.startsWith(featuresDir)) return false;
  final parts = lib.substring(featuresDir.length).split('/');
  return parts.length > 2 && parts[1] == 'data' && parts[2] != 'models';
}

/// The text of the call that opens at [open], up to its closing paren.
String _call(String text, int open) {
  var depth = 0;
  for (var i = open; i < text.length; i++) {
    final c = text[i];
    if (c == '(') depth++;
    if (c == ')' && --depth == 0) return text.substring(open, i + 1);
  }
  return text.substring(open);
}

/// Every rule [content] breaks. [path] is relative to the repo root.
List<Violation> checkDartFile(String path, String content) {
  final lines = content.split('\n');
  final legacy = isLegacy(path);
  final isTest = path.startsWith('test/');
  final inLib = path.startsWith('lib/');
  final styled = isStyled(path);
  final motion = isMotionScoped(path);
  final inFeatures = path.startsWith(featuresDir);
  final found = <Violation>[];
  void flag(int i, String rule) => found.add(Violation(path, i + 1, rule));
  if (!legacy && lines.length > maxFileLines) {
    found.add(Violation(path, maxFileLines + 1, 'max-lines'));
  }
  if (inLib) {
    for (final m in _uriHost.allMatches(content)) {
      final i = _lineOf(content, m.start);
      if (!lines[i].trimLeft().startsWith('//')) flag(i, 'raw-host');
    }
  }
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (inLib && _literals(line).any(_url.hasMatch)) flag(i, 'raw-host');
    if (legacy) continue;
    if (inLib &&
        !path.startsWith(platformDir) &&
        _platformCheck.hasMatch(line)) {
      flag(i, 'platform-check');
    }
    if (_ignore.hasMatch(line)) flag(i, 'ignore-comment');
    if (isTest && _skippedTest.hasMatch(line)) flag(i, 'skipped-test');
    if (inLib && _googleFonts.hasMatch(line)) flag(i, 'google-fonts');
  }
  final seen = <String>{};
  int lineOf(int offset) =>
      '\n'.allMatches(content.substring(0, offset)).length;
  void scan(RegExp re, String rule, {bool Function(Match)? when}) {
    for (final m in re.allMatches(content)) {
      if (when != null && !when(m)) continue;
      final i = lineOf(m.start);
      if (seen.add('$rule:$i')) flag(i, rule);
    }
  }

  if (legacy) return found;
  scan(
    _directive,
    'legacy-import',
    when: (m) => isLegacyImport(path, m.group(1)!),
  );
  if (inFeatures) {
    scan(
      _directive,
      'cross-feature-import',
      when: (m) => importsAnotherFeature(path, m.group(1)!),
    );
    scan(
      _directive,
      'presentation-imports-data',
      when: (m) => presentationImportsData(path, m.group(1)!),
    );
  }
  scan(
    _directive,
    'core-imports-feature',
    when: (m) => coreImportsFeature(path, m.group(1)!),
  );
  // Whole-text rules: the line reported is where the match starts.
  if (inLib && !path.startsWith(l10nDir)) scan(_intlFormat, 'intl-format');
  if (path == apiFormatsPath) {
    scan(
      _intlConstructor,
      'api-locale',
      when: (m) => !_call(content, m.end - 1).contains("'en'"),
    );
  }
  if (styled) {
    scan(_rawColour, 'raw-colour');
    scan(_inlineTextStyle, 'inline-text-style');
    scan(_rawDimension, 'raw-dimension');
    scan(_nonDirectional, 'non-directional');
  }
  if (motion) scan(_rawMotion, 'raw-motion');
  if (inFeatures) scan(_textInterpolation, 'text-interpolation');
  return found;
}
