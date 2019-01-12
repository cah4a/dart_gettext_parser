## Parse Mo Files:

```dart
import 'package:gettext_parser/gettext_parser.dart' as gettextParser;

Map translateTable = gettextParser.mo.parse(
    file.readAsBytesSync(),
);

// with custom encoding
Map translateTable = gettextParser.mo.parse(
    file.readAsBytesSync(),
    encoding: latin1,
);
```

## Parse Po Files:

```dart
import 'package:gettext_parser/gettext_parser.dart' as gettextParser;

Map translateTable = gettextParser.mo.parse(
    file.readAsStringSync()
);

// with custom encoding
Map translateTable = gettextParser.mo.parseRaw(
    file.readAsBytesSync(),
    encoding: latin1,
);
```