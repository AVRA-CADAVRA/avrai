# LLM Chat Stream Edge Function

## Overview

This Supabase Edge Function provides **Server-Sent Events (SSE) streaming** for Google Gemini LLM responses. It enables real-time word-by-word streaming of AI responses to the client.

**Last Updated:** November 26, 2025  
**Status:** Enhanced with reconnection, error handling, and timeout management

## Features

- **True SSE Streaming:** Real-time response streaming from Gemini API
- **Full Context Support:** Personality, vibe, AI2AI insights, connection metrics
- **Enhanced Error Handling:** Graceful handling of stream interruptions, API errors, and safety filters
- **Timeout Management:** 5-minute timeout for long-running streams
- **Connection Recovery:** Automatic reconnection logic (client-side)
- **Fallback Support:** Automatic fallback to non-streaming on failure
- **CORS Enabled:** Works with web and mobile clients

## API

### Endpoint

```
POST /llm-chat-stream
```

### Request Body

```json
{
  "messages": [
    {"role": "user", "content": "Find coffee shops near me"}
  ],
  "context": {
    "userId": "user-123",
    "location": {"lat": 40.7128, "lng": -74.0060},
    "personality": { ... },
    "vibe": { ... },
    "ai2aiInsights": [ ... ],
    "connectionMetrics": { ... }
  },
  "temperature": 0.7,
  "maxTokens": 500
}
```

### Response Format (SSE)

The response is a Server-Sent Events stream:

```
data: {"text": "I"}

data: {"text": " found"}

data: {"text": " some"}

data: {"text": " great"}

data: {"text": " coffee"}

data: {"text": " shops"}

data: {"done": true}
```

## Client Usage

### Dart/Flutter

```dart
final response = await http.post(
  Uri.parse('$supabaseUrl/functions/v1/llm-chat-stream'),
  headers: {
    'Authorization': 'Bearer $supabaseAnonKey',
    'Content-Type': 'application/json',
  },
  body: jsonEncode(request),
);

final stream = response.body
  .transform(utf8.decoder)
  .transform(LineSplitter())
  .where((line) => line.startsWith('data: '))
  .map((line) => line.substring(6))
  .map((data) => jsonDecode(data));

await for (final event in stream) {
  if (event['text'] != null) {
    print(event['text']);
  }
  if (event['done'] == true) {
    break;
  }
}
```

## Deployment

```bash
supabase functions deploy llm-chat-stream
```

## Environment Variables

- `GEMINI_API_KEY`: Google Gemini API key (required)

## Error Handling

### Error Events

The stream may send error events:

```
data: {"error": "Error message"}
data: {"done": true}
```

### Error Types

1. **API Errors:** Gemini API errors (4xx/5xx) are forwarded to client
2. **Safety Filters:** Responses blocked by safety filters are reported
3. **Stream Timeout:** Streams exceeding 5 minutes are automatically closed
4. **Connection Errors:** Network issues trigger client-side reconnection

### Client-Side Error Handling

The Dart client (`LLMService`) includes:
- **Automatic Reconnection:** Up to 3 retry attempts with 2-second delays
- **Fallback to Non-Streaming:** If SSE fails after retries, automatically falls back to regular `chat()` method
- **Timeout Handling:** 5-minute timeout for entire stream
- **Partial Text Recovery:** Yields accumulated text before retrying or falling back

### Error Recovery Flow

```
SSE Connection → Error Detected
    ↓
Check Error Type
    ↓
Retryable? → Yes → Retry (max 3 attempts)
    ↓              ↓
    No            Success → Continue
    ↓
Fallback to Non-Streaming Chat
```

## Performance

- **Latency:** First token in ~200-500ms
- **Throughput:** ~10-20 tokens/second (depends on Gemini API)
- **Timeout:** 5 minutes maximum (prevents hanging connections)
- **Reconnection:** 2-second delay between retries (max 3 attempts)

## Comparison with Non-Streaming

| Feature | Non-Streaming | SSE Streaming |
|---------|---------------|---------------|
| First response | 3-5 seconds | 0.2-0.5 seconds |
| User perception | Slow | Fast & responsive |
| Long responses | Blocking | Progressive |
| Bandwidth | All at once | Incremental |

## Implementation Details

### Edge Function Enhancements (Week 35)

1. **Timeout Management:**
   - 5-minute timeout for entire stream
   - Prevents hanging connections
   - Sends completion event on timeout

2. **Enhanced Error Detection:**
   - Detects Gemini API errors in stream
   - Handles safety filter blocks
   - Reports finish reasons (STOP, SAFETY, etc.)

3. **Stream Cleanup:**
   - Proper reader cancellation
   - Timeout cleanup
   - Error event propagation

### Client-Side Enhancements (Week 35)

1. **Automatic Reconnection:**
   - Up to 3 retry attempts
   - 2-second delay between retries
   - Resets on successful data reception

2. **Intelligent Fallback:**
   - Falls back to non-streaming after retries exhausted
   - Preserves accumulated text before fallback
   - Handles timeout exceptions gracefully

3. **Error Classification:**
   - Non-retryable: 4xx errors, safety blocks, timeouts
   - Retryable: 5xx errors, connection drops
   - Partial recovery: Yields text before retry/fallback

## Usage Example

### Dart/Flutter with Enhanced Error Handling

```dart
try {
  final stream = llmService.chatStream(
    messages: [
      ChatMessage(role: ChatRole.user, content: 'Find coffee shops'),
    ],
    useRealSSE: true,
    autoFallback: true, // Automatically fallback if SSE fails
  );
  
  await for (final text in stream) {
    // Text is cumulative - each emission contains all text so far
    print('Streaming: $text');
  }
} catch (e) {
  // Handles both SSE failures and fallback failures
  print('Error: $e');
}
```

## Notes

- This replaces the simulated streaming in `LLMService.chatStream()`
- The Gemini API SSE endpoint is: `streamGenerateContent?alt=sse`
- Connection recovery is handled automatically by the client
- Fallback to non-streaming is automatic when `autoFallback: true`
- All error handling is transparent to the caller

