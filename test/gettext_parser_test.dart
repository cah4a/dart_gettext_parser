import 'dart:io';
import 'dart:convert';
import 'package:gettext_parser/gettext_parser.dart' as gettextParser;
import 'package:gettext_parser/src/utils/fold_line.dart';
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
        gettextParser.mo.parseBytes(bytes),
        json.decode(result.readAsStringSync()) as Map,
      );
    });

    test('latin-1', () {
      final File source = File(path.join(testFixturesPath, 'latin1.mo'));
      final File result = File(path.join(testFixturesPath, 'latin1-mo.json'));

      final List<int> bytes = source.readAsBytesSync();

      expect(
        gettextParser.mo.parseBytes(bytes, encoding: latin1),
        jsonDecode(result.readAsStringSync()) as Map,
      );
    });
  });

  group('Mo compiler', () {
    test('utf8', () {
      final File source = File(path.join(testFixturesPath, 'utf8-mo.json'));
      final File result = File(path.join(testFixturesPath, 'utf8.mo'));

      final List<int> resultList = result.readAsBytesSync();
      final Map table = json.decode(source.readAsStringSync());

      expect(gettextParser.mo.compile(table), equals(resultList));
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

  group('Po compiler', () {
    test('utf8', () {
      final File source = File(path.join(testFixturesPath, 'utf8-po.json'));
      final File result = File(path.join(testFixturesPath, 'utf8.po'));

      final String resultList = result.readAsStringSync();
      final Map table = json.decode(source.readAsStringSync());

      expect(gettextParser.po.compile(table), equals(resultList));
    });
  });

  group("utils", () {
    test('should not fold when not necessary', () {
      final line = 'abc def ghi';
      expect(
        foldLine(line),
        [line],
      );
    });

    test('should force fold with newline', () {
      final line = 'abc \\ndef \\nghi';
      final folded = foldLine(line);

      expect(line, folded.join(''));
      expect(folded, ['abc \\n', 'def \\n', 'ghi']);
    });

    test('should fold at default length', () {
      final expected = [
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum pretium ',
        'a nunc ac fringilla. Nulla laoreet tincidunt tincidunt. Proin tristique ',
        'vestibulum mauris non aliquam. Vivamus volutpat odio nisl, sed placerat ',
        'turpis sodales a. Vestibulum quis lectus ac elit sagittis sodales ac a ',
        'felis. Nulla iaculis, nisl ut mattis fringilla, tortor quam tincidunt ',
        'lorem, quis feugiat purus felis ut velit. Donec euismod eros ut leo ',
        'lobortis tristique.'
      ];
      final folded = foldLine(expected.join(''));

      expect(folded, expected);
      expect(folded.length, 7);
    });

    test('should force fold white space', () {
      final line = 'abc def ghi';
      final folded = foldLine(line, 5);

      expect(line, folded.join(''));
      expect(folded, ['abc ', 'def ', 'ghi']);
      expect(folded.length, 3);
    });

    test('should ignore leading spaces', () {
      final line = '    abc def ghi';
      final folded = foldLine(line, 5);

      expect(line, folded.join(''));
      expect(folded, ['    a', 'bc ', 'def ', 'ghi']);
      expect(folded.length, 4);
    });

    test('should force fold special character', () {
      final line = 'abcdef--ghi';
      final folded = foldLine(line, 5);

      expect(line, folded.join(''));
      expect(folded, ['abcde', 'f--', 'ghi']);
      expect(folded.length, 3);
    });

    test('should force fold last special character', () {
      final line = 'ab--cdef--ghi';
      final folded = foldLine(line, 10);

      expect(line, folded.join(''));
      expect(folded, ['ab--cdef--', 'ghi']);
      expect(folded.length, 2);
    });

    test('should force fold only if at least one non-special character', () {
      final line = '--abcdefghi';
      final folded = foldLine(line, 5);

      expect(line, folded.join(''));
      expect(folded, ['--abc', 'defgh', 'i']);
      expect(folded.length, 3);
    });
  });
}
