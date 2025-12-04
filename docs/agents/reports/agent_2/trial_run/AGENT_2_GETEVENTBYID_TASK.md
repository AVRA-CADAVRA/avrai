# Agent 2: Add getEventById() Method to ExpertiseEventService

**Date:** November 22, 2025, 09:17 PM CST  
**Priority:** High - Required for Event Details Page  
**Task:** Add `getEventById()` method to ExpertiseEventService  
**When:** Task 2.5 (Event Details Page, Days 3-4 of Week 2)  
**Status:** 🟡 Pending

---

## 🎯 **What Needs to Be Done**

Add a `getEventById(String eventId)` method to `ExpertiseEventService` to fetch a single event by its ID.

---

## 📋 **Why This Is Needed**

### **1. Event Details Page Requirement**
- **Task 2.5: Event Details Page** requires displaying full event information
- The page will receive `eventId` as a route parameter (typical for detail pages)
- Need to fetch the event object to display details

### **2. registerForEvent() Requires Event Object**
- Current `registerForEvent()` signature:
  ```dart
  Future<void> registerForEvent(ExpertiseEvent event, UnifiedUser user)
  ```
- This method requires the full `ExpertiseEvent` object, not just an `eventId`
- To register for an event from the details page, you need to fetch the event first

### **3. Performance & Architecture**
- Currently, Agent 1's `PaymentService` uses a workaround:
  - Calls `searchEvents()` with no filters
  - Filters client-side to find matching event ID
  - This is inefficient (loads all events into memory)
- A proper `getEventById()` method will:
  - Use direct database query (O(1) lookup)
  - Reduce memory usage
  - Improve performance

### **4. Real-World Scenarios**
- **Deep linking:** User clicks event link from notification/email
- **Page refresh:** User refreshes event details page
- **Direct navigation:** User navigates directly to event URL
- **Post-payment:** Fetch updated event info after payment confirmation

---

## 📍 **When to Do This**

**Task 2.5: Event Details Page (Days 3-4 of Week 2)**

Add this method **before or during** Event Details Page implementation, as you'll need it to:
1. Fetch event data when the page loads with an `eventId` parameter
2. Call `registerForEvent()` which requires the event object
3. Refresh event data after registration/payment

---

## ✅ **Implementation Requirements**

### **Method Signature**
```dart
/// Get event by ID
/// 
/// Fetches a single event by its unique identifier.
/// 
/// **Parameters:**
/// - `eventId`: Unique event identifier
/// 
/// **Returns:**
/// - `ExpertiseEvent?`: The event if found, `null` if not found
/// 
/// **Throws:**
/// - `Exception` if database query fails
Future<ExpertiseEvent?> getEventById(String eventId) async {
  // Implementation
}
```

### **Implementation Steps**

1. **Add method to ExpertiseEventService:**
   - File: `lib/core/services/expertise_event_service.dart`
   - Add after `getEventsByAttendee()` method (around line 211)
   - Follow existing method patterns in the service

2. **Implementation approach:**
   ```dart
   /// Get event by ID
   Future<ExpertiseEvent?> getEventById(String eventId) async {
     try {
       _logger.info('Getting event by ID: $eventId', tag: _logName);
       
       // In production, query database directly by ID
       // For now, use _getAllEvents() and filter (same as current workaround)
       final allEvents = await _getAllEvents();
       try {
         return allEvents.firstWhere(
           (event) => event.id == eventId,
         );
       } catch (e) {
         // Event not found
         return null;
       }
     } catch (e) {
       _logger.error('Error getting event by ID', error: e, tag: _logName);
       return null;
     }
   }
   ```

3. **Production note:**
   - Current implementation uses `_getAllEvents()` (same as workaround)
   - In production, replace with direct database query by ID for better performance
   - Example: `SELECT * FROM events WHERE id = ?`

4. **Error handling:**
   - Return `null` if event not found (not an error condition)
   - Log errors for debugging
   - Don't throw exceptions for "not found" - return null

---

## 🔗 **Integration Points**

### **1. Event Details Page**
```dart
// In event_details_page.dart
final eventService = GetIt.instance<ExpertiseEventService>();
final event = await eventService.getEventById(eventId);
if (event == null) {
  // Show error: Event not found
  return;
}
// Display event details
```

### **2. Payment Service (Agent 1)**
- Once this method exists, Agent 1 can update `PaymentService._getEventById()` to use it
- This will improve performance and remove the workaround

### **3. Registration Flow**
```dart
// After fetching event
final event = await eventService.getEventById(eventId);
if (event != null) {
  await eventService.registerForEvent(event, currentUser);
}
```

---

## 📝 **File Ownership**

**File to modify:** `lib/core/services/expertise_event_service.dart`
- ✅ **You own this file** (per FILE_OWNERSHIP_MATRIX.md)
- ✅ You can modify it freely
- ✅ No coordination needed with other agents

---

## ✅ **Acceptance Criteria**

- [ ] `getEventById(String eventId)` method added to ExpertiseEventService
- [ ] Method returns `ExpertiseEvent?` (nullable)
- [ ] Returns `null` if event not found (not an error)
- [ ] Proper error handling and logging
- [ ] Method follows existing service patterns
- [ ] Method is documented with doc comments
- [ ] Event Details Page can use this method successfully
- [ ] Payment Service (Agent 1) can use this method (removes workaround)

---

## 🔄 **Coordination Notes**

### **For Agent 1:**
- Once this method is added, Agent 1 can update `PaymentService._getEventById()` to use it
- This will improve performance and remove the inefficient workaround
- Agent 1 has documented this need in PaymentService code

### **For Agent 2:**
- This is a straightforward addition to your service
- No breaking changes to existing code
- All existing methods continue to work
- This enables proper Event Details Page implementation

---

## 📚 **Reference**

### **Existing Methods to Follow:**
- `getEventsByHost()` - See how it queries events
- `getEventsByAttendee()` - See how it filters events
- `searchEvents()` - See how it uses `_getAllEvents()`

### **Current Workaround (Agent 1):**
- See `lib/core/services/payment_service.dart` line 414-460
- This shows why the method is needed
- Once you add it, Agent 1 can remove the workaround

---

## 🚀 **Quick Start**

1. Open `lib/core/services/expertise_event_service.dart`
2. Add `getEventById()` method after `getEventsByAttendee()` (around line 211)
3. Follow the implementation pattern shown above
4. Test with Event Details Page
5. Update status tracker when complete

---

**Last Updated:** November 22, 2025, 09:17 PM CST  
**Status:** Ready for Agent 2 Implementation

