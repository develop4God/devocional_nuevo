import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Outcome of a branch listing. [branches] is null when the listing failed
/// entirely; [warning] explains a failure or a partially applied filter.
class BranchListing {
  final List<String>? branches;
  final String? warning;

  const BranchListing({this.branches, this.warning});
}

/// Lists branches of a develop4God GitHub repo, optionally keeping only the
/// recently active ones. Debug tooling only.
class GithubBranchLister {
  static const String devotionalsRepo = 'Devocionales-json';
  static const String bibleVersionsRepo = 'bible_versions';

  /// Complete listings kept for the app session, so reopening the debug page
  /// does not spend the unauthenticated GitHub quota (1 + N calls per
  /// filtered listing). Warned/failed listings are never cached.
  static final Map<String, BranchListing> _sessionCache = {};

  @visibleForTesting
  static void clearSessionCache() => _sessionCache.clear();

  final http.Client _client;
  final DateTime Function() _now;

  GithubBranchLister({http.Client? client, DateTime Function()? now})
      : _client = client ?? http.Client(),
        _now = now ?? DateTime.now;

  void close() => _client.close();

  static const _requestTimeout = Duration(seconds: 10);
  static const _headers = {'Accept': 'application/vnd.github.v3+json'};

  /// Branches of [repo]. With [activeWithin], branches whose newest commit
  /// (author or committer date, so rebases and cherry-picks are not misjudged)
  /// is older are dropped; [alwaysKeep] is never dropped. When a branch's date
  /// cannot be read (e.g. rate limit) it is kept and [BranchListing.warning]
  /// says the filter is incomplete. Complete results are cached for the
  /// session unless [forceRefresh] is set.
  Future<BranchListing> fetch(
    String repo, {
    Duration? activeWithin,
    String alwaysKeep = 'main',
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$repo|${activeWithin?.inDays}|$alwaysKeep';
    final cached = _sessionCache[cacheKey];
    if (!forceRefresh && cached != null) return cached;
    final listing = await _fetchUncached(repo, activeWithin, alwaysKeep);
    if (listing.branches != null && listing.warning == null) {
      _sessionCache[cacheKey] = listing;
    }
    return listing;
  }

  Future<BranchListing> _fetchUncached(
    String repo,
    Duration? activeWithin,
    String alwaysKeep,
  ) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              'https://api.github.com/repos/develop4God/$repo/branches?per_page=100',
            ),
            headers: _headers,
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        final reason = response.statusCode == 403
            ? 'GitHub rate limit hit'
            : 'GitHub API error ${response.statusCode}';
        return BranchListing(warning: '$reason listing $repo branches');
      }
      final names = (jsonDecode(response.body) as List)
          .map((b) => b['name'] as String)
          .toList();
      if (activeWithin == null) return BranchListing(branches: names);

      final cutoff = _now().subtract(activeWithin);
      final checks = await Future.wait(
        names.map(
          (n) => n == alwaysKeep
              ? Future<bool?>.value(true)
              : _isActive(repo, n, cutoff),
        ),
      );
      final active = [
        for (var i = 0; i < names.length; i++)
          if (checks[i] != false) names[i],
      ];
      final unchecked = checks.where((c) => c == null).length;
      return BranchListing(
        // Never hand callers an empty list (a dropdown cannot render one).
        branches: active.isEmpty ? [alwaysKeep] : active,
        warning: unchecked == 0
            ? null
            : 'Activity filter incomplete: $unchecked branch(es) could not be '
                'checked (rate limit?) and are shown anyway',
      );
    } catch (e) {
      debugPrint('❌ Error fetching branches for $repo: $e');
      return BranchListing(warning: 'Unexpected GitHub response for $repo: $e');
    }
  }

  /// True/false when the branch's age is known, null when it could not be
  /// determined.
  Future<bool?> _isActive(String repo, String branch, DateTime cutoff) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              'https://api.github.com/repos/develop4God/$repo/branches/${Uri.encodeComponent(branch)}',
            ),
            headers: _headers,
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200) return null;
      final commit = jsonDecode(response.body)['commit']['commit'];
      final dates = [
        for (final who in ['committer', 'author'])
          if (commit[who]?['date'] is String)
            DateTime.parse(commit[who]['date'] as String),
      ];
      if (dates.isEmpty) return null;
      return dates.any((d) => d.isAfter(cutoff));
    } catch (_) {
      return null;
    }
  }
}
