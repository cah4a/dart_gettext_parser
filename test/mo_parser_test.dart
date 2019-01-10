import 'dart:io';
import 'dart:convert';
import 'package:gettext_parser/mo_parser.dart';
import 'package:test/test.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

final String testFixturesPath = path.join(Directory.current.path, 'test', 'fixtures');

final File utf8Mo = File(path.join(testFixturesPath,'utf8.mo'));
final File utf8Json = File(path.join(testFixturesPath, 'utf8-mo.json'));

Function deepEquals = const DeepCollectionEquality().equals;

void main() {
  group('Mo parser', () {
    test('UTF-8', () {
      final List<int> mo = utf8Mo.readAsBytesSync();
      final Map json = jsonDecode(utf8Json.readAsStringSync()) as Map;
      final Map parsed = parser(mo);

      print(parsed);

      expect(deepEquals(json, parsed), true);
    });

  });
}
