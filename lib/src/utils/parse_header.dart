/// Parses a header string into an object of key-value pairs
Map parseHeader({String headersStr = ''}) {
  final List<String> lines = headersStr.split('\n');
  final Map headers = {};

  lines.forEach((line) {
    final List<String> parts = line.trim().split(':');
    final String key = parts.first.trim().toLowerCase();
    parts.removeAt(0);
    final String value = parts.join(':').trim();

    if (key.isEmpty) {
      return;
    }

    headers[key] = value;
  });

  return headers;
}