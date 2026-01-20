---
name: workflow-controller-pattern
description: Implements base workflow controller patterns for multi-step processes. Use when creating complex workflows that require orchestration of multiple steps with error handling and rollback.
---

# Workflow Controller Pattern

## Base Workflow Controller

Use base workflow controller for multi-step processes:

```dart
import 'dart:developer' as developer;

abstract class WorkflowController<TInput, TOutput> {
  final AppLogger _logger;
  
  WorkflowController({AppLogger? logger})
      : _logger = logger ?? const AppLogger(
          defaultTag: 'WorkflowController',
          minimumLevel: LogLevel.debug,
        );
  
  Future<Result<TOutput>> execute(TInput input) async {
    _logger.info('Starting workflow execution');
    try {
      return await executeWorkflow(input);
    } catch (e, st) {
      _logger.error('Workflow execution failed', error: e, stackTrace: st);
      return Result.failure('Workflow execution failed: ${e.toString()}');
    }
  }
  
  @protected
  Future<Result<TOutput>> executeWorkflow(TInput input);
  
  @protected
  Future<void> onWorkflowStart(TInput input) async {}
  
  @protected
  Future<void> onWorkflowComplete(TOutput output) async {}
  
  @protected
  Future<void> onWorkflowError(Object error, StackTrace stackTrace) async {}
}
```

## Implementation Pattern

```dart
class MyWorkflowController extends WorkflowController<InputType, OutputType> {
  final Step1Service _step1Service;
  final Step2Service _step2Service;
  final Step3Service _step3Service;
  
  MyWorkflowController({
    required Step1Service step1Service,
    required Step2Service step2Service,
    required Step3Service step3Service,
    super.logger,
  })  : _step1Service = step1Service,
        _step2Service = step2Service,
        _step3Service = step3Service;
  
  @override
  Future<Result<OutputType>> executeWorkflow(InputType input) async {
    await onWorkflowStart(input);
    
    // Step 1
    final step1Result = await _step1Service.execute(input);
    if (step1Result.isFailure) {
      await onWorkflowError(step1Result.error, StackTrace.current);
      return step1Result.toFailure();
    }
    
    // Step 2
    final step2Result = await _step2Service.execute(step1Result.value);
    if (step2Result.isFailure) {
      await _step1Service.rollback(step1Result.value);
      await onWorkflowError(step2Result.error, StackTrace.current);
      return step2Result.toFailure();
    }
    
    // Step 3
    final step3Result = await _step3Service.execute(step2Result.value);
    if (step3Result.isFailure) {
      await _step2Service.rollback(step2Result.value);
      await _step1Service.rollback(step1Result.value);
      await onWorkflowError(step3Result.error, StackTrace.current);
      return step3Result.toFailure();
    }
    
    await onWorkflowComplete(step3Result.value);
    return Result.success(step3Result.value);
  }
}
```

## Rollback Pattern

For workflows that need rollback:

```dart
abstract class ReversibleWorkflowController<TInput, TOutput> 
    extends WorkflowController<TInput, TOutput> {
  
  final List<RollbackAction> _rollbackActions = [];
  
  @protected
  void registerRollback(Future<void> Function() rollbackAction) {
    _rollbackActions.add(RollbackAction(rollbackAction));
  }
  
  @protected
  Future<void> executeRollback() async {
    for (final action in _rollbackActions.reversed) {
      try {
        await action.execute();
      } catch (e, st) {
        developer.log(
          'Rollback action failed',
          error: e,
          stackTrace: st,
          name: 'WorkflowController',
        );
      }
    }
    _rollbackActions.clear();
  }
  
  @override
  Future<Result<TOutput>> executeWorkflow(TInput input) async {
    try {
      return await super.executeWorkflow(input);
    } catch (e, st) {
      await executeRollback();
      rethrow;
    }
  }
}

class RollbackAction {
  final Future<void> Function() execute;
  RollbackAction(this.execute);
}
```

## Error Handling

Each step should handle its own errors:

```dart
Future<Result<StepData>> _executeStep(StepInput input) async {
  try {
    final result = await _service.performOperation(input);
    return Result.success(result);
  } on ValidationException catch (e) {
    return Result.failure('Validation failed: ${e.message}');
  } on NetworkException catch (e) {
    return Result.failure('Network error: ${e.message}');
  } catch (e, st) {
    developer.log('Step execution failed', error: e, stackTrace: st);
    return Result.failure('Step execution failed');
  }
}
```

## Reference

See base workflow controller in:
- `lib/core/controllers/base/workflow_controller.dart`
