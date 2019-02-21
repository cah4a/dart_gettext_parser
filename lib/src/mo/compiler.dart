import 'dart:typed_data';
import 'dart:convert';
import '../models/table.dart';
import '../models/translation.dart';
import '../models/sizeOfData.dart';

/// Creates a MO compiler object.
class MoCompiler {
  Table _table;
  Endian _endian = Endian.little;

  // Magic bytes for the generated binary data
  static const _MAGIC = 0x950412de;

  MoCompiler(Map table) {
    _table = Table(table);
  }

  List<int> compile () {
    final List<TranslationInterface> list = _generateList();
    final SizeOfData size = SizeOfData(list);

    // sort by msgid
    list.sort((a, b) => utf8.decode(a.msgid.asUint8List()).compareTo(utf8.decode(b.msgid.asUint8List())));

    return this._build(list, size);
  }

  // Generates an List of translation strings
  // in the form of [TranslationInterface, ...]
  List<TranslationInterface> _generateList () {
    List<TranslationInterface> list = [];

    list.add(HeaderTranslation(this._table.headers));

    this._table.translations.keys.forEach((msgctxt) {
      if (this._table.translations[msgctxt] is! Map) {
        return;
      }

      this._table.translations[msgctxt].keys.forEach((String msgid) {
        if (this._table.translations[msgctxt][msgid] is! Map) {
          return;
        }
        if (msgctxt == '' && msgid == '') {
          return;
        }

        String msgidPlural = this._table.translations[msgctxt][msgid]['msgid_plural'];
        String key = msgid;
        String value;
        List msgstr = this._table.translations[msgctxt][msgid]['msgstr'] ?? [];

        if (msgctxt.toString().isNotEmpty) {
          key = '${msgctxt}\u0004${key}';
        }

        if (msgidPlural != null && msgidPlural.toString().isNotEmpty) {
          key += '\u0000${msgidPlural}';
        }

        value = msgstr.join('\u0000');

        list.add(Translation(key, value));
      });
    });

    return list;
  }

  List<int> _build (List<TranslationInterface> list, SizeOfData size) {
    ByteData returnBuffer = ByteData.view(Uint8List(size.total).buffer);
    int currentPosition = 0;

    // magic
    returnBuffer.setUint32(0, _MAGIC, _endian);

    // revision
    returnBuffer.setUint32(4, 0, _endian);

    // string count
    returnBuffer.setUint32(8, list.length, _endian);

    // original string table offset
    returnBuffer.setUint32(12, 28, _endian);

    // translation string table offset
    returnBuffer.setUint32(16, 28 + (4 + 4)*list.length, _endian);

    // hash table size
    returnBuffer.setUint32(20, 0, _endian);

    // hash table offset
    returnBuffer.setUint32(24, 28 + (4 + 4)*list.length*2, _endian);

    // build originals table
    currentPosition = 28 + 2*(4 + 4)*list.length;
    for (int i = 0, len = list.length; i < len; i++) {
      final Uint8List copy = list[i].msgid.asUint8List();

      returnBuffer.buffer.asUint8List().setRange(currentPosition, currentPosition + copy.length, copy);

      returnBuffer.setUint32(28 + i*8, copy.length, _endian);
      returnBuffer.setUint32(28 + i*8 + 4, currentPosition, _endian);
      returnBuffer.setUint8(currentPosition + copy.length, 0x00);

      currentPosition += copy.length + 1;
    }

    // build translation table
    for (int i = 0, len = list.length; i < len; i++) {
      final Uint8List copy = list[i].msgstr.asUint8List();

      returnBuffer.buffer.asUint8List().setRange(currentPosition, currentPosition + copy.length, copy);

      returnBuffer.setUint32(28 + (4 + 4)*list.length + i*8, copy.length, _endian);
      returnBuffer.setUint32(28 + (4 + 4)*list.length + i*8 + 4, currentPosition, _endian);
      returnBuffer.setUint8(currentPosition + copy.length, 0x00);

      currentPosition += copy.length + 1;
    }

    return returnBuffer.buffer.asUint8List();
  }
}