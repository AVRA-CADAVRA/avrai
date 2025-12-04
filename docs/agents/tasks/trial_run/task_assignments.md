# Agent Task Assignments - MVP Core (Weeks 1-4)

**Date:** November 22, 2025, 8:40 PM CST  
**Purpose:** Specific task assignments for 3 agents working in parallel  
**Usage:** Copy the agent section and use as prompt: "[AGENT_X_SECTION] you are agent X, follow the task exactly as written."

---

## 🎯 **Overview**

This document provides specific, actionable task assignments for 3 agents working on **MVP Core features (Weeks 1-4)**. This is a **TRIAL RUN** - if successful, we'll continue with the remaining Master Plan phases.

**Trial Run Scope:** Weeks 1-4 (MVP Core) = 20% of total Master Plan  
**Total Master Plan:** 20 weeks (Weeks 1-20)  
**Trial Run Reference:** `docs/TRIAL_RUN_SCOPE.md` - See what's included and what comes after

**Master Plan Reference:** `docs/MASTER_PLAN.md` (Weeks 1-4: MVP Core Functionality)  
**MVP Analysis Reference:** `docs/MVP_CRITICAL_ANALYSIS.md`  
**Quick Reference Guide:** `docs/agents/reference/quick_reference.md` - **READ THIS FIRST** for code examples and patterns

---

## 📖 **Before Starting Work**

**All agents MUST read:**
1. ✅ This task assignment document (your agent section)
2. ✅ `docs/agents/reference/quick_reference.md` - Code examples, patterns, design tokens
3. ✅ `docs/MASTER_PLAN.md` - Overall context
4. ✅ `.cursorrules` - Project rules and standards

**This ensures clarity and consistency across all agents.**

---

## 📋 **Agent Roles**

- **Agent 1:** Payment Processing & Revenue (Backend + Integration)
- **Agent 2:** Event Discovery & Hosting UI (Frontend)
- **Agent 3:** Expertise UI & Testing (Frontend + Quality Assurance)

---

## 🔄 **Coordination Protocol**

### **Can All Agents Start Simultaneously? YES, with Coordination**

**✅ All 3 agents CAN start at the same time, but with this strategy:**

1. **Agent 1 (Payment Backend):** Start immediately - no dependencies
2. **Agent 2 (Event UI):** Start with Event Discovery UI (Week 2 tasks) - no dependencies, can work in parallel
3. **Agent 3 (Expertise UI):** Start immediately - no dependencies, completely independent

**⚠️ Critical Coordination:**
- Agent 2's **payment UI** (Week 1, Task 2.3) must wait for Agent 1's payment models (Day 2)
- Agent 2 should start with **Event Discovery UI** (Week 2 tasks) instead of payment UI
- Agent 3 can work completely independently Weeks 1-3
- Week 4 requires all agents to coordinate for integration testing

### **Recommended Parallel Start Strategy:**

**Week 1 (All Start Simultaneously):**
- **Agent 1:** Payment backend (Days 1-5) - CRITICAL PATH
- **Agent 2:** Start Event Discovery UI early (Week 2 tasks, Days 1-5) - Can work in parallel
- **Agent 3:** Expertise UI (Days 1-5) - Completely independent

**Week 2:**
- **Agent 1:** Backend improvements (Days 1-5)
- **Agent 2:** Continue Event Discovery UI (Days 1-5) - Then do payment UI after Agent 1's models ready
- **Agent 3:** Expertise unlock indicator (Days 1-5)

**Week 3:**
- **Agent 1:** Service improvements (Days 1-5)
- **Agent 2:** Event Hosting UI (Days 1-5)
- **Agent 3:** Test planning (Days 1-5)

**Week 4:**
- **Agent 1:** Integration testing support (Days 1-5)
- **Agent 2:** UI polish (Days 1-5)
- **Agent 3:** Integration testing (Days 1-5) - Coordinates with Agents 1 & 2

### **Daily Sync Points:**
1. **Model Definitions:** Agent 1 shares payment models when complete (Day 2)
2. **Integration Points:** Agents share service interfaces and integration points
3. **Design Tokens:** All agents verify `AppColors`/`AppTheme` usage (100% adherence required)
4. **Progress Updates:** Update Master Plan progress daily

### **Critical Dependencies:**
- **Week 1 Day 2:** Agent 1 must define payment models before Agent 2 can build payment UI
- **Week 2:** Agent 2 needs existing `ExpertiseEventService` (already exists) ✅
- **Week 3:** Agent 2 needs payment models from Agent 1 for event hosting integration ✅ (already done Week 1)
- **Week 4:** Agent 3 needs all features complete for integration testing (coordinate daily)

---

# 🤖 **AGENT 1: Payment Processing & Revenue**

**Role:** Backend & Integration  
**Focus:** Payment processing, Stripe integration, revenue splits, integration testing

---

## **PHASE 1: Payment Processing Foundation**

### **Section 1: Stripe Integration Setup**

**Objective:** Set up Stripe integration for event ticket purchases.

**Steps:**
1. Add Stripe Flutter package to `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_stripe: ^latest_version
   ```

2. Create payment service file: `lib/core/services/payment_service.dart`
   - Implement `PaymentService` class
   - Initialize Stripe with publishable key
   - Handle Stripe initialization errors

3. Create Stripe service file: `lib/core/services/stripe_service.dart`
   - Implement `StripeService` class
   - Methods: `initializeStripe()`, `createPaymentIntent()`, `confirmPayment()`
   - Handle payment errors and edge cases

4. Add Stripe configuration to environment/config:
   - Create `lib/core/config/stripe_config.dart`
   - Store publishable key (use environment variables for production)
   - Add secret key handling for backend (if needed)

**Deliverables:**
- ✅ `lib/core/services/payment_service.dart` (complete)
- ✅ `lib/core/services/stripe_service.dart` (complete)
- ✅ `lib/core/config/stripe_config.dart` (complete)
- ✅ Stripe package added to `pubspec.yaml`

**Acceptance Criteria:**
- Stripe initializes without errors
- Payment service can create payment intents
- Error handling for network failures
- Follows architecture: ai2ai only, offline-first considerations

