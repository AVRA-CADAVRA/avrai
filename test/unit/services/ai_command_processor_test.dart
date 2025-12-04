/// SPOTS AICommandProcessor Service Tests
/// Date: November 19, 2025
/// Purpose: Test AI command processing with LLM service and rule-based fallback
/// 
/// Test Coverage:
/// - Command Processing: LLM-based and rule-based command handling
/// - Offline Handling: Fallback to rule-based processing when offline
/// - Rule-based Processing: List creation, spot addition, search commands
/// - Error Handling: LLM failures, offline exceptions
/// 
/// Dependencies:
/// - Mock LLMService: Simulates LLM backend
/// - Mock Connectivity: Simulates network state
/// - Mock BuildContext: Simulates Flutter context

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spots/presentation/widgets/common/ai_command_processor.dart';
import 'package:spots/core/services/llm_service.dart';

import 'ai_command_processor_test.mocks.dart';

@GenerateMocks([LLMService, Connectivity, BuildContext])
void main() {
  group('AICommandProcessor Tests', () {
    late MockLLMService mockLLMService;
    late MockConnectivity mockConnectivity;
    late MockBuildContext mockContext;

    setUp(() {
      mockLLMService = MockLLMService();
      mockConnectivity = MockConnectivity();
      mockContext = MockBuildContext();
    });

    group('processCommand', () {
      test('should process create list command using rule-based fallback', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await AICommandProcessor.processCommand(
          'create a list called "Coffee Shops"',
          mockContext,
          llmService: null,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result, contains('Coffee Shops'));
        expect(result.toLowerCase(), contains('create'));
      });

      test('should process add spot command using rule-based fallback', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await AICommandProcessor.processCommand(
          'add Central Park to my list',
          mockContext,
          llmService: null,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result.toLowerCase(), contains('add'));
      });

      test('should process find command using rule-based fallback', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await AICommandProcessor.processCommand(
          'find restaurants near me',
          mockContext,
          llmService: null,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result.toLowerCase(), contains('restaurant'));
      });

      test('should use LLM service when online and available', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLLMService.generateRecommendation(
          userQuery: anyNamed('userQuery'),
          userContext: anyNamed('userContext'),
        )).thenAnswer((_) async => 'LLM response');

        // Act
        final result = await AICommandProcessor.processCommand(
          'test command',
          mockContext,
          llmService: mockLLMService,
        );

        // Assert
        expect(result, equals('LLM response'));
        verify(mockLLMService.generateRecommendation(
          userQuery: 'test command',
          userContext: null,
        )).called(1);
      });

      test('should fallback to rule-based when LLM service fails', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLLMService.generateRecommendation(
          userQuery: anyNamed('userQuery'),
          userContext: anyNamed('userContext'),
        )).thenThrow(Exception('LLM error'));

        // Act
        final result = await AICommandProcessor.processCommand(
          'find coffee shops',
          mockContext,
          llmService: mockLLMService,
        );

        // Assert - Should fallback to rule-based
        expect(result, isNotEmpty);
        expect(result.toLowerCase(), contains('coffee'));
      });

      test('should handle offline exception and use rule-based fallback', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLLMService.generateRecommendation(
          userQuery: anyNamed('userQuery'),
          userContext: anyNamed('userContext'),
        )).thenThrow(OfflineException('Network unavailable'));

        // Act
        final result = await AICommandProcessor.processCommand(
          'create a list',
          mockContext,
          llmService: mockLLMService,
        );

        // Assert - Should fallback to rule-based
        expect(result, isNotEmpty);
        expect(result.toLowerCase(), contains('create'));
      });

      test('should handle help command', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await AICommandProcessor.processCommand(
          'help',
          mockContext,
          llmService: null,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result.toLowerCase(), contains('help'));
      });

      test('should handle trending command', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await AICommandProcessor.processCommand(
          'show me trending spots',
          mockContext,
          llmService: null,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result.toLowerCase(), contains('trending'));
      });

      test('should handle event command', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await AICommandProcessor.processCommand(
          'show me weekend events',
          mockContext,
          llmService: null,
        );

        // Assert
        expect(result, isNotEmpty);
        final lowerResult = result.toLowerCase();
        expect(lowerResult.contains('weekend') || lowerResult.contains('event'), isTrue);
      });

      test('should handle default command for unknown input', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await AICommandProcessor.processCommand(
          'random unknown command',
          mockContext,
          llmService: null,
        );

        // Assert - Should return default help message
        expect(result, isNotEmpty);
        final lowerResult = result.toLowerCase();
        expect(lowerResult.contains('help') || lowerResult.contains('create'), isTrue);
      });
    });

    group('Rule-based Processing', () {
      test('should extract list name from quoted string', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await AICommandProcessor.processCommand(
          'create a list called "My Favorite Places"',
          mockContext,
          llmService: null,
        );

        // Assert
        expect(result, contains('My Favorite Places'));
      });

      test('should extract list name from "called" keyword', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await AICommandProcessor.processCommand(
          'create list called Test List',
          mockContext,
          llmService: null,
        );

        // Assert
        expect(result, contains('Test List'));
      });
    });
  });
}

