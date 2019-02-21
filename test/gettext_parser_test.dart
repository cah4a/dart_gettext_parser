import 'dart:io';
import 'dart:convert';
import 'package:gettext_parser/gettext_parser.dart' as gettextParser;
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

final String testFixturesPath =
    path.join(Directory.current.path, 'test', 'fixtures');

void main() {
  group('Mo parser', () {
    test('utf8', () {
      final File source = File(path.join(testFixturesPath, 'utf8.mo'));
      final File result = File(path.join(testFixturesPath, 'utf8-mo.json'));

      final List<int> bytes = source.readAsBytesSync();

      expect(
        gettextParser.mo.parse(bytes),
        jsonDecode(result.readAsStringSync()) as Map,
      );
    });

    test('latin-1', () {
      final File source = File(path.join(testFixturesPath, 'latin1.mo'));
      final File result = File(path.join(testFixturesPath, 'latin1-mo.json'));

      final List<int> bytes = source.readAsBytesSync();

      expect(
        gettextParser.mo.parse(bytes, encoding: latin1),
        jsonDecode(result.readAsStringSync()) as Map,
      );
    });
  });

  group('Mo compiler', () {
    test('utf8', () {
      final File source = File(path.join(testFixturesPath, 'utf8-mo.json'));
      final File result = File(path.join(testFixturesPath,'utf8.mo'));

      final List<int> resultList = result.readAsBytesSync();
      final Map json = jsonDecode(source.readAsStringSync()) as Map;

      expect(
        gettextParser.mo.compile(json),
        equals(resultList));
    });
  });

  group('Po parser', () {
    test('utf-8', () {
      final File source = File(path.join(testFixturesPath, 'utf8.po'));
      final File expected = File(path.join(testFixturesPath, 'utf8-po.json'));

      final String text = source.readAsStringSync();

      expect(
        gettextParser.po.parse(text),
        jsonDecode(expected.readAsStringSync()) as Map,
      );
    });

    test('latin-1', () {
      final File source = File(path.join(testFixturesPath, 'latin1.po'));
      final File expected = File(path.join(testFixturesPath, 'latin1-po.json'));

      final List<int> bytes = source.readAsBytesSync();

      expect(
        gettextParser.po.parseBytes(bytes, encoding: latin1),
        jsonDecode(expected.readAsStringSync()) as Map,
      );
    });
  });
}