---

### **Section 2: Payment Models**

**⚠️ DEPENDENCY:** Agent 2 needs this for Payment UI. Update `docs/agents/status/status_tracker.md` when complete.

**Objective:** Create data models for payment processing.

**Steps:**
1. Create payment model: `lib/core/models/payment.dart`
   ```dart
   class Payment {
     final String id;
     final String eventId;
     final String userId;
     final double amount;
     final PaymentStatus status;
     final DateTime createdAt;
     final String? stripePaymentIntentId;
     // ... complete model
   }
   ```

2. Create payment intent model: `lib/core/models/payment_intent.dart`
   - Store Stripe payment intent data
   - Track payment status

3. Create revenue split model: `lib/core/models/revenue_split.dart`
   ```dart
   class RevenueSplit {
     final String eventId;
     final double totalAmount;
     final double platformFee; // 10% to SPOTS
     final double processingFee; // ~3% to Stripe
     final double hostPayout; // Remaining to host
     final DateTime calculatedAt;
     // ... complete model
   }
   ```

4. Add enums: `lib/core/models/payment_status.dart`
   - `PaymentStatus`: pending, processing, completed, failed, refunded

**Deliverables:**
- ✅ `lib/core/models/payment.dart`
- ✅ `lib/core/models/payment_intent.dart`
- ✅ `lib/core/models/revenue_split.dart`
- ✅ `lib/core/models/payment_status.dart`

**Acceptance Criteria:**
- All models are immutable (use `final`)
- Models include proper serialization (JSON)
- Models follow existing codebase patterns
- Models are properly documented

**⚠️ COORDINATION:** Share these models with Agent 2 immediately after completion.

---

### **Task 1.3: Payment Service Implementation (Days 3-4)**

**Objective:** Implement payment processing service.

**Steps:**
1. Implement `purchaseEventTicket()` method in `PaymentService`:
   ```dart
   Future<PaymentResult> purchaseEventTicket({
     required String eventId,
     required String userId,
     required double ticketPrice,
     required int quantity,
   }) async {
     // 1. Validate event exists and has capacity
     // 2. Create Stripe payment intent
     // 3. Calculate revenue split
     // 4. Save payment record
     // 5. Return payment result
   }
   ```

2. Implement revenue split calculation:
   ```dart
   RevenueSplit calculateRevenueSplit({
     required double totalAmount,
   }) {
     // Platform fee: 10%
     // Processing fee: ~2.9% + $0.30 per transaction
     // Host payout: remaining amount
   }
   ```

3. Implement payment confirmation:
   - Handle successful payments
   - Handle failed payments
   - Update event attendee count
   - Save payment records

4. Add error handling:
   - Network errors
   - Stripe API errors
   - Validation errors
   - Insufficient capacity errors

**Deliverables:**
- ✅ `PaymentService.purchaseEventTicket()` implemented
- ✅ `PaymentService.calculateRevenueSplit()` implemented
- ✅ Payment confirmation flow implemented
- ✅ Error handling complete

**Acceptance Criteria:**
- Payment flow works end-to-end
- Revenue split calculation is accurate (10% platform, ~3% processing, 87% host)
- Error handling covers all edge cases
- Follows offline-first architecture (handle offline gracefully)

---

### **Task 1.4: Basic Revenue Split Calculation (Day 5)**

**Objective:** Finalize revenue split logic and prepare for integration.

**Steps:**
1. Test revenue split calculation with various amounts:
   - $25 ticket
   - $50 ticket
   - $100 ticket
   - Verify calculations are correct

2. Create payout service stub: `lib/core/services/payout_service.dart`
   - Method: `schedulePayout()` (for future implementation)
   - Method: `getHostEarnings()` (calculate total earnings)

3. Integration preparation:
   - Document payment service API
   - Create integration examples
   - Prepare for Agent 2 integration

**Deliverables:**
- ✅ Revenue split calculation tested and verified
- ✅ `PayoutService` stub created
- ✅ Integration documentation

**Acceptance Criteria:**
- Revenue splits calculate correctly for all test cases
- Service is ready for frontend integration
- Documentation is clear for Agent 2

**⚠️ COORDINATION:** Update `docs/agents/status/status_tracker.md` - mark Section 2 as complete. Agent 2 can now start building payment UI.

---

## **PHASE 2: Backend Improvements & Integration Prep**

### **Task 2.1: Review Event Service Integration (Days 1-2)**

**Objective:** Ensure event service is ready for payment integration.

**Steps:**
1. Review `lib/core/services/expertise_event_service.dart`:
   - Verify `registerForEvent()` method exists
   - Check if payment integration points are needed
   - Document integration requirements

2. Add payment integration to event registration:
   - Update `registerForEvent()` to accept payment information
   - Handle paid vs free events
   - Update attendee count after payment

3. Create integration tests:
   - Test event registration with payment
   - Test event registration without payment (free events)
   - Test capacity limits

**Deliverables:**
- ✅ Event service reviewed and documented
- ✅ Payment integration points added (if needed)
- ✅ Integration tests created

**Acceptance Criteria:**
- Event service supports payment integration
- Free events still work without payment
- Capacity limits are enforced

---

### **Task 2.2: Payment-Event Integration (Days 3-4)**

**Objective:** Integrate payment system with event system.

**Steps:**
1. Update `ExpertiseEvent` model (if needed):
   - Ensure `price` field exists
   - Ensure `isPaid` field exists
   - Ensure `maxAttendees` field exists

2. Create payment-event bridge service: `lib/core/services/payment_event_service.dart`
   - Method: `processEventPayment()` (combines payment + registration)
   - Method: `refundEventPayment()` (stub for future)
   - Handle payment success → event registration

3. Add payment status to event registration:
   - Track payment status in event attendees
   - Handle payment failures gracefully

**Deliverables:**
- ✅ Payment-event integration complete
- ✅ `PaymentEventService` created
- ✅ Payment status tracking in events

**Acceptance Criteria:**
- Payment and event registration work together
- Payment failures don't break event registration
- Free events work without payment flow

