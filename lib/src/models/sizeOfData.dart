import './translation.dart';

class SizeOfData {
  int msgid;
  int msgstr;
  int total;

  SizeOfData(List<TranslationInterface> list) {
    int msgidLength = 0,
      msgstrLength = 0,
      totalLength = 0;

    list.forEach((TranslationInterface translation) {
      msgidLength += translation.msgid.lengthInBytes + 1; // + extra 0x00
      msgstrLength += translation.msgstr.lengthInBytes + 1; // + extra 0x00
    });

    totalLength = 4 + // magic number
          4 + // revision
          4 + // string count
          4 + // original string table offset
          4 + // translation string table offset
          4 + // hash table size
          4 + // hash table offset
          (4 + 4) * list.length + // original string table
          (4 + 4) * list.length + // translations string table
          msgidLength + // originals
          msgstrLength; // translations

    this.msgid = msgidLength;
    this.msgstr = msgstrLength;
    this.total = totalLength;
  }
}