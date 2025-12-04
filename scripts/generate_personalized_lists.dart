import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.length < 3) {
    print('Usage: dart generate_personalized_lists.dart <user_id> <user_name> <list_suggestions>');
    exit(1);
  }
  
  final userId = args[0];
  final userName = args[1];
  final listSuggestions = args[2].split(' ');
  
  final now = DateTime.now();
  final personalizedLists = <Map<String, dynamic>>[];
  
  for (int i = 0; i < listSuggestions.length && i < 5; i++) {
    final suggestion = listSuggestions[i];
    final listId = 'personalized-${i + 1}-$userId';
    
    personalizedLists.add({
      'id': listId,
      'title': suggestion,
      'description': 'Personalized list based on your preferences',
      'category': 'Personalized',
      'userId': userId,
      'isPublic': false,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'isStarter': false,
      'isPersonalized': true,
      'personalizedType': 'ai_generated',
    });
  }
  
  // Save to a temporary file for the main app to read
  final outputFile = File('personalized_lists_$userId.json');
  await outputFile.writeAsString(jsonEncode(personalizedLists));
  
  print('Generated ${personalizedLists.length} personalized lists for user $userName');
}