---

### **Task 2.3: Integration Documentation (Day 5)**

**Objective:** Document integration points for other agents.

**Steps:**
1. Create integration guide: `docs/INTEGRATION_PAYMENT_EVENTS.md`
   - Document payment service API
   - Document event service integration
   - Provide code examples

2. Update Master Plan progress:
   - Mark Week 1 complete
   - Update Week 2 progress

**Deliverables:**
- ✅ Integration documentation complete
- ✅ Master Plan updated

**Acceptance Criteria:**
- Documentation is clear and complete
- Other agents can integrate easily

---

## **WEEK 3: Service Improvements & Testing Prep**

### **Task 3.1: Event Hosting Service Review (Days 1-2)**

**Objective:** Ensure event hosting service is ready for UI integration.

**Steps:**
1. Review `ExpertiseEventService.createEvent()`:
   - Verify all required parameters
   - Check validation logic
   - Document API for Agent 2

2. Add any missing validation:
   - Event date validation
   - Capacity validation
   - Price validation (if paid event)

3. Create service tests:
   - Test event creation
   - Test validation errors
   - Test expertise requirements

**Deliverables:**
- ✅ Event hosting service reviewed
- ✅ Validation improved (if needed)
- ✅ Service tests created

**Acceptance Criteria:**
- Event service is ready for UI integration
- Validation covers all edge cases

---

### **Task 3.2: Integration Testing Preparation (Days 3-4)**

**Objective:** Prepare for Week 4 integration testing.

**Steps:**
1. Create integration test plan: `docs/INTEGRATION_TEST_PLAN.md`
   - List all test scenarios
   - Define success criteria
   - Document test data requirements

2. Set up test infrastructure:
   - Create test helpers
   - Set up mock services (if needed)
   - Prepare test data

3. Create test checklist:
   - Payment flow tests
   - Event discovery tests
   - Event hosting tests
   - End-to-end flow tests

**Deliverables:**
- ✅ Integration test plan complete
- ✅ Test infrastructure ready
- ✅ Test checklist created

**Acceptance Criteria:**
- Test plan covers all MVP features
- Test infrastructure is ready
- Agent 3 can execute tests in Week 4

---

### **Task 3.3: Bug Fixes & Polish (Day 5)**

**Objective:** Fix any issues found during Week 3.

**Steps:**
1. Review code for issues:
   - Linter errors
   - Logic errors
   - Performance issues

2. Fix identified issues
3. Update documentation

**Deliverables:**
- ✅ All issues fixed
- ✅ Code polished
- ✅ Documentation updated

---

## **WEEK 4: Integration Testing**

### **Task 4.1: Payment Flow Testing (Days 1-2)**

**Objective:** Test complete payment flow end-to-end.

**Steps:**
1. Test payment purchase flow:
   - Create test event
   - Purchase ticket
   - Verify payment success
   - Verify event registration
   - Verify revenue split calculation

2. Test payment failures:
   - Network failures
   - Insufficient funds
   - Invalid card
   - Event capacity exceeded

3. Document test results

**Deliverables:**
- ✅ Payment flow tests complete
- ✅ Test results documented
- ✅ Issues identified and fixed

**Acceptance Criteria:**
- All payment flows work correctly
- Error handling works properly
- Revenue splits are accurate

---

### **Task 4.2: Full Integration Testing (Days 3-4)**

**Objective:** Test complete MVP flow with Agent 3.

