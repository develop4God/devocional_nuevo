import 'dart:convert';

import 'package:http/http.dart' as http;

void main() async {
  final url =
      'https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/discovery/index.json';

  print('Fetching: $url');
  final response = await http.get(Uri.parse(url));

  print('Status: ${response.statusCode}');
  print('Body length: ${response.body.length}');
  print('First 1000 chars:');
  print(response.body
      .substring(0, response.body.length < 1000 ? response.body.length : 1000));
  print('\n---\n');

  final json = jsonDecode(response.body);
  print('JSON type: ${json.runtimeType}');
  print('JSON keys: ${json.keys}');
  print('\nFull JSON:');
  print(const JsonEncoder.withIndent('  ').convert(json));
}
