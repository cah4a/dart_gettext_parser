# Dart gettext mo/po parser

Parse and compile gettext po and mo files with dart.
Ported [gettext-parser](https://github.com/smhg/gettext-parser) npm package to dartlang.

## Usage

Add dependency to `pubspec.yaml`
```
dependencies:
    gettext_parser: any
```

Import library:
```dart
import 'package:gettext_parser/gettext_parser.dart' as gettextParser;
```

### Parse .po files:
```dart
Map translateTable = gettextParser.po.parse(
    file.readAsStringSync(),
);
```

### Parse .mo files:
```dart
Map translateTable = gettextParser.mo.parse(
    file.readAsBytesSync(),
);
```

### Compile .po files:
```dart
String data = gettextParser.po.compile(
    translateTable,
);
```

### Compile .mo files:
```dart
UInt8List data = gettextParser.mo.compile(
    translateTable,
);
```

## Encoding
`gettext_parser` use `Encoding` interface for encoding and decoding charsets from `dart:convert` package with utf8, base64, latin1 built-in encoders.
If you need other encoding you could implement `Encoding` interface by your own.

Example:
```
gettextParser.mo.parse(buffer, encoding: latin1);
gettextParser.po.parse(buffer, encoding: latin1);
```

## Data structure of parsed mo/po files

### Character set

Parsed data is always in unicode but the original charset of the file can
be found from the `charset` property.

### Headers

Headers can be found from the `headers` object, all keys are lowercase and the value for a key is a string. This value will also be used when compiling.

### Translations

Translations can be found from the `translations` object which in turn holds context objects for `msgctxt`. Default context can be found from `translations[""]`.

Context objects include all the translations, where `msgid` value is the key. The value is an object with the following possible properties:

  * **msgctxt** context for this translation, if not present the default context applies
  * **msgid** string to be translated
  * **msgid_plural** the plural form of the original string (might not be present)
  * **msgstr** an array of translations
  * **comments** an object with the following properties: `translator`, `reference`, `extracted`, `flag`, `previous`.

Example

```json
{
  "charset": "iso-8859-1",

  "headers": {
    "content-type": "text/plain; charset=iso-8859-1",
    "plural-forms": "nplurals=2; plural=(n!=1);"
  },

  "translations": {
    "": {
      "": {
        "msgid": "",
        "msgstr": ["Content-Type: text/plain; charset=iso-8859-1\n..."]
      }
    },
    "another context": {
      "%s example": {
        "msgctxt": "another context",
        "msgid": "%s example",
        "msgid_plural": "%s examples",
        "msgstr": ["% näide", "%s näidet"],
        "comments": {
          "translator": "This is regular comment",
          "reference": "/path/to/file:123"
        }
      }
    }
  }
}
```

Notice that the structure has both a `headers` object and a `""` translation with the header string.
When compiling the structure to a *mo* or a *po* file, the `headers` object is used to define the header.
Header string in the `""` translation is just for reference (includes the original unmodified data) but
will not be used when compiling. So if you need to add or alter header values, use only the `headers` object.

## License

**MIT**