**Steps:**
1. Coordinate with Agent 3 on integration tests
2. Test complete user journey:
   - Discover event (Agent 2's work)
   - Register for event (with payment)
   - Host event (Agent 2's work)
   - View expertise (Agent 3's work)

3. Fix integration issues
4. Document test results

**Deliverables:**
- ✅ Full integration tests complete
- ✅ All issues fixed
- ✅ Test results documented

**Acceptance Criteria:**
- Complete MVP flow works end-to-end
- All features integrate properly
- No critical bugs remain

---

### **Task 4.3: Final Polish & Documentation (Day 5)**

**Objective:** Finalize Week 4 work.

**Steps:**
1. Final code review
2. Update Master Plan (mark Week 4 complete)
3. Create completion report

**Deliverables:**
- ✅ Week 4 complete
- ✅ Master Plan updated
- ✅ Completion report created

---

# 🎨 **AGENT 2: Event Discovery & Hosting UI**

**Role:** Frontend & UX  
**Focus:** Event discovery UI, event hosting UI, user experience

---

## **WEEK 1: Event Discovery UI (Early Start - Parallel with Agent 1)**

**⚠️ PARALLEL START STRATEGY:** Start with Event Discovery UI (Week 2 tasks) instead of payment UI. Payment UI can be done later after Agent 1's models are ready.

### **Task 2.1: Event Discovery UI - Early Start (Days 1-5)**

**Objective:** Start Event Discovery UI early to work in parallel with Agent 1. This has no dependencies and can be done immediately.

**Steps:**
1. Review existing event service: `lib/core/services/expertise_event_service.dart`
2. Review existing event model: `lib/core/models/expertise_event.dart`
3. Start Event Browse page (Task 2.4 from Week 2)
4. Start Event Details page (Task 2.5 from Week 2)
5. Start "My Events" page (Task 2.6 from Week 2)

**Note:** This allows Agent 2 to work productively while Agent 1 builds payment backend. Payment UI (Task 2.3) can be done after Agent 1's models are ready (Day 2+).

**⚠️ COORDINATION:** Check with Agent 1 on Day 2 if payment models are ready. If ready, you can also start payment UI. Otherwise, continue with Event Discovery UI.

---

### **Task 2.2: Payment UI Components (Days 2-5) - AFTER Agent 1 Models Ready**

**⚠️ DEPENDENCY:** This task requires Agent 1's payment models (Task 1.2) to be complete. Start this AFTER Agent 1 shares payment models (Day 2).

**Objective:** Create payment UI components for event ticket purchases.

**Steps:**
1. Create payment checkout page: `lib/presentation/pages/payment/checkout_page.dart`
   - Display event details
   - Show ticket price
   - Show quantity selector
   - Display total amount
   - **CRITICAL:** Use `AppColors`/`AppTheme` (100% adherence required)

2. Create payment form widget: `lib/presentation/widgets/payment/payment_form_widget.dart`
   - Card input fields (use Stripe's card input widget)
   - Payment button
   - Error display
   - Loading states

3. Create payment success page: `lib/presentation/pages/payment/payment_success_page.dart`
   - Success message
   - Event details
   - Registration confirmation

4. Create payment failure page: `lib/presentation/pages/payment/payment_failure_page.dart`
   - Error message
   - Retry button
   - Support information

5. Integrate with `PaymentService` (from Agent 1):
   - Call `purchaseEventTicket()` on form submit
   - Handle payment success
   - Handle payment failures
   - Show loading states

**Deliverables:**
- ✅ `lib/presentation/pages/payment/checkout_page.dart`
- ✅ `lib/presentation/widgets/payment/payment_form_widget.dart`
- ✅ `lib/presentation/pages/payment/payment_success_page.dart`
- ✅ `lib/presentation/pages/payment/payment_failure_page.dart`
- ✅ Payment UI integrated with `PaymentService`

**Acceptance Criteria:**
- Payment UI uses `AppColors`/`AppTheme` (NO direct `Colors.*` usage)
- Payment flow works with Agent 1's payment service
- Error handling displays properly
- Loading states work correctly
- UI is responsive and follows design guidelines

**⚠️ COORDINATION:** Test payment UI with Agent 1's payment service.

---

## **WEEK 2: Event Discovery UI (Continue) + Payment UI (If Not Done)**

**Note:** If you started Event Discovery UI in Week 1, continue with remaining tasks. If payment models are ready, also work on payment UI.

### **Task 2.3: Payment UI Components (If Not Done in Week 1)**

**Objective:** Complete payment UI if Agent 1's models are ready and you haven't done this yet.

**Steps:** See Task 2.2 above.

---

### **Task 2.4: Event Browse/Search Page (Days 1-2) - Continue if Started Week 1**

**Objective:** Create event discovery page where users can browse and search events.

**Steps:**
1. Create event browse page: `lib/presentation/pages/events/events_browse_page.dart`
   - List view of events
   - Event cards (use existing `ExpertiseEventWidget` if available)
   - Pull-to-refresh
   - **CRITICAL:** Use `AppColors`/`AppTheme` (100% adherence required)

2. Add search functionality:
   - Search bar
   - Search by event title
   - Search by category
   - Search by location

3. Add filters:
   - Category filter (dropdown or chips)
   - Location filter
   - Date filter (upcoming, this week, this month)
   - Price filter (free, paid)

4. Integrate with `ExpertiseEventService`:
   - Call `searchEvents()` method
   - Display search results
   - Handle empty states
   - Handle loading states

5. Add pagination or infinite scroll:
   - Load more events as user scrolls
   - Show loading indicator

**Deliverables:**
- ✅ `lib/presentation/pages/events/events_browse_page.dart`
- ✅ Search functionality
- ✅ Filter functionality
- ✅ Integration with `ExpertiseEventService`
- ✅ Pagination/infinite scroll

**Acceptance Criteria:**
- Events display correctly
- Search works properly
- Filters work correctly
- UI uses `AppColors`/`AppTheme` (NO direct `Colors.*`)
- Empty states handled
- Loading states work

---

### **Task 2.5: Event Details Page (Days 3-4)**

**Objective:** Create event details page with full event information and registration.

**Steps:**
1. Create event details page: `lib/presentation/pages/events/event_details_page.dart`
   - Display full event information:
     - Event title
     - Event description
     - Host information (with expertise pins)
     - Date and time
     - Location
     - Price (if paid event)
     - Max attendees / Current attendees
     - Event category
     - Event type (Tour, Workshop, etc.)
   - **CRITICAL:** Use `AppColors`/`AppTheme` (100% adherence required)

2. Add registration button:
   - "Register" button (if free event)
   - "Purchase Ticket" button (if paid event)
   - "Already Registered" state
   - "Event Full" state
   - "Event Cancelled" state

3. Integrate registration:
   - Free events: Call `ExpertiseEventService.registerForEvent()`
   - Paid events: Navigate to checkout page (from Week 1)
   - Handle registration success
   - Handle registration failures

4. Add event actions:
   - Share event
   - Add to calendar
   - Report event (if needed)

5. Display event spots (if event includes spots):
   - Show list of spots
   - Link to spot details

**Deliverables:**
- ✅ `lib/presentation/pages/events/event_details_page.dart`
- ✅ Registration functionality
- ✅ Payment integration (for paid events)
- ✅ Event actions (share, calendar)

**Acceptance Criteria:**
- Event details display correctly
- Registration works for free events
- Payment flow works for paid events (integrates with Week 1 work)
- UI uses `AppColors`/`AppTheme` (NO direct `Colors.*`)
- All event states handled properly

---

### **Task 2.6: "My Events" Page (Day 5)**

**Objective:** Create page showing user's hosted and attending events.

**Steps:**
1. Create "My Events" page: `lib/presentation/pages/events/my_events_page.dart`
   - Tab 1: "Hosting" (events user is hosting)
   - Tab 2: "Attending" (events user is registered for)
   - Tab 3: "Past" (past events)
   - **CRITICAL:** Use `AppColors`/`AppTheme` (100% adherence required)

2. Display hosted events:
   - List of events user is hosting
   - Show attendee count
   - Show registration status
   - Link to event management (future feature)

3. Display attending events:
   - List of events user is registered for
   - Show event date
   - Show payment status (if paid event)
   - Link to event details

4. Display past events:
   - List of past events (hosted or attended)
   - Show event date
   - Link to event details

5. Integrate with `ExpertiseEventService`:
   - Call `getEventsByHost()` for hosted events
   - Call `getEventsByAttendee()` for attending events
   - Filter by date for past events

**Deliverables:**
- ✅ `lib/presentation/pages/events/my_events_page.dart`
- ✅ Hosted events display
- ✅ Attending events display
- ✅ Past events display
- ✅ Integration with `ExpertiseEventService`

**Acceptance Criteria:**
- All event lists display correctly
- Tabs work properly
- Integration with event service works
- UI uses `AppColors`/`AppTheme` (NO direct `Colors.*`)
- Empty states handled

---

### **Task 2.7: Replace "Coming Soon" Placeholder (Day 5)**

**Objective:** Replace placeholder in Events tab with actual event discovery.

**Steps:**
1. Find Events tab placeholder: `lib/presentation/pages/home/home_page.dart`
   - Look for `EventsSubTab` widget
   - Currently shows "Coming Soon" message

2. Replace with navigation to Events Browse page:
   - Remove placeholder
   - Add navigation to `EventsBrowsePage`
   - Or embed `EventsBrowsePage` directly in tab

3. Test navigation:
   - Verify Events tab shows event browse page
   - Verify navigation works correctly

**Deliverables:**
- ✅ Events tab shows event browse page
- ✅ "Coming Soon" placeholder removed
- ✅ Navigation works correctly

**Acceptance Criteria:**
- Events tab displays event discovery UI
- Navigation is smooth
- No placeholder text remains

---

## **WEEK 3: Easy Event Hosting UI**

### **Task 2.8: Event Creation Form (Days 1-2)**

**Objective:** Create simple event creation form for users to host events.

**Steps:**
1. Create event creation page: `lib/presentation/pages/events/create_event_page.dart`
   - Form fields:
     - Event title (required)
     - Event description (required)
     - Category (dropdown, required)
     - Event type (Tour, Workshop, Tasting, etc.)
     - Start date/time (date picker, required)
     - End date/time (date picker, required)
     - Location (text input, required)
     - Max attendees (number input, optional)
     - Price (number input, optional - if set, event is paid)
     - Public/Private toggle
   - **CRITICAL:** Use `AppColors`/`AppTheme` (100% adherence required)

2. Add form validation:
   - Required field validation
   - Date validation (end after start)
   - Price validation (non-negative)
   - Capacity validation (positive number)

3. Add expertise check:
   - Verify user has City level+ expertise in selected category
   - Show error if user doesn't have required expertise
   - Display expertise level to user

4. Integrate with `ExpertiseEventService`:
   - Call `createEvent()` on form submit
   - Handle creation success
   - Handle creation failures
   - Show loading states

**Deliverables:**
- ✅ `lib/presentation/pages/events/create_event_page.dart`
- ✅ Form validation
- ✅ Expertise verification
- ✅ Integration with `ExpertiseEventService`

**Acceptance Criteria:**
- Form works correctly
- Validation covers all fields
- Expertise check works
- Event creation works
- UI uses `AppColors`/`AppTheme` (NO direct `Colors.*`)
- Error handling works properly

---

### **Task 2.9: Template Selection UI (Day 3)**

**Objective:** Add event template selection to make event creation easier.

**Steps:**
1. Review existing template service: `lib/core/services/event_template_service.dart`
2. Create template selection widget: `lib/presentation/widgets/events/template_selection_widget.dart`
   - Display available templates
   - Template cards with preview
   - "Use Template" button
   - **CRITICAL:** Use `AppColors`/`AppTheme` (100% adherence required)

3. Integrate with event creation form:
   - Add template selection step before form
   - Pre-fill form with template data
   - Allow user to edit template data

4. Add template categories:
   - Filter templates by category
   - Show popular templates

**Deliverables:**
- ✅ `lib/presentation/widgets/events/template_selection_widget.dart`
- ✅ Template integration with creation form
- ✅ Template categories

**Acceptance Criteria:**
- Template selection works
- Templates pre-fill form correctly
- UI uses `AppColors`/`AppTheme` (NO direct `Colors.*`)

---

### **Task 2.10: Quick Builder Polish (Day 4)**

**Objective:** Improve existing Quick Event Builder page.

**Steps:**
1. Review existing Quick Builder: `lib/presentation/pages/events/quick_event_builder_page.dart`
2. Improve UI/UX:
   - Better layout
   - Better form fields
   - Better validation feedback
   - Better loading states
   - **CRITICAL:** Use `AppColors`/`AppTheme` (100% adherence required)

3. Improve integration:
   - Ensure integration with `ExpertiseEventService` works
   - Ensure integration with `EventTemplateService` works
   - Fix any bugs

4. Add "Host Again" feature (if not already implemented):
   - Allow users to duplicate previous events
   - Pre-fill form with previous event data
   - Allow editing before publishing

**Deliverables:**
- ✅ Quick Builder improved
- ✅ Integration verified
- ✅ "Host Again" feature (if needed)

**Acceptance Criteria:**
- Quick Builder works smoothly
- UI is polished
- Integration works correctly
- UI uses `AppColors`/`AppTheme` (NO direct `Colors.*`)

---

### **Task 2.11: Event Publishing Flow (Day 5)**

**Objective:** Create event publishing flow with review and confirmation.

**Steps:**
1. Create event review page: `lib/presentation/pages/events/event_review_page.dart`
   - Display all event details for review
   - Allow editing before publishing
   - Show expertise requirements
   - **CRITICAL:** Use `AppColors`/`AppTheme` (100% adherence required)

2. Add publish confirmation:
   - "Publish Event" button
   - Confirmation dialog
   - Success message

3. Add success page: `lib/presentation/pages/events/event_published_page.dart`
   - Success message
   - Event details
   - "View Event" button
   - "Share Event" button

4. Integrate with event creation:
   - Call `ExpertiseEventService.createEvent()` on publish
   - Handle success
   - Handle failures
   - Navigate to success page

**Deliverables:**
- ✅ `lib/presentation/pages/events/event_review_page.dart`
- ✅ `lib/presentation/pages/events/event_published_page.dart`
- ✅ Publishing flow complete

**Acceptance Criteria:**
- Review page works correctly
- Publishing works
- Success page displays properly
- UI uses `AppColors`/`AppTheme` (NO direct `Colors.*`)

---

## **WEEK 4: UI Polish & Integration**

### **Task 2.12: UI Polish (Days 1-2)**

**Objective:** Polish all UI components created in Weeks 1-3.

**Steps:**
1. Review all pages created:
   - Payment pages
   - Event discovery pages
   - Event hosting pages

2. Fix any UI issues:
   - Layout issues
   - Spacing issues
   - Color issues (verify `AppColors`/`AppTheme` usage)
   - Typography issues

3. Add animations:
   - Page transitions
   - Loading animations
   - Success animations

4. Improve accessibility:
   - Add semantic labels
   - Improve contrast
   - Add keyboard navigation

**Deliverables:**
- ✅ All UI polished
- ✅ Animations added
- ✅ Accessibility improved

**Acceptance Criteria:**
- UI is polished and professional
- All pages use `AppColors`/`AppTheme` (NO direct `Colors.*`)
- Animations are smooth
- Accessibility is improved

---

### **Task 2.13: Integration Testing Support (Days 3-4)**

**Objective:** Support Agent 3's integration testing.

**Steps:**
1. Coordinate with Agent 3 on test scenarios
2. Fix any UI issues found during testing
3. Ensure all pages work correctly in integration tests

**Deliverables:**
- ✅ UI issues fixed
- ✅ Integration tests pass

**Acceptance Criteria:**
- All UI works in integration tests
- No blocking UI issues

---

### **Task 2.14: Final Documentation (Day 5)**

**Objective:** Document all UI work completed.

**Steps:**
1. Update Master Plan progress
2. Create UI documentation:
   - List all pages created
   - Document navigation flow
   - Document integration points

**Deliverables:**
- ✅ Master Plan updated
- ✅ UI documentation complete

---

# 🧪 **AGENT 3: Expertise UI & Testing**

**Role:** Frontend & Quality Assurance  
**Focus:** Expertise UI, integration testing, quality assurance

---

## **WEEK 1: Basic Expertise UI (Early Start)**

### **Task 3.1: Review Expertise System (Day 1)**

**Objective:** Understand existing expertise system before building UI.

**Steps:**
1. Review expertise service: `lib/core/services/expertise_service.dart`
2. Review expertise model: `lib/core/models/expertise.dart`
3. Review expertise levels: City, Regional, National, Global
4. Document expertise system for UI implementation

**Deliverables:**
- ✅ Expertise system understood
- ✅ Documentation created

**Acceptance Criteria:**
- Clear understanding of expertise system
- Ready to build UI

---

### **Task 3.2: Expertise Display Widget (Days 2-3)**

**Objective:** Create widget to display user's expertise levels.

**Steps:**
1. Create expertise display widget: `lib/presentation/widgets/expertise/expertise_display_widget.dart`
   - Display expertise levels (City, Regional, National, Global)
   - Display category expertise
   - Show progress indicators
   - **CRITICAL:** Use `AppColors`/`AppTheme` (100% adherence required)

2. Add expertise badges:
   - Visual badges for each level
   - Category-specific badges
   - Progress bars for next level

3. Integrate with `ExpertiseService`:
   - Call `getUserExpertise()` to get user's expertise
   - Display expertise data
   - Handle loading states
   - Handle empty states

**Deliverables:**
- ✅ `lib/presentation/widgets/expertise/expertise_display_widget.dart`
- ✅ Expertise badges
- ✅ Integration with `ExpertiseService`

**Acceptance Criteria:**
- Expertise displays correctly
- Badges are visually clear
- UI uses `AppColors`/`AppTheme` (NO direct `Colors.*`)
- Integration works correctly

---

### **Task 3.3: Expertise Dashboard Page (Days 4-5)**

**Objective:** Create page showing user's complete expertise profile.

**Steps:**
1. Create expertise dashboard: `lib/presentation/pages/expertise/expertise_dashboard_page.dart`
   - Display all user expertise
   - Group by category
   - Show progress to next level
   - **CRITICAL:** Use `AppColors`/`AppTheme` (100% adherence required)

2. Add expertise breakdown:
   - List of categories with expertise
   - Current level for each category
   - Progress to next level
   - Requirements for next level

3. Add expertise history (if available):
   - Show expertise progression over time
   - Show milestones reached

4. Integrate with `ExpertiseService`:
   - Get all user expertise
   - Display expertise data
   - Handle loading and empty states

**Deliverables:**
- ✅ `lib/presentation/pages/expertise/expertise_dashboard_page.dart`
- ✅ Expertise breakdown
- ✅ Integration with `ExpertiseService`

**Acceptance Criteria:**
- Dashboard displays correctly
- All expertise categories shown
- UI uses `AppColors`/`AppTheme` (NO direct `Colors.*`)
- Integration works correctly

---

## **WEEK 2: Event Hosting Unlock Indicator**

### **Task 3.4: Event Hosting Unlock Widget (Days 1-2)**

**Objective:** Create widget showing when user unlocks event hosting.

**Steps:**
1. Create unlock indicator widget: `lib/presentation/widgets/expertise/event_hosting_unlock_widget.dart`
   - Show current expertise level
   - Show requirement (City level+)
   - Show progress to unlock
   - Show "Unlocked" state when City level reached
   - **CRITICAL:** Use `AppColors`/`AppTheme` (100% adherence required)

2. Add unlock notification:
   - Show notification when user reaches City level
   - Celebrate unlock achievement
   - Link to event creation

3. Integrate with `ExpertiseService`:
   - Check if user has City level+ expertise
   - Calculate progress to City level
   - Display unlock status

**Deliverables:**
- ✅ `lib/presentation/widgets/expertise/event_hosting_unlock_widget.dart`
- ✅ Unlock notification
- ✅ Integration with `ExpertiseService`

**Acceptance Criteria:**
- Unlock indicator works correctly
- Notification displays properly
- UI uses `AppColors`/`AppTheme` (NO direct `Colors.*`)
- Integration works correctly

---

### **Task 3.5: Integration with Event Creation (Days 3-4)**

**Objective:** Integrate unlock indicator with event creation flow.

**Steps:**
1. Add unlock check to event creation:
   - Show unlock indicator on event creation page
   - Disable event creation if not unlocked
   - Show requirements if not unlocked

2. Add unlock prompt:
   - If user tries to create event without unlock, show requirements
   - Link to expertise dashboard
   - Encourage user to reach City level

3. Test integration:
   - Test with unlocked user
   - Test with locked user
   - Verify unlock indicator displays correctly

**Deliverables:**
- ✅ Unlock indicator integrated with event creation
- ✅ Unlock prompt added
- ✅ Integration tested

**Acceptance Criteria:**
- Integration works correctly
- Unlock check works
- User experience is clear

---

### **Task 3.6: Expertise UI Polish (Day 5)**

**Objective:** Polish all expertise UI components.

**Steps:**
1. Review all expertise UI:
   - Display widget
   - Dashboard page
   - Unlock indicator

2. Fix any UI issues:
   - Layout issues
   - Spacing issues
   - Color issues (verify `AppColors`/`AppTheme` usage)

3. Add animations:
   - Unlock animations
   - Progress animations

**Deliverables:**
- ✅ Expertise UI polished
- ✅ Animations added

**Acceptance Criteria:**
- UI is polished
- All components use `AppColors`/`AppTheme` (NO direct `Colors.*`)

---

## **WEEK 3: Test Planning & Preparation**

### **Task 3.7: Integration Test Plan (Days 1-2)**

**Objective:** Create comprehensive integration test plan.

**Steps:**
1. Review all features to test:
   - Payment processing (Agent 1)
   - Event discovery (Agent 2)
   - Event hosting (Agent 2)
   - Expertise UI (Agent 3)

2. Create test scenarios:
   - Complete user journey (discover → register → host)
   - Payment flow (purchase ticket → success)
   - Event creation flow (create → publish)
   - Expertise progression (view expertise → unlock hosting)

3. Document test plan: `docs/INTEGRATION_TEST_PLAN.md`
   - List all test scenarios
   - Define success criteria
   - Document test data requirements

**Deliverables:**
- ✅ Integration test plan complete
- ✅ Test scenarios defined
- ✅ Test plan documented

**Acceptance Criteria:**
- Test plan covers all MVP features
- Test scenarios are clear
- Success criteria are defined

---

### **Task 3.8: Test Infrastructure Setup (Days 3-4)**

**Objective:** Set up test infrastructure for integration testing.

**Steps:**
1. Review existing test setup:
   - Check test directory structure
   - Review existing test helpers
   - Review test utilities

2. Create test helpers:
   - Event creation helpers
   - Payment test helpers
   - User creation helpers
   - Mock services (if needed)

3. Prepare test data:
   - Test events
   - Test users
   - Test payment scenarios

4. Set up test environment:
   - Configure test Stripe keys (if needed)
   - Configure test database
   - Set up test fixtures

**Deliverables:**
- ✅ Test infrastructure ready
- ✅ Test helpers created
- ✅ Test data prepared

**Acceptance Criteria:**
- Test infrastructure is ready
- Test helpers work correctly
- Test data is prepared

---

### **Task 3.9: Unit Test Review (Day 5)**

**Objective:** Review and ensure unit tests exist for critical components.

**Steps:**
1. Review unit tests for:
   - Payment service (Agent 1)
   - Event service (existing)
   - Expertise service (existing)

2. Add missing unit tests (if needed):
   - Payment service tests
   - Event service tests
   - UI widget tests

3. Ensure test coverage is adequate

**Deliverables:**
- ✅ Unit tests reviewed
- ✅ Missing tests added (if needed)
- ✅ Test coverage verified

**Acceptance Criteria:**
- Critical components have unit tests
- Test coverage is adequate

---

## **WEEK 4: Integration Testing & Bug Fixes**

### **Task 3.10: Payment Flow Integration Tests (Days 1-2)**

**Objective:** Test complete payment flow end-to-end.

**Steps:**
1. Test payment purchase:
   - Create test event
   - Navigate to event details
   - Click "Purchase Ticket"
   - Complete payment
   - Verify payment success
   - Verify event registration
   - Verify revenue split

2. Test payment failures:
   - Network failure
   - Invalid card
   - Insufficient funds
   - Event capacity exceeded

3. Document test results:
   - Record test outcomes
   - Document bugs found
   - Create bug reports

**Deliverables:**
- ✅ Payment flow tests complete
- ✅ Test results documented
- ✅ Bug reports created

**Acceptance Criteria:**
- All payment flows tested
- Bugs documented
- Test results recorded

---

### **Task 3.11: Event Discovery Integration Tests (Days 2-3)**

**Objective:** Test event discovery flow end-to-end.

**Steps:**
1. Test event browsing:
   - Navigate to events browse page
   - Verify events display
   - Test search functionality
   - Test filters
   - Test pagination

2. Test event details:
   - Click on event
   - Verify event details display
   - Test registration (free event)
   - Test payment (paid event)

3. Test "My Events":
   - Verify hosted events display
   - Verify attending events display
   - Verify past events display

4. Document test results

**Deliverables:**
- ✅ Event discovery tests complete
- ✅ Test results documented
- ✅ Bug reports created

**Acceptance Criteria:**
- All discovery flows tested
- Bugs documented
- Test results recorded

---

### **Task 3.12: Event Hosting Integration Tests (Days 3-4)**

**Objective:** Test event hosting flow end-to-end.

**Steps:**
1. Test event creation:
   - Navigate to create event page
   - Fill out form
   - Verify validation
   - Submit form
   - Verify event created

2. Test template selection:
   - Select template
   - Verify form pre-filled
   - Edit template data
   - Create event

3. Test event publishing:
   - Review event
   - Publish event
   - Verify success
   - Verify event appears in browse page

4. Document test results

**Deliverables:**
- ✅ Event hosting tests complete
- ✅ Test results documented
- ✅ Bug reports created

**Acceptance Criteria:**
- All hosting flows tested
- Bugs documented
- Test results recorded

---

### **Task 3.13: End-to-End Integration Tests (Day 4)**

**Objective:** Test complete user journey end-to-end.

**Steps:**
1. Test complete journey:
   - User discovers event
   - User registers for event (with payment if paid)
   - User views "My Events"
   - User creates own event
   - User views expertise
   - User unlocks event hosting

2. Test edge cases:
   - Multiple events
   - Event capacity limits
   - Payment failures
   - Network failures

3. Document test results

**Deliverables:**
- ✅ End-to-end tests complete
- ✅ Test results documented
- ✅ Bug reports created

**Acceptance Criteria:**
- Complete journey works
- Edge cases handled
- Bugs documented

---

### **Task 3.14: Bug Fixes & Final Testing (Day 5)**

**Objective:** Fix bugs found during testing and verify fixes.

**Steps:**
1. Coordinate with Agents 1 and 2 on bug fixes:
   - Share bug reports
   - Verify bug fixes
   - Re-test fixed bugs

2. Final integration test:
   - Re-run all integration tests
   - Verify all bugs fixed
   - Verify MVP is complete

3. Create test report:
   - Document all tests run
   - Document bugs found and fixed
   - Document MVP completion

4. Update Master Plan:
   - Mark Week 4 complete
   - Update progress

**Deliverables:**
- ✅ All bugs fixed
- ✅ Final tests passed
- ✅ Test report created
- ✅ Master Plan updated

**Acceptance Criteria:**
- All critical bugs fixed
- MVP is functional
- Test report is complete

---

## 📋 **Coordination Checklist**

### **Before Starting Work:**
- [ ] All agents have read Master Plan
- [ ] All agents have read MVP Critical Analysis
- [ ] All agents understand design token requirements (100% `AppColors`/`AppTheme`)
- [ ] All agents understand architecture (ai2ai only, offline-first)
- [ ] Communication channel established (daily sync)

### **During Work:**
- [ ] Daily sync on model definitions (Agent 1 → Agent 2)
- [ ] Daily sync on integration points
- [ ] Daily sync on progress
- [ ] Verify design token compliance (all agents)
- [ ] Update Master Plan progress daily

### **Week 1 Coordination (Parallel Start):**
- [ ] **All agents start simultaneously:**
  - Agent 1: Payment backend (Days 1-5)
  - Agent 2: Event Discovery UI (Week 2 tasks, Days 1-5) - No dependencies
  - Agent 3: Expertise UI (Days 1-5) - Completely independent
- [ ] Agent 1 shares payment models with Agent 2 (Day 2)
- [ ] Agent 2 can start payment UI after models ready (Day 2+) OR continue Event Discovery UI
- [ ] All agents update progress daily

### **Week 2 Coordination:**
- [ ] Agent 2 shares event discovery UI with Agent 1
- [ ] Agent 1 verifies integration points
- [ ] Agent 3 continues expertise UI

### **Week 3 Coordination:**
- [ ] Agent 2 shares event hosting UI with Agent 1
- [ ] Agent 1 verifies integration
- [ ] Agent 3 prepares test plan

### **Week 4 Coordination:**
- [ ] Agent 3 coordinates integration tests with Agents 1 & 2
- [ ] All agents fix bugs found during testing
- [ ] All agents verify MVP completion

---

## ✅ **Success Criteria**

### **Week 1 Success:**
- ✅ Payment backend complete (Agent 1)
- ✅ Payment models shared (Agent 1 → Agent 2)
- ✅ Payment UI started (Agent 2)
- ✅ Expertise UI started (Agent 3)

### **Week 2 Success:**
- ✅ Event Discovery UI complete (Agent 2)
- ✅ Backend integration ready (Agent 1)
- ✅ Expertise UI complete (Agent 3)

### **Week 3 Success:**
- ✅ Event Hosting UI complete (Agent 2)
- ✅ Integration prep complete (Agent 1)
- ✅ Test plan complete (Agent 3)

### **Week 4 Success:**
- ✅ Integration tests complete (Agent 3)
- ✅ All bugs fixed (all agents)
- ✅ MVP fully functional (all agents)

---

## 🚨 **Critical Rules (All Agents)**

1. **Design Tokens (100% Adherence):**
   - ✅ ALWAYS use `AppColors` or `AppTheme`
   - ❌ NEVER use direct `Colors.*`
   - This is non-negotiable

2. **Architecture:**
   - ai2ai only (never p2p)
   - Offline-first (handle offline gracefully)
   - Self-improving (where applicable)

3. **Quality Standards:**
   - Zero linter errors
   - Full integration (users can access features)
   - Tests written (where applicable)
   - Documentation complete

4. **Coordination:**
   - Share models/services immediately
   - Update progress daily
   - Communicate blockers immediately

---

## 📝 **Usage Instructions**

### **To Use This Document:**

1. **For Agent 1:**
   - Read `docs/agents/reference/quick_reference.md` first (code examples and patterns)
   - Copy the "AGENT 1" section from this document
   - Use prompt: "[AGENT_1_SECTION] you are agent 1, follow the task exactly as written. Reference docs/agents/reference/quick_reference.md for code patterns."

2. **For Agent 2:**
   - Read `docs/agents/reference/quick_reference.md` first (code examples and patterns)
   - Copy the "AGENT 2" section from this document
   - Use prompt: "[AGENT_2_SECTION] you are agent 2, follow the task exactly as written. Reference docs/agents/reference/quick_reference.md for code patterns."

3. **For Agent 3:**
   - Read `docs/agents/reference/quick_reference.md` first (code examples and patterns)
   - Copy the "AGENT 3" section from this document
   - Use prompt: "[AGENT_3_SECTION] you are agent 3, follow the task exactly as written. Reference docs/agents/reference/quick_reference.md for code patterns."

### **Daily Workflow:**
1. Agent reads `docs/agents/reference/quick_reference.md` (if first time)
2. Agent reads their task for the day
3. Agent references quick guide for code patterns
4. Agent completes task
5. Agent updates progress
6. Agent coordinates with other agents (if needed)
7. Agent moves to next task

### **If Unclear:**
- Check `docs/agents/reference/quick_reference.md` for code examples
- Check existing code files for patterns
- Ask for clarification rather than guessing

---

**Last Updated:** November 22, 2025  
**Status:** Ready for Use

