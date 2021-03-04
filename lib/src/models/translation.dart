import 'dart:typed_data';
import 'dart:convert';
import '../utils/generate_header.dart';

abstract class TranslationInterface {
  late ByteBuffer msgid, msgstr;
}

class Translation extends TranslationInterface {
  Translation(String key, String value) {
    final List encodedKeyList = utf8.encode(key);
    final List encodedValueList = utf8.encode(value);

    this.msgid = Uint8List.fromList(encodedKeyList as List<int>).buffer;
    this.msgstr = Uint8List.fromList(encodedValueList as List<int>).buffer;
  }
}

class HeaderTranslation extends TranslationInterface {
  HeaderTranslation(Map headers) {
    final String headersString = generateHeader(headers);
    final List encodedHeaderList = utf8.encode(headersString);

    this.msgid = Uint8List(0).buffer;
    this.msgstr = Uint8List.fromList(encodedHeaderList as List<int>).buffer;
  }
}
