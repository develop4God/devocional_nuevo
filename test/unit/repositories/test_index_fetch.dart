@Tags(['unit', 'repositories'])
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() async {
  final url =
      'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/discovery/index.json';

  debugPrint('Fetching: $url');
  final response = await http.get(Uri.parse(url));

  debugPrint('Status: \\${response.statusCode}');
  debugPrint('Body length: \\${response.body.length}');
  debugPrint('First 1000 chars:');
  debugPrint(response.body
      .substring(0, response.body.length < 1000 ? response.body.length : 1000));
  debugPrint('\n---\n');

  final json = jsonDecode(response.body);
  debugPrint('JSON type: \\${json.runtimeType}');
  debugPrint('JSON keys: \\${json.keys}');
  debugPrint('\nFull JSON:');
  debugPrint(const JsonEncoder.withIndent('  ').convert(json));
}
