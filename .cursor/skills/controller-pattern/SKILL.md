---
name: controller-pattern
description: Guides controller implementation for complex workflows, reservation creation, quantum matching, group matching. Use when creating controllers for multi-step processes or complex state management.
---

# Controller Pattern

## When to Use Controllers

Controllers are used for complex workflows that require:
- Multi-step processes
- Complex state management
- Orchestrating multiple services
- Workflow-specific logic

## Controller Structure

```dart
import 'dart:developer' as developer;
import 'package:avrai/core/services/logger.dart';

class MyController {
  final RequiredService _requiredService;
  final AppLogger _logger = const AppLogger(
    defaultTag: 'MyController',
    minimumLevel: LogLevel.debug,
  );
  
  MyController({
    required RequiredService requiredService,
  }) : _requiredService = requiredService;
  
  Future<Result<void>> executeWorkflow() async {
    _logger.info('Starting workflow');
    try {
      // Step 1
      final step1Result = await _step1();
      if (step1Result.isFailure) return step1Result;
      
      // Step 2
      final step2Result = await _step2(step1Result.value);
      if (step2Result.isFailure) return step2Result;
      
      // Step 3
      final step3Result = await _step3(step2Result.value);
      return step3Result;
    } catch (e, st) {
      _logger.error('Workflow failed', error: e, stackTrace: st);
      return Result.failure('Workflow execution failed');
    }
  }
  
  Future<Result<Step1Data>> _step1() async {
    // Implementation
  }
  
  Future<Result<Step2Data>> _step2(Step1Data data) async {
    // Implementation
  }
  
  Future<Result<void>> _step3(Step2Data data) async {
    // Implementation
  }
}
```

## Controller Registration

Register controllers in dependency injection:

```dart
// In injection container
sl.registerLazySingleton(() => MyController(
  requiredService: sl<RequiredService>(),
));
```

## Controller Usage

Controllers are used in services or BLoCs:

```dart
class MyBloc extends Bloc<MyEvent, MyState> {
  final MyController _controller;
  
  MyBloc({required MyController controller}) : _controller = controller;
  
  Future<void> _onExecuteWorkflow(
    ExecuteWorkflow event,
    Emitter<MyState> emit,
  ) async {
    emit(MyLoading());
    final result = await _controller.executeWorkflow();
    if (result.isSuccess) {
      emit(MySuccess());
    } else {
      emit(MyError(result.error));
    }
  }
}
```

## Workflow Controller Pattern

For multi-step workflows, use base workflow controller:

```dart
abstract class WorkflowController<T> {
  Future<Result<T>> execute();
  
  Future<Result<StepData>> step1();
  Future<Result<StepData>> step2(StepData previous);
  Future<Result<T>> step3(StepData previous);
}

class MyWorkflowController extends WorkflowController<OutputType> {
  @override
  Future<Result<OutputType>> execute() async {
    try {
      final step1Result = await step1();
      if (step1Result.isFailure) return step1Result.toFailure();
      
      final step2Result = await step2(step1Result.value);
      if (step2Result.isFailure) return step2Result.toFailure();
      
      return await step3(step2Result.value);
    } catch (e, st) {
      return Result.failure('Workflow failed: ${e.toString()}');
    }
  }
}
```

## Examples

### Reservation Creation Controller

```dart
class ReservationCreationController {
  final ReservationService _reservationService;
  final PaymentService _paymentService;
  final AppLogger _logger = const AppLogger(defaultTag: 'ReservationController');
  
  ReservationCreationController({
    required ReservationService reservationService,
    required PaymentService paymentService,
  })  : _reservationService = reservationService,
        _paymentService = paymentService;
  
  Future<Result<Reservation>> createReservation({
    required String eventId,
    required int ticketCount,
  }) async {
    try {
      // Step 1: Validate availability
      final availability = await _reservationService.checkAvailability(eventId);
      if (!availability.hasCapacity(ticketCount)) {
        return Result.failure('Not enough tickets available');
      }
      
      // Step 2: Create reservation
      final reservation = await _reservationService.createReservation(
        eventId: eventId,
        ticketCount: ticketCount,
      );
      
      // Step 3: Process payment
      final payment = await _paymentService.processPayment(reservation);
      if (payment.isFailure) {
        await _reservationService.cancelReservation(reservation.id);
        return payment.toFailure();
      }
      
      return Result.success(reservation);
    } catch (e, st) {
      _logger.error('Reservation creation failed', error: e, stackTrace: st);
      return Result.failure('Failed to create reservation');
    }
  }
}
```

## Reference

See existing controllers in:
- `lib/core/controllers/reservation_creation_controller.dart`
- `lib/core/controllers/group_matching_controller.dart`
- `lib/core/controllers/quantum_matching_controller.dart`
- `lib/core/controllers/base/workflow_controller.dart`
