# Agent Quick Reference Guide

**Date:** November 22, 2025, 8:47 PM CST  
**Purpose:** Quick reference for all agents with code examples and patterns  
**Status:** ✅ Ready for Use

---

## 🎯 **Quick Start**

Before starting work, all agents should:
1. ✅ Read their section in `docs/agents/tasks/trial_run/task_assignments.md`
2. ✅ Review this quick reference for code patterns
3. ✅ Check existing code examples below
4. ✅ Understand design token requirements
5. ✅ **Read `docs/agents/reference/date_time_format.md` - CRITICAL for all documents** ⚠️

---

## 🎨 **Design Tokens (100% Adherence Required)**

### **CRITICAL RULE:**
- ✅ **ALWAYS** use `AppColors` or `AppTheme`
- ❌ **NEVER** use direct `Colors.*`

### **Correct Usage Examples:**

```dart
// ✅ CORRECT: Using AppColors
import 'package:spots/core/theme/app_colors.dart';
import 'package:spots/core/theme/app_theme.dart';

Container(
  color: AppColors.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: AppTheme.textColor),
  ),
)

// ✅ CORRECT: Using AppTheme
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryColor,
    foregroundColor: AppColors.white,
  ),
  onPressed: () {},
  child: Text('Button'),
)

// ❌ WRONG: Direct Colors usage
Container(
  color: Colors.blue,  // ❌ NEVER DO THIS
  child: Text('Hello', style: TextStyle(color: Colors.black)),
)
```

### **Common Design Token Patterns:**

```dart
// Background colors
backgroundColor: AppColors.background
backgroundColor: AppColors.surface
backgroundColor: AppTheme.primaryColor

// Text colors
color: AppTheme.textColor
color: AppColors.textSecondary
color: AppColors.white

// Border colors
borderColor: AppColors.border
borderColor: AppTheme.dividerColor
```

---

## 📁 **File Structure Patterns**

### **Services (Agent 1):**
```dart
// File: lib/core/services/payment_service.dart
import 'package:spots/core/models/payment.dart';
import 'package:spots/core/services/stripe_service.dart';

class PaymentService {
  final StripeService _stripeService;
  
  PaymentService(this._stripeService);
  
  Future<PaymentResult> purchaseEventTicket({
    required String eventId,
    required String userId,
    required double ticketPrice,
  }) async {
    // Implementation
  }
}
```

### **Models (Agent 1):**
```dart
// File: lib/core/models/payment.dart
class Payment {
  final String id;
  final String eventId;
  final String userId;
  final double amount;
  final PaymentStatus status;
  final DateTime createdAt;
  
  Payment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });
  
  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'userId': userId,
    'amount': amount,
    'status': status.toString(),
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'],
    eventId: json['eventId'],
    userId: json['userId'],
    amount: json['amount'],
    status: PaymentStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
    ),
    createdAt: DateTime.parse(json['createdAt']),
  );
}
```

### **Pages (Agent 2, Agent 3):**
```dart
// File: lib/presentation/pages/events/events_browse_page.dart
import 'package:flutter/material.dart';
import 'package:spots/core/theme/app_colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/services/expertise_event_service.dart';

class EventsBrowsePage extends StatefulWidget {
  const EventsBrowsePage({Key? key}) : super(key: key);
  
  @override
  State<EventsBrowsePage> createState() => _EventsBrowsePageState();
}

class _EventsBrowsePageState extends State<EventsBrowsePage> {
  final ExpertiseEventService _eventService = GetIt.instance<ExpertiseEventService>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Events', style: TextStyle(color: AppTheme.textColor)),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: // Your implementation
    );
  }
}
```

### **Widgets (Agent 2, Agent 3):**
```dart
// File: lib/presentation/widgets/events/event_card_widget.dart
import 'package:flutter/material.dart';
import 'package:spots/core/theme/app_colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/models/expertise_event.dart';

class EventCardWidget extends StatelessWidget {
  final ExpertiseEvent event;
  
  const EventCardWidget({
    Key? key,
    required this.event,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Column(
        children: [
          Text(
            event.title,
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          // More implementation
        ],
      ),
    );
  }
}
```

---

## 🔧 **Existing Service Patterns**

### **ExpertiseEventService (Reference for Agent 2):**

```dart
// File: lib/core/services/expertise_event_service.dart
class ExpertiseEventService {
  Future<ExpertiseEvent> createEvent({
    required UnifiedUser host,
    required String title,
    required String description,
    required String category,
    required ExpertiseEventType eventType,
    required DateTime startTime,
    required DateTime endTime,
    List<Spot>? spots,
    String? location,
    double? latitude,
    double? longitude,
    int? maxAttendees,
    double? price,
    bool isPublic = true,
  }) async {
    // Implementation exists - Agent 2 should use this
  }
  
  Future<void> registerForEvent({
    required String eventId,
    required String userId,
  }) async {
    // Implementation exists - Agent 2 should use this
  }
  
  Future<List<ExpertiseEvent>> searchEvents({
    String? category,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Implementation exists - Agent 2 should use this
  }
}
```

### **ExpertiseService (Reference for Agent 3):**

