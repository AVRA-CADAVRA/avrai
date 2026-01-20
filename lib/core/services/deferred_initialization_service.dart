import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:avrai/core/services/logger.dart';

/// Service for managing deferred initialization of non-critical app services.
/// This allows the UI to render immediately while services initialize in background.
///
/// Usage:
/// ```dart
/// final deferredInit = DeferredInitializationService();
/// deferredInit.addTask(
///   priority: 1,
///   name: 'Signal Protocol',
///   initializer: () => signalInitService.initialize(),
/// );
/// deferredInit.start();
/// ```
class DeferredInitializationService {
  final AppLogger _logger = const AppLogger(
    defaultTag: 'DeferredInit',
    minimumLevel: LogLevel.debug,
  );

  /// Queue of initialization tasks
  final List<_InitializationTask> _tasks = [];

  /// Track which tasks have completed
  final Set<String> _completedTasks = {};

  /// Track which tasks have failed
  final Set<String> _failedTasks = {};

  /// Whether initialization has started
  bool _started = false;

  /// Whether initialization is complete
  bool _isComplete = false;

  /// Completion callback (optional)
  VoidCallback? onComplete;

  /// Task completion callback (optional) - called when each task completes
  void Function(String taskName, bool success)? onTaskComplete;

  /// Add an initialization task to the queue
  ///
  /// [priority] - Lower numbers = higher priority (executed first)
  /// [name] - Unique identifier for this task
  /// [initializer] - Async function that performs initialization
  /// [dependencies] - Task names that must complete before this task runs
  void addTask({
    required int priority,
    required String name,
    required Future<void> Function() initializer,
    List<String> dependencies = const [],
  }) {
    if (_started) {
      _logger.warn('Cannot add task "$name" after initialization has started');
      return;
    }

    _tasks.add(_InitializationTask(
      priority: priority,
      name: name,
      initializer: initializer,
      dependencies: dependencies,
    ));
  }

  /// Start deferred initialization
  ///
  /// Tasks are executed in priority order (lowest priority number first).
  /// Tasks with dependencies wait for their dependencies to complete.
  Future<void> start() async {
    if (_started) {
      _logger.warn('Deferred initialization already started');
      return;
    }

    _started = true;
    _logger.info('🚀 [DeferredInit] Starting deferred initialization of ${_tasks.length} tasks');

    // Sort by priority (lowest number = highest priority)
    _tasks.sort((a, b) => a.priority.compareTo(b.priority));

    // Execute tasks in priority order, respecting dependencies
    for (final task in _tasks) {
      // Wait for dependencies to complete
      if (task.dependencies.isNotEmpty) {
        await _waitForDependencies(task.dependencies, task.name);
      }

      // Execute the task
      await _executeTask(task);
    }

    _isComplete = true;
    _logger.info('✅ [DeferredInit] All deferred initialization tasks completed');
    onComplete?.call();
  }

  /// Wait for all dependencies to complete
  Future<void> _waitForDependencies(
    List<String> dependencies,
    String taskName,
  ) async {
    final pending = dependencies.where((dep) => !_completedTasks.contains(dep)).toList();
    if (pending.isEmpty) return;

    _logger.debug(
      '⏳ [DeferredInit] Task "$taskName" waiting for dependencies: ${pending.join(", ")}',
    );

    // Poll until all dependencies are complete (or failed)
    // In practice, dependencies should complete quickly since we execute in priority order
    while (pending.any((dep) => !_completedTasks.contains(dep) && !_failedTasks.contains(dep))) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // Check if any dependency failed
    final failedDeps = pending.where((dep) => _failedTasks.contains(dep)).toList();
    if (failedDeps.isNotEmpty) {
      _logger.warn(
        '⚠️ [DeferredInit] Task "$taskName" has failed dependencies: ${failedDeps.join(", ")}. Proceeding anyway.',
      );
    }
  }

  /// Execute a single initialization task
  Future<void> _executeTask(_InitializationTask task) async {
    if (_completedTasks.contains(task.name)) {
      _logger.debug('⏭️ [DeferredInit] Task "${task.name}" already completed, skipping');
      return;
    }

    _logger.debug('🔄 [DeferredInit] Initializing: ${task.name}');

    try {
      await task.initializer();
      _completedTasks.add(task.name);
      _logger.info('✅ [DeferredInit] Completed: ${task.name}');
      onTaskComplete?.call(task.name, true);
    } catch (e, stackTrace) {
      _failedTasks.add(task.name);
      _logger.error(
        '❌ [DeferredInit] Failed: ${task.name}',
        error: e,
        stackTrace: stackTrace,
      );
      onTaskComplete?.call(task.name, false);
      // Continue with other tasks even if one fails
    }
  }

  /// Check if a specific task has completed
  bool isTaskComplete(String taskName) => _completedTasks.contains(taskName);

  /// Check if a specific task has failed
  bool isTaskFailed(String taskName) => _failedTasks.contains(taskName);

  /// Check if all tasks are complete
  bool get isComplete => _isComplete && _tasks.every((t) => _completedTasks.contains(t.name));

  /// Get list of completed task names
  List<String> get completedTasks => List.unmodifiable(_completedTasks);

  /// Get list of failed task names
  List<String> get failedTasks => List.unmodifiable(_failedTasks);
}

/// Internal representation of an initialization task
class _InitializationTask {
  final int priority;
  final String name;
  final Future<void> Function() initializer;
  final List<String> dependencies;

  _InitializationTask({
    required this.priority,
    required this.name,
    required this.initializer,
    required this.dependencies,
  });
}
