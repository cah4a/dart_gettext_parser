import 'dart:convert';
import 'dart:typed_data';

import '../utils/parse_header.dart';

/// Parser class
/// Contains decoding and parse logic for passed List<int>
class MoParser {
  // Magic constant to check the endianness of the input file
  static const _MAGIC = 0x950412de;
  Encoding encoding;

  // Default endian for read/write
  Endian _endian = Endian.little;
  ByteData _fileContents;
  Map _table;

  // Offset position for original strings table
  int _offsetOriginals;

  // Offset position for translation strings table
  int _offsetTranslations;

  // GetText revision nr, usually 0
  int _revision;

  // Total count of translated strings
  int _total;

  MoParser(List<int> fileContent, {Encoding encoding}) {
    this.encoding = encoding ?? utf8;
    this._fileContents = ByteData.view(Uint8List.fromList(fileContent).buffer);

    this._table = {
      'charset': encoding.name,
      'headers': null,
      'translations': {},
    };
  }

  // Checks if number values in the input file are in big- or littleendian format.
  bool _checkMagick() {
    if (this._fileContents.getUint32(0, Endian.little) == MoParser._MAGIC) {
      this._endian = Endian.little;
      return true;
    } else if (this._fileContents.getUint32(0, Endian.big) == MoParser._MAGIC) {
      this._endian = Endian.big;
      return true;
    } else {
      return false;
    }
  }

  // Read the original strings and translations from the input MO file. Use the
  // first translation string in the file as the header.
  void _loadTranslationTable() {
    int offsetOriginals = this._offsetOriginals;
    int offsetTranslations = this._offsetTranslations;
    int position, length;
    String msgid, msgstr;
    Iterable msgidRange, msgstrRange;

    for (int i = 0; i < this._total; i++) {
      // msgid string
      length = this._fileContents.getUint32(offsetOriginals, this._endian);
      offsetOriginals += 4;
      position = this._fileContents.getUint32(offsetOriginals, this._endian);
      offsetOriginals += 4;
      msgidRange = this
          ._fileContents
          .buffer
          .asUint8List()
          .getRange(position, position + length);

      // matching msgstr
      length = this._fileContents.getUint32(offsetTranslations, this._endian);
      offsetTranslations += 4;
      position = this._fileContents.getUint32(offsetTranslations, this._endian);
      offsetTranslations += 4;
      msgstrRange = this
          ._fileContents
          .buffer
          .asUint8List()
          .getRange(position, position + length);

      if (i == 0 && msgidRange.toList().isEmpty) {
        this._handleCharset(msgstrRange);
      }

      /**
       * dart:convert support limited quantity of charsets
       * https://api.dartlang.org/dev/2.1.1-dev.0.1/dart-convert/dart-convert-library.html
       *
       * More about issue
       * https://stackoverflow.com/questions/21142985/convert-a-string-from-iso-8859-2-to-utf-8-in-the-dart-language
       * https://stackoverflow.com/questions/51148729/how-to-manually-convert-between-latin-5-and-unicode-code-points
       */
      msgid = encoding.decode(msgidRange.toList());
      msgstr = encoding.decode(msgstrRange.toList());

      this._addString(msgid, msgstr);
    }

    // dump the file contents object
    this._fileContents = null;
  }

  void _handleCharset(Iterable headers) {
    String headersParsed = encoding.decode(headers.toList());

    this._table['headers'] = parseHeader(headersStr: headersParsed);
  }

  void _addString(dynamic msgid, dynamic msgstr) {
    final Map translation = {};
    List<String> parts;
    String msgctxt, msgidPlural;

    msgid = msgid.split('\u0004');
    if (msgid.length > 1) {
      msgctxt = msgid.first;
      msgid.removeAt(0);
      translation['msgctxt'] = msgctxt;
    } else {
      msgctxt = '';
    }
    msgid = msgid.join('\u0004');

    parts = msgid.split('\u0000');
    msgid = parts.first;
    parts.removeAt(0);

    translation['msgid'] = msgid;
    msgidPlural = parts.join('\u0000');

    if (!msgidPlural.isEmpty) {
      translation['msgid_plural'] = msgidPlural;
    }

    msgstr = msgstr.split('\u0000');
    translation['msgstr'] = msgstr;

    if (!this._table['translations'].containsKey(msgctxt)) {
      this._table['translations'][msgctxt] = {};
    }

    this._table['translations'][msgctxt][msgid] = translation;
  }

  /// Parses the MO object and returns translation table
  Map parse() {
    if (!this._checkMagick()) {
      return null;
    }

    this._revision = this._fileContents.getUint32(4, this._endian);
    this._total = this._fileContents.getUint32(8, this._endian);
    this._offsetOriginals = this._fileContents.getUint32(12, this._endian);
    this._offsetTranslations = this._fileContents.getUint32(16, this._endian);

    this._loadTranslationTable();

    return this._table;
  }
}
