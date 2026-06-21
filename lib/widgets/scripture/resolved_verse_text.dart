import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResolvedVerseText extends StatefulWidget {
  final String reference;
  final String fallbackText;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool quoted;

  const ResolvedVerseText({
    required this.reference,
    required this.fallbackText,
    this.style,
    this.textAlign,
    this.quoted = false,
    super.key,
  });

  @override
  State<ResolvedVerseText> createState() => _ResolvedVerseTextState();
}

class _ResolvedVerseTextState extends State<ResolvedVerseText> {
  String? _resolvedText;

  @override
  void initState() {
    super.initState();
    _resolveAsync();
  }

  Future<void> _resolveAsync() async {
    final versionCode = context.read<DevocionalProvider>().selectedVersion;
    final resolver = getService<IVerseResolverService>();
    final result = await resolver.resolveVerseText(
      reference: widget.reference,
      versionCode: versionCode,
    );
    if (mounted && result != null && result.isNotEmpty) {
      setState(() => _resolvedText = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _resolvedText ?? widget.fallbackText;
    return Text(
      widget.quoted ? '"$displayText"' : displayText,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
