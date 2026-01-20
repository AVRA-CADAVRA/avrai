---
name: code-documentation-standards
description: Enforces Dart doc comments for public APIs, parameter descriptions, usage examples. Use when writing public APIs, reviewing code, or ensuring documentation completeness.
---

# Code Documentation Standards

## Mandatory Rule

**✅ ALWAYS document public APIs** (classes, methods, functions)
**✅ Use Dart doc comments (`///`) for public APIs**
**✅ Include parameter descriptions, return values, exceptions**
**✅ Document complex business logic** with inline comments
**❌ Don't document obvious code** (e.g., `/// Gets the name` for `getName()`)

## Documentation Pattern

Document **WHY**, not **WHAT** (code should be self-explanatory).

## Class Documentation

```dart
/// Service for managing user authentication
///
/// Handles sign in, sign up, sign out, and password management.
/// Uses Supabase for backend authentication.
class AuthService {
  // Implementation
}
```

## Method Documentation

### Simple Method
```dart
/// Signs in a user with email and password
///
/// Returns the authenticated user on success.
/// Throws [AuthException] if credentials are invalid.
Future<User> signIn(String email, String password) async {
  // Implementation
}
```

### Complex Method
```dart
/// Calculate sales tax for an event
///
/// **Flow:**
/// 1. Get event details
/// 2. Check if event type is taxable
/// 3. Get tax rate for location
/// 4. Calculate tax amount
///
/// **Parameters:**
/// - `eventId`: Event ID
/// - `ticketPrice`: Ticket price in dollars
///
/// **Returns:**
/// SalesTaxCalculation with tax details
///
/// **Throws:**
/// - [EventNotFoundException] if event not found
/// - [InvalidPriceException] if price is negative
Future<SalesTaxCalculation> calculateSalesTax({
  required String eventId,
  required double ticketPrice,
}) async {
  // Implementation
}
```

## Parameter Documentation

```dart
/// Creates a new spot
///
/// [name] - Name of the spot
/// [latitude] - Latitude coordinate (-90 to 90)
/// [longitude] - Longitude coordinate (-180 to 180)
/// [address] - Optional address string
Spot createSpot({
  required String name,
  required double latitude,
  required double longitude,
  String? address,
}) {
  // Implementation
}
```

## Property Documentation

```dart
class User {
  /// User's unique identifier
  final String id;
  
  /// User's display name
  final String name;
  
  /// User's email address
  ///
  /// May be null if user signed up with social auth
  final String? email;
}
```

## Enum Documentation

```dart
/// Event types available in the system
enum EventType {
  /// Community meetup or gathering
  meetup,
  
  /// Workshop or educational event
  workshop,
  
  /// Social event or party
  social,
}
```

## Complex Logic Documentation

Use inline comments for complex business logic:

```dart
Future<Result<User>> authenticate(String email, String password) async {
  // Validate email format before attempting auth
  // This prevents unnecessary API calls
  if (!_isValidEmail(email)) {
    return Result.failure('Invalid email format');
  }
  
  try {
    // Attempt Supabase authentication
    // This may throw AuthException if credentials are invalid
    final user = await _supabase.auth.signIn(
      email: email,
      password: password,
    );
    
    // Cache user locally for offline access
    await _storageService.saveUser(user);
    
    return Result.success(user);
  } on AuthException catch (e) {
    // Don't log password in error message
    developer.log('Authentication failed', error: e, name: 'AuthService');
    return Result.failure('Invalid email or password');
  }
}
```

## Usage Examples

For complex APIs, include usage examples:

```dart
/// Calculates compatibility score between two users
///
/// Uses 12-dimensional personality spectrum to calculate compatibility.
///
/// **Example:**
/// ```dart
/// final user1 = User(personality: Personality(...));
/// final user2 = User(personality: Personality(...));
/// final score = compatibilityCalculator.calculate(user1, user2);
/// print('Compatibility: ${score * 100}%');
/// ```
double calculateCompatibility(User user1, User user2) {
  // Implementation
}
```

## TODO Comments

Use `TODO` comments with phase notation:

```dart
// TODO(Phase 8.3.2): Add support for event cancellations
// TODO(Phase 9.1): Implement batch operations
```

## What NOT to Document

Don't document obvious code:

```dart
// ❌ BAD: Obvious documentation
/// Gets the user's name
String getName() => _name;

// ✅ GOOD: Self-explanatory code
String getName() => _name;
```

## Checklist

Before committing:
- [ ] All public classes documented
- [ ] All public methods documented
- [ ] Parameters documented (for complex methods)
- [ ] Return values documented
- [ ] Exceptions documented
- [ ] Complex logic has inline comments
- [ ] Usage examples for complex APIs
- [ ] No obvious/trivial documentation
