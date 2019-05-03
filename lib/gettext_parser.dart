library mo_parser;

import 'dart:convert';
import 'dart:typed_data';

import './src/mo/parser.dart';
import './src/po/parser.dart';

const mo = const _Mo();
const po = const _Po();

class _Mo {
  const _Mo();

  /// Parse mo file data with encoding
  Map<String, dynamic> parse(ByteData data, {Encoding encoding: utf8}) {
    final parser = new MoParser(data, encoding: encoding);
    return parser.parse();
  }

  /// Parse mo file data with encoding
  Map<String, dynamic> parseBytes(List<int> data, {Encoding encoding: utf8}) {
    final parser = new MoParser(
      ByteData.view(Uint8List.fromList(data).buffer),
      encoding: encoding,
    );

    return parser.parse();
  }
}

class _Po {
  const _Po();

  /// Parse po data file with encoding
  Map<String, dynamic> parseBytes(List<int> data, {Encoding encoding: utf8}) {
    final parser = new PoParser(encoding.decode(data));
    return parser.parse(charset: encoding.name);
  }

  /// Parse po file string
  Map<String, dynamic> parse(String text) {
    final parser = new PoParser(text);
    return parser.parse(charset: utf8.name);
  }
}
