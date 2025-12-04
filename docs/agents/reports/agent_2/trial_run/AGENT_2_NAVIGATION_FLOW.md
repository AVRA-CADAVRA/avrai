# Agent 2: Navigation Flow Documentation

**Date:** November 22, 2025, 09:27 PM CST  
**Agent:** Agent 2 - Event Discovery & Hosting UI  
**Purpose:** Document navigation flow between all UI pages

---

## 🗺️ **Navigation Flow Map**

### **Event Discovery Flow**

```
Home Page (Events Tab)
  └─> Events Browse Page
        ├─> [Search/Filter Events]
        └─> Event Details Page
              ├─> [Register for Event] → Success → My Events Page
              ├─> [Purchase Ticket] → Checkout Page
              ├─> [Share Event] → Share Dialog
              └─> [Add to Calendar] → Calendar App
```

### **Payment Flow**

```
Event Details Page
  └─> [Purchase Ticket] → Checkout Page
        ├─> [Select Quantity]
        ├─> [Enter Payment Info]
        └─> [Pay] → Payment Processing
              ├─> Success → Payment Success Page
              │     └─> [View Event] → Event Details Page
              │     └─> [Back to Home] → Home Page
              └─> Failure → Payment Failure Page
                    ├─> [Try Again] → Checkout Page
                    ├─> [Back to Event] → Event Details Page
                    └─> [Back to Home] → Home Page
```

### **Event Hosting Flow**

```
Home Page
  └─> [Create Event] → Create Event Page
        ├─> [Fill Form]
        ├─> [Verify Expertise]
        └─> [Review & Publish] → Event Review Page
              └─> [Publish] → Event Published Page
                    ├─> [View Event] → Event Details Page
                    ├─> [Share Event] → Share Dialog
                    └─> [Back to Home] → Home Page

OR

Home Page
  └─> [Quick Builder] → Quick Event Builder Page
        ├─> [Select Template]
        ├─> [Select Date/Time]
        ├─> [Select Spots]
        └─> [Review & Publish] → Event Published Page
```

### **Template Selection Flow**

```
Create Event Page
  └─> [Use Template] → Template Selection Widget
        └─> [Select Template] → Pre-fills Create Event Page

Quick Event Builder Page
  └─> [Step 1: Template Selection] → Shows Templates
        └─> [Select Template] → Next Step
```

### **My Events Flow**

```
Home Page
  └─> [My Events] → My Events Page
        ├─> [Hosting Tab] → Shows Hosted Events
        │     └─> [Event Card] → Event Details Page
        ├─> [Attending Tab] → Shows Registered Events
        │     └─> [Event Card] → Event Details Page
        └─> [Past Tab] → Shows Past Events
              └─> [Event Card] → Event Details Page
```

---

## 🔄 **Page Entry Points**

### **Direct Navigation:**
- **Events Browse Page:** Home Page (Events Tab)
- **Event Details Page:** From Events Browse Page, My Events Page, or Deep Links
- **My Events Page:** Home Page → My Events
- **Create Event Page:** Home Page → Create Event
- **Quick Event Builder:** Home Page → Quick Builder
- **Checkout Page:** Event Details Page → Purchase Ticket

### **Deep Links:**
- **Event Details Page:** `/events/{eventId}`
- **Events Browse Page:** `/events`

---

## 📋 **Route Parameters**

### **Event Details Page:**
- **Route:** `/events/{eventId}`
- **Parameter:** `eventId` (String)
- **Usage:** `getEventById(eventId)` to fetch event

### **Checkout Page:**
- **Route:** Direct navigation (no route)
- **Parameter:** `event` (ExpertiseEvent) - passed as constructor parameter

---

## 🔗 **Integration Points**

### **With ExpertiseEventService:**
- `searchEvents()` - Events Browse Page
- `getEventById()` - Event Details Page
- `registerForEvent()` - Event Details Page, Payment Success Page
- `createEvent()` - Create Event Page, Quick Builder, Review Page
- `getEventsByHost()` - My Events Page (Hosting tab)
- `getEventsByAttendee()` - My Events Page (Attending tab)

### **With PaymentService:**
- `purchaseEventTicket()` - Payment Form Widget
- `confirmPayment()` - Payment Form Widget
- `handlePaymentFailure()` - Payment Form Widget

### **With AuthBloc:**
- `Authenticated` state - All pages (to get current user)
- User ID - Event registration, event creation, payment

---

## 🎯 **Key User Flows**

### **Flow 1: Discover and Register for Free Event**
1. User opens app → Home Page
2. User taps "Events" tab → Events Browse Page
3. User searches/filters events
4. User taps event card → Event Details Page
5. User taps "Register for Event" → Registration success
6. User navigates to "My Events" → Sees event in "Attending" tab

### **Flow 2: Purchase Ticket for Paid Event**
1. User opens app → Home Page
2. User taps "Events" tab → Events Browse Page
3. User taps paid event → Event Details Page
4. User taps "Purchase Ticket" → Checkout Page
5. User selects quantity → Enters payment info
6. User taps "Pay" → Payment processing
7. Payment success → Payment Success Page
8. Automatic registration → User registered for event
9. User taps "View Event" → Event Details Page

### **Flow 3: Host an Event**
1. User opens app → Home Page
2. User taps "Create Event" → Create Event Page
3. User fills form (title, description, date, etc.)
4. User taps "Review & Publish" → Event Review Page
5. User reviews details → Taps "Publish Event"
6. Event created → Event Published Page
7. User taps "View Event" → Event Details Page

### **Flow 4: Quick Event Builder**
1. User opens app → Home Page
2. User taps "Quick Builder" → Quick Event Builder Page
3. User selects template → Next step
4. User selects date/time → Next step
5. User selects spots → Next step
6. User reviews → Taps "Publish Event"
7. Event created → Event Published Page

---

## 📱 **Page States**

### **Loading States:**
- Events Browse Page: Loading events
- Event Details Page: Loading event details
- My Events Page: Loading events by tab
- Create Event Page: Creating event
- Payment Form Widget: Processing payment
- Payment Success Page: Registering for event

### **Error States:**
- Events Browse Page: Error loading events
- Event Details Page: Event not found
- Payment Form Widget: Payment failed
- Payment Failure Page: Payment error details

### **Empty States:**
- Events Browse Page: No events found
- My Events Page: No events in tab (Hosting/Attending/Past)
- Template Selection Widget: No templates found

---

## 🎨 **UI Transitions**

### **Page Transitions Used:**
- **Slide from Right:** Event Details → Checkout
- **Scale and Fade:** Checkout → Payment Success/Failure
- **Fade:** Standard navigation

### **Animation Utilities:**
- `PageTransitions.slideFromRight()` - Forward navigation
- `PageTransitions.scaleAndFade()` - Success/result pages
- `PageTransitions.fade()` - Standard transitions

---

## ✅ **Navigation Completeness**

All navigation flows are:
- ✅ Functional and tested
- ✅ Smooth transitions applied
- ✅ Error handling in place
- ✅ Loading states implemented
- ✅ Deep link ready (event details)
- ✅ Back navigation working
- ✅ Proper parameter passing

---

**Last Updated:** November 22, 2025, 09:27 PM CST  
**Status:** ✅ Complete - All navigation flows documented

