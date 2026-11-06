import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Text whose http(s) URLs are underlined and open in the external browser
/// on tap. Everything else renders as plain text with [style].
class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  /// Opens a tapped URL. Defaults to the external browser; injectable so
  /// tests do not need the url_launcher platform channel.
  final Future<void> Function(Uri uri)? onOpenUrl;

  const LinkifiedText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.onOpenUrl,
  });

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

/// A slice of the text; [recognizer] is set only for URL slices.
class _Segment {
  final String text;
  final TapGestureRecognizer? recognizer;

  const _Segment(this.text, [this.recognizer]);
}

class _LinkifiedTextState extends State<LinkifiedText> {
  static final _urlPattern = RegExp(r'''https?://[^\s"'<>]+''');
  static const _closers = {')': '(', ']': '[', '}': '{'};
  static const _sentencePunctuation = '.,;:!?';

  /// Built once per text so recognizers survive rebuilds (theme changes)
  /// and are only disposed when the text changes or the widget goes away.
  List<_Segment> _segments = const [];

  @override
  void initState() {
    super.initState();
    _segments = _parse(widget.text);
  }

  @override
  void didUpdateWidget(LinkifiedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _disposeRecognizers();
      _segments = _parse(widget.text);
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final segment in _segments) {
      segment.recognizer?.dispose();
    }
  }

  Future<void> _open(String url) async {
    try {
      final uri = Uri.parse(url);
      final opener = widget.onOpenUrl;
      if (opener != null) return await opener(uri);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('LinkifiedText: no handler for $url');
      }
    } catch (e) {
      debugPrint('LinkifiedText: could not open $url: $e');
    }
  }

  /// Drops trailing sentence punctuation and closing brackets that have no
  /// opener inside the URL, so `(see https://a.com/x)` excludes the `)` while
  /// `https://en.wikipedia.org/wiki/Foo_(bar)` keeps it.
  static String _trimUrl(String url) {
    var end = url.length;
    while (end > 0) {
      final last = url[end - 1];
      final opener = _closers[last];
      if (_sentencePunctuation.contains(last)) {
        end--;
      } else if (opener != null) {
        final body = url.substring(0, end - 1);
        // Unbalanced: this closer has no opener left to pair with.
        if (_count(body, opener) <= _count(body, last)) {
          end--;
        } else {
          break;
        }
      } else {
        break;
      }
    }
    return url.substring(0, end);
  }

  static int _count(String text, String char) => char.allMatches(text).length;

  List<_Segment> _parse(String text) {
    final segments = <_Segment>[];
    var cursor = 0;
    for (final match in _urlPattern.allMatches(text)) {
      final url = _trimUrl(match.group(0)!);
      if (url.isEmpty) continue;
      if (match.start > cursor) {
        segments.add(_Segment(text.substring(cursor, match.start)));
      }
      segments.add(
        _Segment(url, TapGestureRecognizer()..onTap = () => _open(url)),
      );
      cursor = match.start + url.length;
    }
    if (cursor < text.length) segments.add(_Segment(text.substring(cursor)));
    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          for (final segment in _segments)
            TextSpan(
              text: segment.text,
              style: segment.recognizer == null ? null : linkStyle,
              recognizer: segment.recognizer,
            ),
        ],
      ),
      textAlign: widget.textAlign,
    );
  }
}
