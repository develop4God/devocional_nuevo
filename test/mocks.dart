import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';

// This will generate mock files using mockito's build_runner
@GenerateMocks([
  DevocionalProvider,
  LocalizationProvider,
  http.Client,
])
void main() {}
