# Complete Code Review Guide

**Date:** January 2026  
**Purpose:** Comprehensive guide to code reviews, broken into multiple parts  
**Focus:** Dependency issues, loading issues, build issues, and code quality

---

## 📚 Table of Contents

1. [Part 1: Code Review Fundamentals](#part-1-code-review-fundamentals)
2. [Part 2: Dependency Review](#part-2-dependency-review)
3. [Part 3: Build & Compilation Review](#part-3-build--compilation-review)
4. [Part 4: Loading & Initialization Review](#part-4-loading--initialization-review)
5. [Part 5: Code Quality Review](#part-5-code-quality-review)
6. [Part 6: Systematic Review Process](#part-6-systematic-review-process)
7. [Quick Reference](#quick-reference)

---

## Part 1: Code Review Fundamentals

### What is Code Review?

Code review is the systematic examination of code to:
- **Find bugs** before they reach production
- **Ensure code quality** and consistency
- **Verify architecture** and design patterns are followed
- **Check dependencies** are correctly managed
- **Validate standards** are met (naming, formatting, documentation)
- **Improve maintainability** for future developers

### Why Code Review Matters

**For Your Specific Issues:**
- **Dependency Issues:** Services not registered, missing imports, circular dependencies
- **Loading Issues:** Services not initialized, startup failures, DI registration order
- **Build Issues:** Compilation errors, linter warnings, missing dependencies

**Benefits:**
- **Catches errors early** (cheaper to fix before production)
- **Improves code quality** (ensures consistent patterns)
- **Reduces technical debt** (prevents accumulation of issues)
- **Knowledge sharing** (team learns from each other)
- **Better architecture** (ensures patterns are followed)

### How Code Review Works

**Two Approaches:**

1. **Self-Review (You):**
   - Review your own code before committing
   - Use automated tools (linter, analyzer)
   - Check against project standards
   - Fix issues before they accumulate

2. **Peer Review (Others):**
   - Someone else reviews your code
   - Provides fresh perspective
   - Catches things you might miss
   - Best practice for production code

**For Your Situation:**
- You're doing a **self-review** of the entire codebase
- Focus on **systematic discovery** of issues
- Use **automated tools** to help
- Create **actionable checklists** to fix issues

### Code Review Principles

**1. Be Systematic**
- Don't skip steps
- Follow a consistent process
- Document findings
- Track progress

**2. Start with Automated Tools**
- Use `flutter analyze` first
- Fix automated issues before manual review
- Use linters and formatters
- Run tests

**3. Prioritize by Impact**
- Fix critical issues first (compilation errors)
- Then high-impact issues (dependency problems)
- Then medium-impact issues (code quality)
- Finally low-impact issues (style, documentation)

**4. Document Everything**
- Keep notes on findings
- Create TODO lists
- Track what's fixed
- Document patterns

---

## Part 2: Dependency Review

### Overview

Dependency issues are one of the most common sources of problems. This section covers:
- Dependency Injection (DI) registration
- Package dependencies (pubspec.yaml)
- Import statements
- Circular dependencies

### 1. Dependency Injection (DI) Registration

**What to Check:**

**Questions to Ask:**
- Are all services registered in `injection_container.dart`?
- Are dependencies registered before dependents?
- Are services registered in the correct order?
- Are there circular dependencies?
- Are services registered with the correct lifecycle (singleton vs factory)?

**How to Check:**

```bash
# Find all services
grep -r "class.*Service" lib/core/services/ --include="*.dart"

# Check if they're registered
grep -r "registerLazySingleton.*Service" lib/injection_container*.dart

# Check for missing registrations
# (Compare list of services vs registered services)
```

**Common Issues:**

**❌ Service Used But Not Registered**

```dart
// ❌ BAD: Service not registered
class MyService {
  MyService(this.otherService);
  final OtherService otherService;
}

// Used in code:
final service = sl<MyService>(); // ERROR: Not registered
```

```dart
// ✅ GOOD: Service registered
sl.registerLazySingleton(() => MyService(
  otherService: sl<OtherService>(), // Dependency registered first
));
```

**❌ Dependency Registered After Dependent**

```dart
// ❌ BAD: Dependency registered after dependent
sl.registerLazySingleton(() => MyService(
  otherService: sl<OtherService>(), // ERROR: OtherService not registered yet
));
sl.registerLazySingleton(() => OtherService());
```

```dart
// ✅ GOOD: Dependency registered first
sl.registerLazySingleton(() => OtherService());
sl.registerLazySingleton(() => MyService(
  otherService: sl<OtherService>(), // OK: OtherService already registered
));
```

**❌ Circular Dependency**

```dart
// ❌ BAD: Circular dependency
sl.registerLazySingleton(() => ServiceA(serviceB: sl<ServiceB>()));
sl.registerLazySingleton(() => ServiceB(serviceA: sl<ServiceA>())); // ERROR: Circular
```

```dart
// ✅ GOOD: Use interfaces or dependency inversion
// ServiceA depends on IServiceB interface
// ServiceB implements IServiceB
// No circular dependency
```

**❌ Wrong Lifecycle**

```dart
// ❌ BAD: Should be singleton but registered as factory
sl.registerFactory(() => MyService()); // Creates new instance every time
```

```dart
// ✅ GOOD: Use singleton for services
sl.registerLazySingleton(() => MyService()); // Single instance
```

**Where Services Are Registered:**

1. **Core Services:** `lib/injection_container_core.dart`
   - StorageService
   - FeatureFlagService
   - Geographic services
   - AtomicClockService
   - PerformanceMonitor

2. **Domain Services:** `lib/injection_container.dart`
   - BusinessAccountService
   - BusinessService
   - ExpertiseEventService
   - CommunityService
   - Payment services

3. **AI Services:** `lib/injection_container_ai.dart`
   - LLMService
   - PersonalityLearningService
   - VibeAnalysisEngine

4. **Knot Services:** `lib/injection_container_knot.dart`
   - KnotFabricService
   - KnotStorageService

5. **Payment Services:** `lib/injection_container_payment.dart`
   - PaymentService
   - StripeService
   - TaxCalculationService

**Checklist:**

- [ ] All services registered in DI container
- [ ] Dependencies registered before dependents
- [ ] No circular dependencies
- [ ] Services registered with correct lifecycle (singleton vs factory)
- [ ] Services registered in correct container (core, domain, AI, etc.)
- [ ] Optional services handled correctly (try-catch for optional dependencies)

### 2. Package Dependencies (pubspec.yaml)

**What to Check:**

**Questions to Ask:**
- Are all packages in `pubspec.yaml` actually used?
- Are there version conflicts?
- Are packages up to date?
- Are there missing packages?

**How to Check:**

```bash
# Check for unused packages (manual check)
flutter pub get
flutter analyze

# Check for version conflicts
flutter pub outdated

# Check for missing packages (compilation errors)
flutter analyze | grep "Target of URI doesn't exist"
```

**Common Issues:**

**❌ Package Listed But Not Used**

```yaml
# ❌ BAD: Package in pubspec.yaml but not used
dependencies:
  http: ^1.0.0  # Not used anywhere
```

```yaml
# ✅ GOOD: Only include packages that are used
dependencies:
  dio: ^5.4.0  # Actually used
```

**❌ Package Used But Not in pubspec.yaml**

```dart
// ❌ BAD: Package used but not in pubspec.yaml
import 'package:http/http.dart'; // ERROR: Package not in pubspec.yaml
```

```yaml
# ✅ GOOD: Add package to pubspec.yaml
dependencies:
  http: ^1.0.0
```

**❌ Version Conflicts**

```yaml
# ❌ BAD: Version conflicts
dependencies:
  package_a: ^1.0.0  # Requires package_c ^2.0.0
  package_b: ^2.0.0  # Requires package_c ^1.0.0
  package_c: ^1.0.0  # Conflict!
```

```yaml
# ✅ GOOD: Resolve version conflicts
dependencies:
  package_a: ^1.0.0
  package_b: ^2.0.0
  package_c: ^2.0.0  # Use version compatible with both
```

**❌ Outdated Packages (Security Vulnerabilities)**

```bash
# Check for outdated packages
flutter pub outdated

# Update packages
flutter pub upgrade
```

**Checklist:**

- [ ] All packages in `pubspec.yaml` are used
- [ ] All used packages are in `pubspec.yaml`
- [ ] No version conflicts
- [ ] Packages are up to date
- [ ] No security vulnerabilities (check pub.dev)

### 3. Import Statements

**What to Check:**

**Questions to Ask:**
- Are imports organized correctly?
- Are there unused imports?
- Are there missing imports?
- Are imports using correct paths?

**How to Check:**

```bash
# Find unused imports (linter will flag these)
flutter analyze

# Find missing imports (compiler errors)
flutter analyze | grep "Target of URI doesn't exist"

# Check import organization (manual check)
# Should be: dart: → flutter: → package: → relative:
```

**Import Organization Standards:**

**From `.cursorrules`:**
- ✅ **Group imports in this order:**
  1. Dart SDK imports (`dart:...`)
  2. Flutter imports (`package:flutter/...`)
  3. Package imports (`package:...`)
  4. Relative imports (`../...`)
- ✅ Use alphabetical ordering within each group
- ✅ Separate groups with blank line
- ✅ Remove unused imports

**Example:**

```dart
// ✅ GOOD: Properly organized imports
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:avrai/core/models/user.dart';
import 'package:avrai/core/services/auth_service.dart';

import '../widgets/custom_button.dart';
```

```dart
// ❌ BAD: Imports not organized
import '../widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:avrai/core/models/user.dart';
import 'dart:async';
import 'package:avrai/core/services/auth_service.dart';
```

**Common Issues:**

**❌ Unused Imports**

```dart
// ❌ BAD: Unused imports (clutter, slower compilation)
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Not used
import 'package:flutter/services.dart'; // Not used
```

```dart
// ✅ GOOD: Remove unused imports
import 'package:flutter/material.dart';
```

**❌ Missing Imports**

```dart
// ❌ BAD: Missing import
class MyWidget extends StatelessWidget { // ERROR: StatelessWidget not imported
  // ...
}
```

```dart
// ✅ GOOD: Import required classes
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  // ...
}
```

**❌ Wrong Import Paths**

```dart
// ❌ BAD: Wrong import path
import 'package:spots/core/models/user.dart'; // ERROR: Should be 'avrai'
```

```dart
// ✅ GOOD: Correct import path
import 'package:avrai/core/models/user.dart';
```

**❌ Ambiguous Imports**

```dart
// ❌ BAD: Ambiguous import (SharedPreferences in two places)
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avrai/core/services/storage_service.dart'; // Also has SharedPreferences
```

```dart
// ✅ GOOD: Use 'show' or 'hide' to disambiguate
import 'package:shared_preferences/shared_preferences.dart' hide SharedPreferences;
import 'package:avrai/core/services/storage_service.dart' show SharedPreferencesCompat;
```

**Checklist:**

- [ ] Imports organized correctly (dart: → flutter: → package: → relative:)
- [ ] No unused imports
- [ ] No missing imports
- [ ] Import paths are correct
- [ ] Ambiguous imports resolved (using show/hide)
- [ ] Alphabetical ordering within groups

### 4. Circular Dependencies

**What to Check:**

**Questions to Ask:**
- Are there circular dependencies?
- Can dependencies be restructured to avoid cycles?

**How to Check:**

```bash
# Manual check: Look for A imports B, B imports A
# Or use dependency graph tools
```

**Common Issues:**

**❌ Circular Dependency**

```dart
// ❌ BAD: Circular dependency
// file_a.dart
import 'file_b.dart';
class A {
  void method(B b) {}
}

// file_b.dart
import 'file_a.dart';
class B {
  void method(A a) {}
}
```

```dart
// ✅ GOOD: Use interfaces or dependency inversion
// file_a.dart
import 'file_b.dart';
class A {
  void method(IB b) {} // Use interface
}

// file_b.dart (no import of file_a.dart needed)
class B implements IB {}
abstract class IB {}
```

**Checklist:**

- [ ] No circular dependencies
- [ ] Use interfaces for decoupling
- [ ] Dependencies point in one direction
- [ ] Can restructure to avoid cycles

---

## Part 3: Build & Compilation Review

### Overview

Build and compilation issues prevent code from running. This section covers:
- Compilation errors
- Linter errors
- Build configuration
- Platform-specific issues

### 1. Compilation Errors

**What to Check:**

**Questions to Ask:**
- Does the code compile?
- Are there syntax errors?
- Are there type errors?
- Are there missing implementations?

**How to Check:**

```bash
# Run analyzer (catches compilation errors)
flutter analyze

# Try building
flutter build apk --debug  # Android
flutter build ios --debug  # iOS
flutter build web  # Web
```

**Common Issues:**

**❌ Syntax Errors**

```dart
// ❌ BAD: Syntax error (missing comma)
class MyClass {
  final String name
  final int age  // ERROR: Missing comma
}
```

```dart
// ✅ GOOD: Correct syntax
class MyClass {
  final String name;
  final int age;
}
```

**❌ Type Errors**

```dart
// ❌ BAD: Type error
String name = 123; // ERROR: int assigned to String
```

```dart
// ✅ GOOD: Correct type
String name = '123';
// OR
String name = 123.toString();
```

**❌ Missing Implementations**

```dart
// ❌ BAD: Missing implementation
abstract class MyClass {
  void method(); // Must be implemented
}

class MySubclass extends MyClass {
  // ERROR: method() not implemented
}
```

```dart
// ✅ GOOD: Implement required methods
abstract class MyClass {
  void method();
}

class MySubclass extends MyClass {
  @override
  void method() {
    // Implementation
  }
}
```

**❌ Missing Constructors**

```dart
// ❌ BAD: Missing required constructor
class MyClass {
  final String name;
  MyClass(this.name);
}

final instance = MyClass(); // ERROR: name required
```

```dart
// ✅ GOOD: Provide required parameters
class MyClass {
  final String name;
  MyClass(this.name);
}

final instance = MyClass('name'); // OK
```

**Checklist:**

- [ ] Code compiles without errors
- [ ] No syntax errors
- [ ] No type errors
- [ ] All required methods implemented
- [ ] All required constructors provided
- [ ] All required parameters provided

### 2. Linter Errors

**What to Check:**

**Questions to Ask:**
- Are there linter warnings?
- Do we follow project standards?
- Are deprecated APIs used?

**How to Check:**

```bash
# Run analyzer (includes linter)
flutter analyze

# Fix automatically fixable issues
dart fix --apply
```

**Common Issues:**

**❌ Unused Variables/Imports**

```dart
// ❌ BAD: Unused variable
void method() {
  String unused = 'value'; // Warning: unused variable
  print('hello');
}
```

```dart
// ✅ GOOD: Remove unused variables
void method() {
  print('hello');
}
```

**❌ Deprecated APIs**

```dart
// ❌ BAD: Deprecated API
final window = WidgetsBinding.instance.window; // Deprecated
```

```dart
// ✅ GOOD: Use modern API
final view = WidgetsBinding.instance.platformDispatcher.views.first;
```

**❌ Naming Conventions Not Followed**

```dart
// ❌ BAD: Wrong naming convention
class myClass {} // Should be PascalCase
void MyMethod() {} // Should be camelCase
```

```dart
// ✅ GOOD: Follow naming conventions
class MyClass {} // PascalCase for classes
void myMethod() {} // camelCase for methods
```

**Checklist:**

- [ ] No linter warnings
- [ ] No deprecated APIs
- [ ] Naming conventions followed
- [ ] Code style consistent
- [ ] Auto-fixable issues fixed

### 3. Build Configuration

**What to Check:**

**Questions to Ask:**
- Are build configurations correct?
- Are platform-specific settings correct?
- Are build scripts working?

**How to Check:**

```bash
# Check Android build
cd android && ./gradlew assembleDebug

# Check iOS build
cd ios && pod install && xcodebuild

# Check web build
flutter build web
```

**Common Issues:**

**❌ Build Configuration Errors**

```gradle
// ❌ BAD: Android build config error
android {
  compileSdkVersion 30  // Too old
}
```

```gradle
// ✅ GOOD: Correct Android build config
android {
  compileSdkVersion 34  // Up to date
}
```

**❌ Missing Native Dependencies**

```bash
# ❌ BAD: Missing iOS pods
cd ios && pod install  # ERROR: Podfile issues
```

```bash
# ✅ GOOD: Install pods
cd ios && pod install  # Success
```

**Checklist:**

- [ ] Android build works
- [ ] iOS build works
- [ ] Web build works
- [ ] Build configurations correct
- [ ] Native dependencies installed
- [ ] Build scripts working

---

## Part 4: Loading & Initialization Review

### Overview

Loading and initialization issues cause runtime failures. This section covers:
- Dependency Injection initialization
- Service loading
- Startup sequence

### 1. Dependency Injection Initialization

**What to Check:**

**Questions to Ask:**
- Are services initialized in the correct order?
- Are async initializations handled correctly?
- Are initialization errors handled?
- Is the DI container properly initialized?

**How to Check:**

```bash
# Check initialization order in injection_container.dart
# Check for await/async issues
grep -r "registerLazySingleton.*async" lib/injection_container*.dart

# Check initialization in main.dart
grep -r "await init()" lib/main.dart
```

**Common Issues:**

**❌ Services Initialized in Wrong Order**

```dart
// ❌ BAD: Service depends on uninitialized service
sl.registerLazySingleton(() => MyService(
  otherService: sl<OtherService>(), // ERROR: OtherService not registered yet
));
sl.registerLazySingleton(() => OtherService());
```

```dart
// ✅ GOOD: Initialize dependencies first
sl.registerLazySingleton(() => OtherService());
sl.registerLazySingleton(() => MyService(
  otherService: sl<OtherService>(), // OK: OtherService already registered
));
```

**❌ Async Initialization Not Awaited**

```dart
// ❌ BAD: Async initialization not awaited
Future<void> init() async {
  registerCoreServices(sl); // ERROR: async but not awaited
}
```

```dart
// ✅ GOOD: Await async initialization
Future<void> init() async {
  await registerCoreServices(sl); // OK: awaited
}
```

**❌ Initialization Errors Not Handled**

```dart
// ❌ BAD: Initialization errors not handled
Future<void> init() async {
  await registerCoreServices(sl); // ERROR: If fails, app crashes
}
```

```dart
// ✅ GOOD: Handle initialization errors
Future<void> init() async {
  try {
    await registerCoreServices(sl);
  } catch (e, stackTrace) {
    logger.error('DI initialization failed', error: e, stackTrace: stackTrace);
    // Handle error appropriately
  }
}
```

**Checklist:**

- [ ] Services initialized in correct order
- [ ] Async initializations awaited
- [ ] Initialization errors handled
- [ ] DI container initialized before use
- [ ] Optional services handled correctly

### 2. Service Loading

**What to Check:**

**Questions to Ask:**
- Are services loaded correctly?
- Are services available when needed?
- Are loading errors handled?
- Are services properly disposed?

**How to Check:**

```bash
# Check service usage
grep -r "sl<" lib/ --include="*.dart"

# Check for missing service errors (runtime errors)
# Look for "Not registered" errors in logs
```

**Common Issues:**

**❌ Service Not Available**

```dart
// ❌ BAD: Service not registered
final service = sl<MyService>(); // ERROR: Not registered
```

```dart
// ✅ GOOD: Register service first
sl.registerLazySingleton(() => MyService());
final service = sl<MyService>(); // OK
```

**❌ Service Accessed Before Initialization**

```dart
// ❌ BAD: Service accessed before DI initialization
void main() {
  final service = sl<MyService>(); // ERROR: DI not initialized
  runApp(MyApp());
}
```

```dart
// ✅ GOOD: Initialize DI first
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init(); // Initialize DI
  final service = sl<MyService>(); // OK
  runApp(MyApp());
}
```

**Checklist:**

- [ ] Services available when needed
- [ ] Services accessed after initialization
- [ ] Service loading errors handled
- [ ] Services properly disposed
- [ ] Service lifecycle managed correctly

### 3. Startup Sequence

**What to Check:**

**Questions to Ask:**
- Is the app startup sequence correct?
- Are critical services initialized first?
- Are startup errors handled?
- Is the app usable after startup?

**How to Check:**

```bash
# Check main.dart startup
cat lib/main.dart

# Check app initialization
cat lib/app.dart
```

**Common Issues:**

**❌ Startup Sequence Incorrect**

```dart
// ❌ BAD: DI initialized after app starts
void main() {
  runApp(MyApp()); // ERROR: DI not initialized
  init(); // Too late
}
```

```dart
// ✅ GOOD: Initialize DI before app starts
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init(); // Initialize DI first
  runApp(MyApp()); // OK: DI initialized
}
```

**Checklist:**

- [ ] Startup sequence correct
- [ ] Critical services initialized first
- [ ] Startup errors handled
- [ ] App usable after startup
- [ ] No runtime crashes during startup

---

## Part 5: Code Quality Review

### Overview

Code quality issues affect maintainability and consistency. This section covers:
- Code standards (from `.cursorrules`)
- Architecture compliance
- Error handling
- Documentation

### 1. Code Standards

**What to Check:**

**Questions to Ask:**
- Does code follow project standards?
- Are naming conventions followed?
- Are design tokens used (AppColors/AppTheme)?
- Is logging done correctly (developer.log, not print)?

**How to Check:**

```bash
# Check for print() usage (should use developer.log)
grep -r "print(" lib/ --include="*.dart"

# Check for Colors.* usage (should use AppColors/AppTheme)
grep -r "Colors\\." lib/ --include="*.dart"

# Check for error handling
grep -r "catch.*{" lib/ --include="*.dart" | grep -v "developer.log"
```

**Common Issues:**

**❌ Using print() Instead of developer.log()**

```dart
// ❌ BAD: Using print()
void method() {
  print('Error occurred'); // Not proper logging
}
```

```dart
// ✅ GOOD: Using developer.log()
import 'dart:developer' as developer;

void method() {
  developer.log('Error occurred', name: 'ServiceName');
}
```

**❌ Using Colors.* Instead of AppColors/AppTheme**

```dart
// ❌ BAD: Using Colors.*
Container(
  color: Colors.blue, // Should use AppColors
)
```

```dart
// ✅ GOOD: Using AppColors/AppTheme
Container(
  color: AppColors.primary, // OK
)
```

**❌ Empty Catch Blocks**

```dart
// ❌ BAD: Empty catch block (silent failure)
try {
  await operation();
} catch (e) {
  // Silent failure
}
```

```dart
// ✅ GOOD: Log errors and provide feedback
try {
  await operation();
} catch (e, stackTrace) {
  developer.log('Operation failed', error: e, stackTrace: stackTrace, name: 'ServiceName');
  // Provide user feedback
}
```

**Checklist:**

- [ ] Logging uses `developer.log()` (not `print()`)
- [ ] Design tokens used (AppColors/AppTheme, not Colors.*)
- [ ] No empty catch blocks
- [ ] Naming conventions followed
- [ ] Code style consistent

### 2. Architecture Compliance

**What to Check:**

**Questions to Ask:**
- Does code follow Clean Architecture?
- Are layers separated correctly?
- Are dependencies pointing in the right direction?
- Are patterns followed consistently?

**How to Check:**

```bash
# Check layer organization
# lib/core/ - Core business logic
# lib/data/ - Data sources, repositories
# lib/domain/ - Use cases, repository interfaces
# lib/presentation/ - UI, BLoCs, widgets
```

**Common Issues:**

**❌ Code in Wrong Layer**

```dart
// ❌ BAD: UI code in core layer
// lib/core/services/ui_service.dart
class UIService {
  Widget buildButton() { // Should be in presentation layer
    return ElevatedButton(onPressed: () {});
  }
}
```

```dart
// ✅ GOOD: UI code in presentation layer
// lib/presentation/widgets/custom_button.dart
class CustomButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: () {});
  }
}
```

**❌ Dependencies Pointing Wrong Direction**

```dart
// ❌ BAD: Core depends on presentation
// lib/core/services/business_service.dart
import 'package:avrai/presentation/pages/home_page.dart'; // ERROR: Core depends on presentation
```

```dart
// ✅ GOOD: Dependencies point in correct direction
// lib/core/services/business_service.dart
// No presentation imports
```

**Checklist:**

- [ ] Code in correct layer
- [ ] Dependencies point in correct direction (core → data → domain → presentation)
- [ ] Architecture patterns followed
- [ ] Consistent patterns across codebase

### 3. Error Handling

**What to Check:**

**Questions to Ask:**
- Are errors handled properly?
- Are errors logged?
- Are user-friendly error messages shown?
- Are errors not silently swallowed?

**How to Check:**

```bash
# Check for empty catch blocks
grep -r "catch.*{" lib/ --include="*.dart" | grep -v "developer.log"

# Check for error handling patterns
grep -r "try {" lib/ --include="*.dart"
```

**Common Issues:**

**❌ Empty Catch Blocks**

```dart
// ❌ BAD: Empty catch block (silent failure)
try {
  await operation();
} catch (e) {
  // Silent failure
}
```

```dart
// ✅ GOOD: Log errors and provide feedback
try {
  await operation();
} catch (e, stackTrace) {
  developer.log('Operation failed', error: e, stackTrace: stackTrace, name: 'ServiceName');
  showError('Something went wrong. Please try again.');
}
```

**❌ Errors Not Logged**

```dart
// ❌ BAD: Errors not logged
try {
  await operation();
} catch (e) {
  showError('Error occurred'); // Not logged
}
```

```dart
// ✅ GOOD: Errors logged with context
try {
  await operation();
} catch (e, stackTrace) {
  developer.log('Operation failed', error: e, stackTrace: stackTrace, name: 'ServiceName');
  showError('Something went wrong. Please try again.');
}
```

**Checklist:**

- [ ] Errors handled properly
- [ ] Errors logged with context
- [ ] User-friendly error messages shown
- [ ] No silent failures
- [ ] Specific error types caught when possible

### 4. Documentation

**What to Check:**

**Questions to Ask:**
- Are public APIs documented?
- Are complex logic commented?
- Are README files updated?

**Common Issues:**

**❌ Public APIs Not Documented**

```dart
// ❌ BAD: Public API not documented
class MyService {
  void method() {} // What does this do?
}
```

```dart
// ✅ GOOD: Public API documented
/// Service for handling user operations
class MyService {
  /// Performs user authentication
  /// 
  /// Returns true if authentication succeeds, false otherwise
  bool authenticate(String username, String password) {}
}
```

**Checklist:**

- [ ] Public APIs documented
- [ ] Complex logic commented
- [ ] README files updated
- [ ] Code comments explain WHY, not WHAT

---

## Part 6: Systematic Review Process

### Step-by-Step Approach

**Phase 1: Automated Checks (30 minutes)**

1. **Run analyzer:**
   ```bash
   flutter analyze > analysis_report.txt
   ```

2. **Categorize errors:**
   - Compilation errors (must fix)
   - Linter warnings (should fix)
   - Info messages (nice to fix)

3. **Create issue list:**
   - List all errors by category
   - Prioritize by impact
   - Create TODO list

**Phase 2: Dependency Review (1-2 hours)**

1. **Check DI registration:**
   - List all services
   - Check if registered
   - Check registration order
   - Check for circular dependencies

2. **Check package dependencies:**
   - Review `pubspec.yaml`
   - Check for unused packages
   - Check for version conflicts
   - Check for missing packages

3. **Check imports:**
   - Find unused imports
   - Find missing imports
   - Check import organization

**Phase 3: Build Review (1 hour)**

1. **Check compilation:**
   - Fix compilation errors
   - Fix type errors
   - Fix syntax errors

2. **Check linter:**
   - Fix linter warnings
   - Fix deprecated APIs
   - Fix code style issues

3. **Check build:**
   - Test Android build
   - Test iOS build
   - Test web build

**Phase 4: Loading Review (1 hour)**

1. **Check DI initialization:**
   - Check initialization order
   - Check async handling
   - Check error handling

2. **Check service loading:**
   - Check service availability
   - Check loading errors
   - Check service lifecycle

3. **Check startup:**
   - Check startup sequence
   - Check initialization
   - Check error handling

**Phase 5: Code Quality Review (2-3 hours)**

1. **Check standards:**
   - Check naming conventions
   - Check design tokens
   - Check logging
   - Check error handling

2. **Check architecture:**
   - Check layer organization
   - Check dependencies
   - Check patterns

3. **Check documentation:**
   - Check public API docs
   - Check code comments
   - Check README files

### Tools & Commands

**Automated Tools:**

```bash
# Analyzer (compilation + linter)
flutter analyze

# Auto-fix issues
dart fix --apply

# Check dependencies
flutter pub outdated
flutter pub deps

# Build tests
flutter build apk --debug
flutter build ios --debug
flutter build web
```

**Manual Checks:**

```bash
# Find services
grep -r "class.*Service" lib/core/services/ --include="*.dart"

# Find DI registrations
grep -r "registerLazySingleton" lib/injection_container*.dart

# Find print() usage (should be developer.log)
grep -r "print(" lib/ --include="*.dart"

# Find Colors.* usage (should be AppColors/AppTheme)
grep -r "Colors\\." lib/ --include="*.dart"

# Find empty catch blocks
grep -r "catch.*{" lib/ --include="*.dart" | grep -v "developer.log"
```

### Review Checklists

**Complete Dependency Review Checklist:**

- [ ] All services registered in DI container
- [ ] Dependencies registered before dependents
- [ ] No circular dependencies
- [ ] Services registered with correct lifecycle
- [ ] Services registered in correct container
- [ ] Optional services handled correctly
- [ ] All packages in `pubspec.yaml` are used
- [ ] All used packages are in `pubspec.yaml`
- [ ] No version conflicts
- [ ] Packages are up to date
- [ ] Imports organized correctly
- [ ] No unused imports
- [ ] No missing imports
- [ ] Import paths are correct

**Complete Build Review Checklist:**

- [ ] Code compiles without errors
- [ ] No syntax errors
- [ ] No type errors
- [ ] All required methods implemented
- [ ] No linter warnings
- [ ] No deprecated APIs
- [ ] Naming conventions followed
- [ ] Android build works
- [ ] iOS build works
- [ ] Web build works
- [ ] Build configurations correct

**Complete Loading Review Checklist:**

- [ ] Services initialized in correct order
- [ ] Async initializations awaited
- [ ] Initialization errors handled
- [ ] DI container initialized before use
- [ ] Services available when needed
- [ ] Service loading errors handled
- [ ] Startup sequence correct
- [ ] Critical services initialized first
- [ ] App usable after startup

**Complete Code Quality Checklist:**

- [ ] Logging uses `developer.log()` (not `print()`)
- [ ] Design tokens used (AppColors/AppTheme)
- [ ] No empty catch blocks
- [ ] Errors logged with context
- [ ] User-friendly error messages
- [ ] Code in correct architecture layer
- [ ] Dependencies point in correct direction
- [ ] Public APIs documented
- [ ] Complex logic commented

---

## Quick Reference

### Common Issues & Fixes

**Dependency Issues:**

| Issue | Fix |
|-------|-----|
| Service not registered | Register in `injection_container.dart` |
| Dependency registered after dependent | Reorder registrations |
| Circular dependency | Use interfaces or dependency inversion |
| Missing import | Add import statement |
| Unused import | Remove import |
| Package not in pubspec.yaml | Add to `pubspec.yaml` |
| Unused package | Remove from `pubspec.yaml` |

**Build Issues:**

| Issue | Fix |
|-------|-----|
| Compilation error | Fix syntax/type errors |
| Linter warning | Fix code style issues |
| Deprecated API | Use modern API |
| Missing package | Add to `pubspec.yaml` |
| Build configuration error | Fix platform-specific config |

**Loading Issues:**

| Issue | Fix |
|-------|-----|
| Service not available | Register service |
| Initialization order wrong | Reorder registrations |
| Async not awaited | Add `await` |
| Startup error | Handle error properly |

**Code Quality Issues:**

| Issue | Fix |
|-------|-----|
| Using `print()` | Use `developer.log()` |
| Using `Colors.*` | Use `AppColors/AppTheme` |
| Empty catch block | Add error logging |
| Code in wrong layer | Move to correct layer |
| Public API not documented | Add documentation |

### Priority Order

**1. Critical (Must Fix):**
- Compilation errors
- Service not registered (runtime crashes)
- Missing dependencies (build fails)

**2. High (Should Fix):**
- Linter warnings
- Dependency registration order
- Import issues
- Initialization errors

**3. Medium (Nice to Fix):**
- Code quality issues (print vs developer.log)
- Documentation
- Architecture compliance

**4. Low (Can Fix Later):**
- Code style
- Naming conventions
- Comments

### Next Steps

1. **Start with Part 1:** Understand code review fundamentals
2. **Run automated checks:** Use `flutter analyze` to find issues
3. **Focus on dependencies:** Check DI registration, imports, packages
4. **Fix build issues:** Ensure code compiles
5. **Fix loading issues:** Ensure services load correctly
6. **Improve code quality:** Follow standards, architecture, patterns

**Remember:** Code review is iterative. Fix issues systematically, test after each fix, and document your findings.

---

## Related Documents

- `.cursorrules` - Project standards and checklists
- `docs/plans/compilation_fixes/` - Previous compilation fix documentation
- `README_DEVELOPMENT.md` - Development guide
- `docs/plans/security_implementation/CODE_REVIEW_REPORT.md` - Security code review example

---

**Last Updated:** January 2026  
**Status:** Active Guide
