// test/unit/pages/lottie_hang_test.dart
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

const _emptyLottieJson =
    '{"v":"5.5.7","fr":30,"ip":0,"op":2,"w":1,"h":1,"layers":[]}';

class _TestBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('.json')) {
      final bytes = utf8.encode(_emptyLottieJson);
      return ByteData.view(Uint8List.fromList(bytes).buffer);
    }
    return rootBundle.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key.endsWith('.json')) return _emptyLottieJson;
    return rootBundle.loadString(key, cache: cache);
  }
}

void main() {
  testWidgets('Lottie + AnimationController.forward() does not hang',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultAssetBundle(
          bundle: _TestBundle(),
          child: const _TestPage(),
        ),
      ),
    );
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

class _TestPage extends StatefulWidget {
  const _TestPage();

  @override
  State<_TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<_TestPage> with TickerProviderStateMixin {
  late AnimationController _headerCtrl;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Lottie.asset('assets/lottie/hands_heart.json', height: 50),
          Lottie.asset('assets/lottie/coffee_enter.json', height: 50),
          Lottie.asset('assets/lottie/plant.json', height: 50),
          Lottie.asset('assets/lottie/hearts_love.json', height: 50),
        ],
      ),
    );
  }
}
