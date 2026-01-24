import 'dart:developer' as developer;

/// Classifies queries to determine if they should use BERT-SQuAD or general LLM.
/// 
/// BERT-SQuAD is best for:
/// - Questions about specific AVRAI data (spots, users, lists, personality)
/// - Questions that can be answered from provided context
/// - Factual questions with precise answers
/// 
/// General LLM (Llama) is best for:
/// - General conversation
/// - Creative text generation
/// - Commands and instructions
/// - Questions requiring reasoning beyond provided context
class QueryClassifier {
  static const String _logName = 'QueryClassifier';
  
  /// AVRAI-specific keywords that indicate dataset questions.
  static const List<String> _avraiKeywords = [
    'spot', 'spots', 'user', 'users', 'list', 'lists',
    'personality', 'profile', 'dimension', 'dimensions',
    'respect', 'visit', 'visited', 'created', 'address',
    'category', 'tags', 'expertise', 'archetype',
    'authenticity', 'exploration', 'community', 'vibe',
    'my ', 'my ', 'what is my', 'what are my', 'show me',
    'how many', 'which spot', 'where is',
  ];
  
  /// Question words that indicate factual questions.
  static const List<String> _questionWords = [
    'what', 'where', 'when', 'who', 'which', 'how many',
    'how much', 'how often',
  ];
  
  /// Check if query should use BERT-SQuAD.
  /// 
  /// Returns true if:
  /// - Query contains AVRAI keywords AND
  /// - Query is a question (ends with ? or starts with question word) AND
  /// - Query asks about specific data (not general conversation)
  Future<bool> isDatasetQuestion(String query) async {
    try {
      final lowerQuery = query.toLowerCase().trim();
      
      // Check for AVRAI keywords
      final hasAvraiKeyword = _avraiKeywords.any(
        (keyword) => lowerQuery.contains(keyword),
      );
      
      if (!hasAvraiKeyword) {
        developer.log('No AVRAI keywords found', name: _logName);
        return false;
      }
      
      // Check if it's a question
      final isQuestion = lowerQuery.endsWith('?') ||
          _questionWords.any((word) => lowerQuery.startsWith(word));
      
      if (!isQuestion) {
        developer.log('Not a question format', name: _logName);
        return false;
      }
      
      // Check for general conversation indicators (exclude these)
      final conversationIndicators = [
        'tell me about', 'explain', 'describe', 'help me',
        'can you', 'could you', 'please', 'chat', 'talk',
      ];
      
      final isGeneralConversation = conversationIndicators.any(
        (indicator) => lowerQuery.contains(indicator),
      );
      
      if (isGeneralConversation) {
        developer.log('General conversation, not dataset question', name: _logName);
        return false;
      }
      
      developer.log('Query classified as dataset question', name: _logName);
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error classifying query: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return false; // Default to general LLM on error
    }
  }
}