```dart
// File: lib/core/services/expertise_service.dart
class ExpertiseService {
  Future<Map<String, ExpertiseLevel>> getUserExpertise(String userId) async {
    // Returns user's expertise by category
  }
  
  bool hasCityLevelExpertise(String userId, String category) {
    // Checks if user has City level+ expertise
  }
}
```

---

## 📦 **Dependency Injection Pattern**

### **Using GetIt (Standard Pattern):**

```dart
// In services
final ExpertiseEventService _eventService = GetIt.instance<ExpertiseEventService>();

// In pages/widgets
final PaymentService _paymentService = GetIt.instance<PaymentService>();
```

---

## 🧪 **Testing Patterns**

### **Unit Test Pattern (Agent 1, Agent 3):**

```dart
// File: test/unit/services/payment_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/payment_service.dart';

void main() {
  group('PaymentService', () {
    test('calculates revenue split correctly', () {
      // Test implementation
    });
  });
}
```

### **Widget Test Pattern (Agent 2, Agent 3):**

```dart
// File: test/widget/pages/events/events_browse_page_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/events/events_browse_page.dart';

void main() {
  testWidgets('EventsBrowsePage displays events', (WidgetTester tester) async {
    // Test implementation
  });
}
```

---

## 🚨 **Common Mistakes to Avoid**

### **1. Design Tokens:**
```dart
// ❌ WRONG
color: Colors.blue
backgroundColor: Colors.white

// ✅ CORRECT
color: AppTheme.primaryColor
backgroundColor: AppColors.background
```

### **2. Service Instantiation:**
```dart
// ❌ WRONG
final service = ExpertiseEventService(); // Don't instantiate directly

// ✅ CORRECT
final service = GetIt.instance<ExpertiseEventService>(); // Use DI
```

### **3. Model Immutability:**
```dart
// ❌ WRONG
class Payment {
  String id; // Mutable
}

// ✅ CORRECT
class Payment {
  final String id; // Immutable
}
```

### **4. Error Handling:**
```dart
// ❌ WRONG
Future<void> doSomething() async {
  await service.call(); // No error handling
}

// ✅ CORRECT
Future<void> doSomething() async {
  try {
    await service.call();
  } catch (e) {
    // Handle error appropriately
    logger.error('Error in doSomething', error: e);
    rethrow;
  }
}
```

---

## 📚 **Key Files to Reference**

### **For All Agents:**
- `lib/core/theme/app_colors.dart` - Color definitions
- `lib/core/theme/app_theme.dart` - Theme definitions
- `.cursorrules` - Project rules and standards

### **For Agent 1 (Payment Backend):**
- `lib/core/services/expertise_event_service.dart` - Event service reference
- `lib/core/models/expertise_event.dart` - Event model reference
- `lib/core/services/expertise_service.dart` - Service pattern

### **For Agent 2 (Event UI):**
- `lib/presentation/pages/home/home_page.dart` - Page structure reference
- `lib/presentation/widgets/expertise/expertise_event_widget.dart` - Widget pattern
- `lib/core/services/expertise_event_service.dart` - Service to integrate with

### **For Agent 3 (Expertise UI):**
- `lib/presentation/widgets/expertise/expertise_event_widget.dart` - Widget pattern
- `lib/core/services/expertise_service.dart` - Service to integrate with
- `lib/core/models/expertise.dart` - Expertise model reference

---

## 🔍 **How to Find Existing Code**

### **Search for Services:**
```bash
# Find service files
grep -r "class.*Service" lib/core/services/

# Find model files
grep -r "class.*" lib/core/models/
```

### **Search for Widgets:**
```bash
# Find widget files
find lib/presentation/widgets -name "*_widget.dart"

# Find page files
find lib/presentation/pages -name "*_page.dart"
```

---

## ✅ **Quality Checklist**

Before marking a task complete, verify:

- [ ] All code uses `AppColors`/`AppTheme` (NO `Colors.*`)
- [ ] Services use dependency injection (GetIt)
- [ ] Models are immutable (all fields `final`)
- [ ] Error handling is implemented
- [ ] Code follows existing patterns
- [ ] No linter errors
- [ ] Files are in correct locations
- [ ] Integration with existing services works

---

## 📞 **When to Ask for Help**

Ask for clarification if:
- ❓ Unclear which existing service to use
- ❓ Unclear file location
- ❓ Existing code conflicts with requirements
- ❓ Design token usage is unclear
- ❓ Integration point is unclear

**Don't guess - ask for clarification!**

---

## 🎯 **Quick Reference by Agent**

### **Agent 1 (Payment Backend):**
- Focus: Services, Models, Integration
- Key Files: `payment_service.dart`, `stripe_service.dart`, `payment.dart`
- Patterns: Service pattern, Model pattern, Error handling

### **Agent 2 (Event UI):**
- Focus: Pages, Widgets, User Experience
- Key Files: `events_browse_page.dart`, `event_details_page.dart`, `create_event_page.dart`
- Patterns: Page pattern, Widget pattern, Design tokens

### **Agent 3 (Expertise UI & Testing):**
- Focus: Widgets, Testing, Quality Assurance
- Key Files: `expertise_display_widget.dart`, `expertise_dashboard_page.dart`
- Patterns: Widget pattern, Test pattern, Design tokens

---

**Last Updated:** November 22, 2025, 8:47 PM CST  
**Status:** Ready for Use

