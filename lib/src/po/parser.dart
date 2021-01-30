class PoParser {
  final String data;

  PoParser(this.data);

  Map<String, dynamic> parse({String charset}) {
    final nodes = data.split(RegExp(r'\r?\n')).map(Node.parse).fold(
      new List<Node>(),
      _combine,
    );

    final list = nodes.fold(
      new List<Map<String, dynamic>>(),
          (List<Map<String, dynamic>> result, node) {
        if (result.isEmpty || node is BlockEnd) {
          result.add(new Map<String, dynamic>());
        }

        final item = result.last;

        if (node is Comment) {
          if (item["comments"] == null) {
            item["comments"] = Map<String, String>();
          }

          item["comments"][node.type] = node.text;
        }

        if (node is Token) {
          if (node.type == "msgstr") {
            if (!item.containsKey(node.type)) {
              item[node.type] = new List<String>();
            }

            (item[node.type] as List).add(node.text);
          } else {
            item[node.type] = node.text;
          }
        }

        return result;
      },
    );

    final headers = new Map<String, String>();

    final head = list.firstWhere(
          (item) => item["msgid"] == "",
      orElse: () => null,
    );

    if (head != null && head["msgstr"] != null) {
      final String comments = head["msgstr"].join("");
      headers.addEntries(comments
          .split("\n")
          .where(
            (line) => line.contains(": "),
      )
          .map((line) {
        final delim = line.indexOf(": ");
        final key = line.substring(0, delim).toLowerCase();
        return MapEntry(key, line.substring(delim + 2));
      }));
    }

    final translations = new Map<String, Map<String, dynamic>>();

    list.forEach(
          (item) {
        final ctx = item["msgctxt"] ?? "";
        final id = item["msgid"] ?? "";

        if (!translations.containsKey(ctx)) {
          translations[ctx] = new Map<String, dynamic>();
        }

        translations[ctx][id] = item;
      },
    );

    return {
      "charset": charset,
      "headers": headers,
      "translations": translations,
    };
  }

  List<Node> _combine(List<Node> nodes, Node node) {
    if (nodes.isEmpty || !nodes.last.combine(node)) {
      nodes.add(node);
    }

    return nodes;
  }
}

class Node {
  bool combine(Node other) => false;

  static Node parse(String line) {
    if (line == "") {
      return new BlockEnd();
    }

    if (line[0] == "#") {
      return new Comment(line.substring(1).trim());
    }

    if (line.startsWith("msg")) {
      return new Token(line);
    }

    if (line.startsWith('"')) {
      return new StrLine(line);
    }

    throw new FormatException();
  }
}

class Comment extends Node {
  String text;
  String type;

  Comment(String text) : assert(text != null) {
    if (text.length >= 2 && text[1] == " ") {
      switch (text[0]) {
        case ":":
          this.type = "reference";
          this.text = text.substring(2);
          return;
        case ".":
          this.type = "extracted";
          this.text = text.substring(2);
          return;
        case ",":
          this.type = "flag";
          this.text = text.substring(2);
          return;
        case "|":
          this.type = "previous";
          this.text = text.substring(2);
          return;
      }
    }

    this.type = "translator";
    this.text = text;
  }

  @override
  bool combine(Node other) {
    if (other is Comment && other.type == type) {
      this.text += "\n" + other.text;
      return true;
    }

    return false;
  }
}

class Token extends Node {
  String type;
  String text;
  int index = 0;

  Token(String line) {
    final pos = line.indexOf(" ");
    this.type = line.substring(0, pos);

    if (type.contains("[")) {
      index =
          int.parse(type.substring(type.indexOf("[") + 1, type.indexOf("]")));
      type = type.substring(0, type.indexOf("["));
    }

    this.text = _unescape(line.substring(pos + 1).trim());
  }

  @override
  bool combine(Node other) {
    if (other is StrLine) {
      this.text += other.text;
      return true;
    }

    return false;
  }
}

class StrLine extends Node {
  final String text;

  StrLine(String text) : this.text = _unescape(text);
}

class BlockEnd extends Node {}

const escape = '"';

String _unescape(String text) {
  if (!text.startsWith(escape) && text.endsWith(escape)) {
    return text;
  }

  text = text.substring(1, text.length - 1);

  return text
      .replaceAll('\\n', "\n")
      .replaceAll("\\'", "\'")
      .replaceAll('\\"', '\"')
      .replaceAll('\\t', "\t");
}
