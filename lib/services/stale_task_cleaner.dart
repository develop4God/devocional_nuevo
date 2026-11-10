import 'package:devocional_nuevo/services/i_stale_task_cleaner.dart';
import 'package:flutter/services.dart';

/// [IStaleTaskCleaner] backed by the native general MethodChannel.
class StaleTaskCleaner implements IStaleTaskCleaner {
  static const MethodChannel _channel =
      MethodChannel('com.devocional_nuevo.test_channel');

  @override
  Future<int> removeStaleAppTasks() async {
    try {
      return await _channel.invokeMethod<int>('removeStaleAppTasks') ?? 0;
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }
}
