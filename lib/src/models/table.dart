class Table {
  Map<String, String> headers = {};
  Map<String, Map<String, dynamic>> translations = {};
  String charset = "";
  String contentType = 'utf-8';

  Table(Map table) {
    assert(table["headers"] is Map &&
        table["headers"].values.every((value) => value is String));
    assert(table['translations'] is Map &&
        table['translations'].values.every((value) => value is Map));

    headers = Map.castFrom(table["headers"]);
    translations = Map.castFrom(table['translations']);

    _handleCharset(table);
  }

  Table.fromCharset({String charset = 'utf-8'}) {
    this.charset = charset;
  }

  // Handles header values, replaces or adds (if needed) a charset property
  void _handleCharset(Map table) {
    final List<String> parts =
        (headers['content-type'] ?? 'text/plain').split(';');
    final String contentType = parts.first;
    parts.removeAt(0);
    // Support only utf-8 encoding
    final String charset = 'utf-8';

    final Iterable params = parts.map((part) {
      final List<String> parts = part.split('=');
      final String key = parts.first.trim();

      if (key.toLowerCase() == 'charset') {
        return 'charset=${charset}';
      }

      return part;
    });

    this.charset = charset;
    this.headers['content-type'] = '${contentType}; ${params.join('; ')}';
  }

  void addString(dynamic msgid, dynamic msgstr) {
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

    if (msgidPlural.isNotEmpty) {
      translation['msgid_plural'] = msgidPlural;
    }

    msgstr = msgstr.split('\u0000');
    translation['msgstr'] = msgstr;

    if (!this.translations.containsKey(msgctxt)) {
      this.translations[msgctxt] = {};
    }

    this.translations[msgctxt][msgid] = translation;
  }

  get toMap {
    return {
      'charset': this.charset,
      'headers': this.headers,
      'translations': this.translations,
    };
  }
}
