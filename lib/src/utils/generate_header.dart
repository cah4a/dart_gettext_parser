import '../utils/upper_case_words.dart';

/// Joins a header object of key value pairs into a header string
String generateHeader (Map headers) {
  List lines = [];

  headers.keys.forEach((key) {
    if (key.isNotEmpty) {
      lines.add('${upperCaseWords(key)}: ${(headers[key] ?? '').trim()}');
    }
  });

  return '${lines.join('\n')}${lines.isNotEmpty ? '\n' : ''}';
}