import 'package:gettext_parser/src/models/table.dart';
import 'package:gettext_parser/src/utils/fold_line.dart';
import 'package:gettext_parser/src/utils/generate_header.dart';

const _commentTypes = {
  "translator": "# ",
  "reference": "#: ",
  "extracted": "#. ",
  "flag": "#, ",
  "previous": "#| ",
};

final _lineBreak = RegExp(r'\r?\n|\r');

class PoCompiler {
  final int foldLength;
  final Table table;

  PoCompiler(Map source, {this.foldLength = 76}) : table = Table(source);

  String compile() {
    final blocks = <StringBuffer>[];

    if (table.translations[""] != null && table.translations[""]![""] != null) {
      blocks.add(_drawBlock(
        table.translations[""]![""],
        msgstr: [generateHeader(table.headers)],
      ));
    }

    table.translations.forEach((msgctx, messages) {
      if (msgctx == "") {
        messages = Map.of(messages)..remove("");
      }

      blocks.addAll(
        messages.values
            .where((block) => block is Map)
            .cast<Map>()
            .map(_drawBlock),
      );
    });

    return blocks.join("\n\n");
  }

  StringBuffer _drawBlock(Map block, {List<String>? msgstr}) {
    assert(block["msgstr"] == null || block["msgstr"] is List);
    final messages = List<String>.from(msgstr ?? block["msgstr"]);

    final iterables = [
      _drawComments(block["comments"] ?? {}),
      _addPOString('msgctxt', block["msgctxt"]),
      _addPOString('msgid', block["msgid"] ?? ""),
    ];

    if (block["msgid_plural"] is String) {
      iterables.add(_addPOString('msgid_plural', block["msgid_plural"]));

      iterables.add(
        Iterable.generate(
          messages.length,
          (index) => _addPOString("msgstr[$index]", messages[index]),
        ).expand((val) => val),
      );
    } else {
      iterables
          .add(_addPOString('msgstr', messages.isEmpty ? "" : messages.first));
    }

    return StringBuffer()
      ..writeAll(
        _IterableZip(iterables),
        "\n",
      );
  }

  Iterable<String> _addPOString(String key, value) {
    if (value == null) {
      return Iterable.empty();
    }

    value = value
        .toString()
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll("\t", r'\t')
        .replaceAll("\r", r'\r')
        .replaceAll("\n", r'\n');

    final lines = foldLine(value);

    if (lines.length < 2) {
      return ['$key "${lines.first}"'];
    } else {
      return ['$key ""'].followedBy(lines.map((line) => '"$line"'));
    }
  }

  Iterable<String> _drawComments(Map comments) {
    return _commentTypes.entries.expand((entry) {
      final key = entry.key;
      final prefix = entry.value;

      assert(comments[key] == null || comments[key] is String);
      final String comment = comments[key] ?? "";

      if (comment.isEmpty) {
        return Iterable<String>.empty();
      }

      return comment.split(_lineBreak).map((line) => prefix + line);
    });
  }
}

class _IterableZip<T> extends Iterable<T?> {
  final Iterable<Iterable<T>> iterables;

  _IterableZip(this.iterables);

  Iterator<T?> get iterator {
    if (iterables.isEmpty) {
      return Iterable.empty().iterator as Iterator<T?>;
    }

    return _ZipIterator<T>(iterables.iterator);
  }
}

class _ZipIterator<T> extends Iterator<T?> {
  final Iterator<Iterable<T>> _outer;

  Iterator<T>? _inner;

  _ZipIterator(this._outer);

  @override
  T? get current => _inner?.current;

  @override
  bool moveNext() {
    if (_inner != null && _inner!.moveNext()) {
      return true;
    }

    while (_outer.moveNext()) {
      _inner = _outer.current.iterator;

      if (_inner!.moveNext()) {
        return true;
      }
    }

    return false;
  }
}
