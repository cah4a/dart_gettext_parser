/// Parses a header string into an object of key-value pairs
Map<String, String> parseHeader({String headersStr = ''}) {
  final List<String> lines = headersStr.split('\n');
  final Map<String, String> headers = {};

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