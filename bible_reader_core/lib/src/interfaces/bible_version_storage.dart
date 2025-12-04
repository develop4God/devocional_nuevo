/// Abstract storage interface for Bible version management.
///
/// This interface allows the bible_reader_core package to persist data
/// without depending on Flutter-specific packages like path_provider
/// or shared_preferences. The consuming application provides its own
/// implementation using its preferred storage solution.
///
/// Example BLoC app implementation:
/// ```dart
/// class StorageAdapter implements BibleVersionStorage {
///   @override
///   Future<String> getBiblesDirectory() async {
///     final dir = await getApplicationDocumentsDirectory();
///     return '${dir.path}/bibles';
///   }
///   // ... other implementations
/// }
/// ```
abstract class BibleVersionStorage {
  /// Gets the directory path where Bible databases are stored.
  ///
  /// Returns a path like `/data/user/0/com.app.name/files/bibles`
  /// The directory should be created if it doesn't exist.
  Future<String> getBiblesDirectory();

  /// Saves the list of downloaded version IDs to persistent storage.
  ///
  /// This is used to track which versions have been downloaded,
  /// separate from actually checking if the files exist.
  Future<void> saveDownloadedVersions(List<String> versionIds);

  /// Retrieves the list of downloaded version IDs from persistent storage.
  ///
  /// Returns an empty list if no versions have been downloaded.
  Future<List<String>> getDownloadedVersions();

  /// Writes binary data to a file at the specified path.
  ///
  /// Creates parent directories if they don't exist.
  /// Overwrites the file if it already exists.
  Future<void> writeFile(String path, List<int> bytes);

  /// Reads binary data from a file at the specified path.
  ///
  /// Throws an exception if the file doesn't exist.
  Future<List<int>> readFile(String path);

  /// Deletes the file at the specified path.
  ///
  /// Does nothing if the file doesn't exist.
  Future<void> deleteFile(String path);

  /// Checks if a file exists at the specified path.
  Future<bool> fileExists(String path);

  /// Gets the available storage space in bytes.
  ///
  /// Returns 0 if the available space cannot be determined.
  Future<int> getAvailableSpace();

  /// Deletes a directory and all its contents.
  ///
  /// Does nothing if the directory doesn't exist.
  Future<void> deleteDirectory(String path);

  /// Checks if a directory exists at the specified path.
  Future<bool> directoryExists(String path);

  /// Creates a directory at the specified path, including parent directories.
  Future<void> createDirectory(String path);

  /// Lists files in a directory.
  ///
  /// Returns file names (not full paths) in the directory.
  Future<List<String>> listFiles(String directoryPath);
}
