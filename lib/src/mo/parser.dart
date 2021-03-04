import 'dart:convert';
import 'dart:typed_data';

import '../utils/parse_header.dart';
import '../models/table.dart';

/// Parser class
/// Contains decoding and parse logic for passed List<int>
class MoParser {
  // Magic constant to check the endianness of the input file
  static const _MAGIC = 0x950412de;
  final Encoding encoding;

  // Default endian for read/write
  Endian _endian = Endian.little;
  final ByteData _fileContents;
  late Table _table;

  MoParser(this._fileContents, {required this.encoding}) {
    this._table = Table.fromCharset(charset: this.encoding.name);
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
  void _loadTranslationTable({
    required int offsetOriginals,
    required int offsetTranslations,
    required int total,
    int? revision,
  }) {
    int position, length;
    String msgid, msgstr;
    Iterable msgidRange, msgstrRange;

    for (int i = 0; i < total; i++) {
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
        this._handleHeaders(msgstrRange);
      }

      // dart:convert support limited quantity of charsets
      // https://api.dartlang.org/dev/2.1.1-dev.0.1/dart-convert/dart-convert-library.html
      //
      // More about issue
      // https://stackoverflow.com/questions/21142985/convert-a-string-from-iso-8859-2-to-utf-8-in-the-dart-language
      // https://stackoverflow.com/questions/51148729/how-to-manually-convert-between-latin-5-and-unicode-code-points
      msgid = encoding.decode(msgidRange.toList() as List<int>);
      msgstr = encoding.decode(msgstrRange.toList() as List<int>);

      this._table.addString(msgid, msgstr);
    }
  }

  void _handleHeaders(Iterable headers) {
    String headersParsed = encoding.decode(headers.toList() as List<int>);

    this._table.headers = parseHeader(headersStr: headersParsed);
  }

  /// Parses the MO object and returns translation table
  Map<String, dynamic> parse() {
    if (!this._checkMagick()) {
      throw FormatException("Wrong gettext format");
    }

    // order is important
    final revision = this._fileContents.getUint32(4, this._endian);
    final total = this._fileContents.getUint32(8, this._endian);
    final offsetOriginals = this._fileContents.getUint32(12, this._endian);
    final offsetTranslations = this._fileContents.getUint32(16, this._endian);

    this._loadTranslationTable(
      revision: revision,
      total: total,
      offsetOriginals: offsetOriginals,
      offsetTranslations: offsetTranslations,
    );

    return this._table.toMap;
  }
}
