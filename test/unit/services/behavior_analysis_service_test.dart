import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/behavior_analysis_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// Behavior Analysis Service Tests
/// Tests user behavior analysis functionality
void main() {

  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('BehaviorAnalysisService', () {
    group('analyzeUserBehavior', () {
      test('should analyze empty actions list', () {
        final result = BehaviorAnalysisService.analyzeUserBehavior([]);
        
        expect(result, isA<Map<String, dynamic>>());
        expect(result['totalActions'], equals(0));
        expect(result['actionTypes'], isA<Map<String, int>>());
        expect(result['timePatterns'], isA<Map<String, dynamic>>());
        expect(result['preferences'], isA<Map<String, dynamic>>());
      });

      test('should analyze single action', () {
        final actions = [
          {'type': 'spot_view', 'timestamp': DateTime.now().toIso8601String()},
        ];
        
        final result = BehaviorAnalysisService.analyzeUserBehavior(actions);
        
        expect(result['totalActions'], equals(1));
        expect(result['actionTypes'], isA<Map<String, int>>());
        expect((result['actionTypes'] as Map)['spot_view'], equals(1));
      });

      test('should analyze multiple actions of different types', () {
        final actions = [
          {'type': 'spot_view', 'timestamp': DateTime.now().toIso8601String()},
          {'type': 'list_create', 'timestamp': DateTime.now().toIso8601String()},
          {'type': 'spot_view', 'timestamp': DateTime.now().toIso8601String()},
        ];
        
        final result = BehaviorAnalysisService.analyzeUserBehavior(actions);
        
        expect(result['totalActions'], equals(3));
        final actionTypes = result['actionTypes'] as Map<String, int>;
        expect(actionTypes['spot_view'], equals(2));
        expect(actionTypes['list_create'], equals(1));
      });

      test('should handle actions without type', () {
        final actions = [
          {'timestamp': DateTime.now().toIso8601String()},
          {'type': 'spot_view', 'timestamp': DateTime.now().toIso8601String()},
        ];
        
        final result = BehaviorAnalysisService.analyzeUserBehavior(actions);
        
        expect(result['totalActions'], equals(2));
        final actionTypes = result['actionTypes'] as Map<String, int>;
        expect(actionTypes['unknown'], equals(1));
        expect(actionTypes['spot_view'], equals(1));
      });

      test('should include time patterns', () {
        final actions = [
          {'type': 'spot_view', 'timestamp': DateTime.now().toIso8601String()},
        ];
        
        final result = BehaviorAnalysisService.analyzeUserBehavior(actions);
        
        expect(result['timePatterns'], isA<Map<String, dynamic>>());
        final timePatterns = result['timePatterns'] as Map<String, dynamic>;
        expect(timePatterns['morning'], isA<int>());
        expect(timePatterns['afternoon'], isA<int>());
        expect(timePatterns['evening'], isA<int>());
        expect(timePatterns['night'], isA<int>());
      });

      test('should include preferences', () {
        final actions = [
          {'type': 'spot_view', 'timestamp': DateTime.now().toIso8601String()},
        ];
        
        final result = BehaviorAnalysisService.analyzeUserBehavior(actions);
        
        expect(result['preferences'], isA<Map<String, dynamic>>());
        final preferences = result['preferences'] as Map<String, dynamic>;
        expect(preferences['categories'], isA<Map>());
        expect(preferences['locations'], isA<Map>());
        expect(preferences['activities'], isA<Map>());
      });

      test('should handle large action lists', () {
        final actions = List.generate(100, (i) => {
          'type': 'action_$i',
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        final result = BehaviorAnalysisService.analyzeUserBehavior(actions);
        
        expect(result['totalActions'], equals(100));
        expect(result['actionTypes'], isA<Map<String, int>>());
      });
    });
  });
}

