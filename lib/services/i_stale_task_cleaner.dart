/// Removes leftover recents cards of this app after an in-app update restart.
abstract class IStaleTaskCleaner {
  /// Finishes and removes every app task except the current one.
  /// Returns the number of tasks removed; never throws.
  Future<int> removeStaleAppTasks();
}
