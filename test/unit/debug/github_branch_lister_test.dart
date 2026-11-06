@Tags(['unit', 'debug'])
library;

import 'dart:convert';

import 'package:devocional_nuevo/debug/github_branch_lister.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(GithubBranchLister.clearSessionCache);

  final now = DateTime.utc(2026, 11, 4);
  String commit(DateTime d) => jsonEncode({
        'commit': {
          'commit': {
            'committer': {'date': d.toIso8601String()},
          },
        },
      });

  GithubBranchLister build(Map<String, http.Response> routes) =>
      GithubBranchLister(
        now: () => now,
        client: MockClient((req) async =>
            routes[req.url.path.split('/repos/develop4God/').last] ??
            http.Response('', 404)),
      );

  final list = http.Response(
      jsonEncode([
        {'name': 'main'},
        {'name': 'fresh'},
        {'name': 'stale'},
        {'name': 'broken'},
      ]),
      200);

  test('keeps main, recent and unreadable branches; drops stale ones',
      () async {
    final lister = build({
      'r/branches': list,
      'r/branches/fresh':
          http.Response(commit(now.subtract(const Duration(days: 5))), 200),
      'r/branches/stale':
          http.Response(commit(now.subtract(const Duration(days: 200))), 200),
    });

    final result =
        await lister.fetch('r', activeWithin: const Duration(days: 90));

    expect(result.branches, ['main', 'fresh', 'broken']);
    expect(result.warning, contains('1 branch'));
  });

  test('without activeWithin returns every branch', () async {
    final result = await build({'r/branches': list}).fetch('r');
    expect(result.branches, ['main', 'fresh', 'stale', 'broken']);
    expect(result.warning, isNull);
  });

  test('falls back to main when every branch is stale and main is absent',
      () async {
    final lister = build({
      'r/branches': http.Response(
          jsonEncode([
            {'name': 'old'}
          ]),
          200),
      'r/branches/old':
          http.Response(commit(now.subtract(const Duration(days: 200))), 200),
    });

    final result =
        await lister.fetch('r', activeWithin: const Duration(days: 90));

    expect(result.branches, ['main']);
  });

  test('returns null on API error (e.g. rate limit)', () async {
    final result = await build({'r/branches': http.Response('', 403)})
        .fetch('r', activeWithin: const Duration(days: 90));
    expect(result.branches, isNull);
    expect(result.warning, contains('rate limit'));
  });

  test('keeps a branch whose author date is recent despite an old committer',
      () async {
    final lister = build({
      'r/branches': http.Response(
          jsonEncode([
            {'name': 'rebased'}
          ]),
          200),
      'r/branches/rebased': http.Response(
          jsonEncode({
            'commit': {
              'commit': {
                'committer': {
                  'date':
                      now.subtract(const Duration(days: 300)).toIso8601String()
                },
                'author': {
                  'date':
                      now.subtract(const Duration(days: 2)).toIso8601String()
                },
              },
            },
          }),
          200),
    });

    final result =
        await lister.fetch('r', activeWithin: const Duration(days: 90));

    expect(result.branches, ['rebased']);
  });

  test('reports a warning when the response has an unexpected shape', () async {
    final result = await build({
      'r/branches': http.Response(jsonEncode({'message': 'oops'}), 200),
    }).fetch('r');

    expect(result.branches, isNull);
    expect(result.warning, contains('Unexpected GitHub response'));
  });

  test('complete listings are cached for the session; forceRefresh bypasses',
      () async {
    var calls = 0;
    final lister = GithubBranchLister(
      now: () => now,
      client: MockClient((req) async {
        calls++;
        return list;
      }),
    );

    await lister.fetch('r');
    await lister.fetch('r');
    expect(calls, 1);

    await lister.fetch('r', forceRefresh: true);
    expect(calls, 2);
  });

  test('failed listings are not cached', () async {
    var calls = 0;
    final lister = GithubBranchLister(
      now: () => now,
      client: MockClient((req) async {
        calls++;
        return http.Response('', 403);
      }),
    );

    await lister.fetch('r');
    await lister.fetch('r');

    expect(calls, 2);
  });
}
