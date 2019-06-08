library gettext_parser;

import 'dart:convert';
import 'dart:typed_data';

import './src/mo/parser.dart';
import './src/mo/compiler.dart';
import './src/po/parser.dart';
import './src/po/compiler.dart';

const mo = const _Mo();
const po = const _Po();

class _Mo {
  const _Mo();

  /// Parse mo file data with encoding
  Map<String, dynamic> parse(ByteData data, {Encoding encoding: utf8}) {
    final parser = MoParser(data, encoding: encoding);
    return parser.parse();
  }

  /// Parse mo file data with encoding
  Map<String, dynamic> parseBytes(List<int> data, {Encoding encoding: utf8}) {
    final parser = MoParser(
      ByteData.view(Uint8List.fromList(data).buffer),
      encoding: encoding,
    );

    return parser.parse();
  }

  /// Converts [table] to a binary MO object
  Uint8List compile(Map table) {
    final compiler = MoCompiler(table);
    return compiler.compile();
  }
}

class _Po {
  const _Po();

  /// Parse po data file with encoding
  Map<String, dynamic> parseBytes(List<int> data, {Encoding encoding: utf8}) {
    final parser = PoParser(encoding.decode(data));
    return parser.parse(charset: encoding.name);
  }

  /// Parse po file string
  Map<String, dynamic> parse(String text) {
    final parser = PoParser(text);
    return parser.parse(charset: utf8.name);
  }

  /// Converts [table] to a PO object
  String compile(Map table) {
    final compiler = PoCompiler(table);
    return compiler.compile();
  }
}
