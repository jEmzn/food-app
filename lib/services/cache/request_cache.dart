import 'dart:async';

/// One cached value plus the time it was stored, so we can check its age
/// against a TTL when reading it back.
class _CacheEntry<T> {
  final T value;
  final DateTime storedAt;

  _CacheEntry(this.value, this.storedAt);
}

/// A tiny, dependency-free, in-memory request cache shared across the app.
///
/// "In-memory" means everything lives in [_store] inside this single instance.
/// There is NO disk persistence — when the app process ends the cache is gone.
/// That's intentional: the goal is just to stop the app from re-fetching the
/// same meals/recommendations/body-metrics over and over within one session.
///
/// Usage from a service:
/// ```dart
/// return RequestCache.instance.getOrFetch(
///   'meals:2026-05-30',
///   ttl: const Duration(minutes: 5),
///   forceRefresh: forceRefresh,
///   fetch: () => _realNetworkCall(),
/// );
/// ```
class RequestCache {
  // Private constructor + single shared instance (singleton). Every service
  // talks to the same cache, so an invalidation in one place is seen by all.
  RequestCache._();
  static final RequestCache instance = RequestCache._();

  final Map<String, _CacheEntry<dynamic>> _store = {};

  /// Returns the cached value for [key] if one exists and is younger than
  /// [ttl]. Otherwise it runs [fetch], stores the fresh result, and returns it.
  ///
  /// Pass [forceRefresh] = true to skip a still-fresh entry and always re-run
  /// [fetch] (used by pull-to-refresh so a manual pull always hits the network).
  ///
  /// Important: if [fetch] throws (network error, timeout, etc.) we do NOT
  /// cache anything — the error propagates to the caller and the next call will
  /// try again. This matters because the services throw user-facing (Thai)
  /// error messages that the UI shows in a SnackBar.
  Future<T> getOrFetch<T>(
    String key, {
    required Duration ttl,
    required Future<T> Function() fetch,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final entry = _store[key];
      if (entry != null) {
        final age = DateTime.now().difference(entry.storedAt);
        if (age <= ttl) {
          // Fresh enough — return the cached value, no network call.
          return entry.value as T;
        }
      }
    }

    // Cache miss, stale, or forced: do the real work and store the result.
    final value = await fetch();
    _store[key] = _CacheEntry<T>(value, DateTime.now());
    return value;
  }

  /// Drops a single cached entry. Call this after a write that changes exactly
  /// one key's data (e.g. saving body metrics).
  void invalidate(String key) {
    _store.remove(key);
  }

  /// Drops every entry whose key starts with [prefix]. Handy when a write
  /// affects several keys at once and we don't know them all — e.g. deleting a
  /// meal by id, where we don't have the date, so we clear all "meals:" keys.
  void invalidatePrefix(String prefix) {
    _store.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Wipes the whole cache. Used on logout so the next user can never see the
  /// previous user's cached data.
  void clear() {
    _store.clear();
  }
}
