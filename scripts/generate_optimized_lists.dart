import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.length < 3) {
    print('Usage: dart generate_optimized_lists.dart <user_id> <user_name> <optimizations>');
    exit(1);
  }
  
  final userId = args[0];
  final userName = args[1];
  final optimizations = args[2].split(' ');
  
  final now = DateTime.now();
  final optimizedLists = <Map<String, dynamic>>[];
  
  for (int i = 0; i < optimizations.length && i < 5; i++) {
    final optimization = optimizations[i];
    final listId = 'optimized-${i + 1}-$userId';
    
    optimizedLists.add({
      'id': listId,
      'title': optimization,
      'description': 'AI-optimized list based on your behavior',
      'category': 'Optimized',
      'userId': userId,
      'isPublic': false,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'isStarter': false,
      'isPersonalized': true,
      'personalizedType': 'ai_optimized',
    });
  }
  
  // Save to a temporary file for the main app to read
  final outputFile = File('optimized_lists_$userId.json');
  await outputFile.writeAsString(jsonEncode(optimizedLists));
  
  print('Generated ${optimizedLists.length} optimized lists for user $userName');
}
