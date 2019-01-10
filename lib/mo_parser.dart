library mo_parser;

import './src/parser.dart';
export './src/parser.dart';

/// Parse *.mo file to Map object
Map parser (List<int> buffer) {
  Parser parser = new Parser(buffer);
  return parser.parse();
}