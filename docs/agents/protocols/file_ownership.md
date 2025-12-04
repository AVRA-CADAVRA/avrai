# File Ownership Matrix - Parallel Agent Work

**Date:** November 22, 2025, 8:40 PM CST  
**Purpose:** Prevent file conflicts by defining clear ownership  
**Status:** 🟢 Active

---

## 🎯 **Ownership Rules**

### **Rule 1: Primary Owner**
Each file has ONE primary owner. Only that agent should create/modify it.

### **Rule 2: Shared Files**
Some files are shared. Agents must coordinate before modifying.

### **Rule 3: Read-Only for Others**
Agents can READ files owned by others, but should NOT modify them.

---

## 📁 **File Ownership by Agent**

### **Agent 1: Payment Processing & Revenue**

**Owns (Can Create/Modify):**
- `lib/core/services/payment_service.dart` ✅
- `lib/core/services/stripe_service.dart` ✅
- `lib/core/services/payout_service.dart` ✅
- `lib/core/models/payment.dart` ✅
- `lib/core/models/payment_intent.dart` ✅
- `lib/core/models/revenue_split.dart` ✅
- `lib/core/models/payment_status.dart` ✅
- `lib/core/config/stripe_config.dart` ✅
- `test/unit/services/payment_service_test.dart` ✅
- `test/unit/services/stripe_service_test.dart` ✅

**Can Read (But NOT Modify):**
- `lib/core/services/expertise_event_service.dart` (Agent 2 might modify)
- `lib/core/models/expertise_event.dart` (Agent 2 might modify)
- `lib/core/services/expertise_service.dart` (Agent 3 might modify)

---

### **Agent 2: Event Discovery & Hosting UI**

**Owns (Can Create/Modify):**
- `lib/presentation/pages/events/events_browse_page.dart` ✅
- `lib/presentation/pages/events/event_details_page.dart` ✅
- `lib/presentation/pages/events/my_events_page.dart` ✅
- `lib/presentation/pages/events/create_event_page.dart` ✅
- `lib/presentation/pages/events/event_review_page.dart` ✅
- `lib/presentation/pages/events/event_published_page.dart` ✅
- `lib/presentation/pages/payment/checkout_page.dart` ✅
- `lib/presentation/pages/payment/payment_success_page.dart` ✅
- `lib/presentation/pages/payment/payment_failure_page.dart` ✅
- `lib/presentation/widgets/events/event_card_widget.dart` ✅
- `lib/presentation/widgets/events/template_selection_widget.dart` ✅
- `lib/presentation/widgets/payment/payment_form_widget.dart` ✅
- `lib/presentation/pages/events/quick_event_builder_page.dart` ✅ (polish existing)
- `test/widget/pages/events/*_test.dart` ✅
- `test/widget/pages/payment/*_test.dart` ✅

**Can Read (But NOT Modify):**
- `lib/core/services/payment_service.dart` (Agent 1 owns)
- `lib/core/models/payment.dart` (Agent 1 owns)
- `lib/core/services/expertise_event_service.dart` (can use, but coordinate changes)

**Might Modify (Coordinate First):**
- `lib/presentation/pages/home/home_page.dart` (replace "Coming Soon" placeholder)
  - **Rule:** Check with other agents first, or use separate branch

---

### **Agent 3: Expertise UI & Testing**

**Owns (Can Create/Modify):**
- `lib/presentation/widgets/expertise/expertise_display_widget.dart` ✅
- `lib/presentation/pages/expertise/expertise_dashboard_page.dart` ✅
- `lib/presentation/widgets/expertise/event_hosting_unlock_widget.dart` ✅
- `test/widget/widgets/expertise/*_test.dart` ✅
- `test/integration/*_test.dart` ✅ (integration tests)
- `docs/INTEGRATION_TEST_PLAN.md` ✅

**Can Read (But NOT Modify):**
- `lib/core/services/payment_service.dart` (Agent 1 owns)
- `lib/core/services/expertise_event_service.dart` (Agent 2 might modify)
- `lib/presentation/pages/events/*.dart` (Agent 2 owns)

---

## ⚠️ **Shared Files (Require Coordination)**

### **`pubspec.yaml`**
**Ownership:** First agent to add a package owns that line
**Rule:** 
- Agent 1 adds Stripe first → owns Stripe dependency
- Agent 2/3 check before adding packages
- If conflict, coordinate

**Process:**
1. Check if package already in `pubspec.yaml`
2. If not, add your package
3. If conflict during merge, coordinate resolution

---

### **`lib/core/services/expertise_event_service.dart`**
**Ownership:** Existing service, all agents can use
**Rule:**
- All agents can READ and USE
- Agent 1 might extend for payment integration
- Agent 2 might extend for UI integration
- **Coordinate before modifying**

**Process:**
1. Check current implementation
2. If extending, coordinate with other agents
3. Use feature flags or separate methods if needed

---

### **`lib/presentation/pages/home/home_page.dart`**
**Ownership:** Shared - Agent 2 needs to modify
**Rule:**
- Agent 2 needs to replace "Coming Soon" placeholder
- Check if other agents are modifying
- Coordinate if needed

**Process:**
1. Check status tracker - is anyone else modifying?
2. If clear, proceed with modification
3. If conflict, coordinate

---

### **`docs/agents/status/status_tracker.md`**
**Ownership:** ALL AGENTS (but coordinate updates)
**Rule:**
- All agents can update
- Update one section at a time
- Don't overwrite others' updates

**Process:**
1. Read current status
2. Update only YOUR section
3. Don't modify other agents' sections
4. If conflict, read latest and update again

---

## 🚨 **Conflict Prevention Rules**

### **Rule 1: Check Before Creating**
Before creating a new file:
1. Search for similar files
2. Check if another agent already created it
3. If exists, use it; don't recreate

### **Rule 2: Coordinate Shared Files**
Before modifying shared files:
1. Check status tracker
2. See if other agents are modifying
3. Coordinate if needed

### **Rule 3: Read-Only for Others' Files**
For files owned by others:
1. You can READ and USE
2. You CANNOT modify
3. If you need changes, ask owner or coordinate

### **Rule 4: Status Tracker Updates**
When updating status tracker:
1. Read latest version first
2. Update only YOUR section
3. Don't overwrite others' updates
4. If conflict, read and update again

---

## 📋 **File Creation Checklist**

Before creating a new file:
- [ ] Searched for similar files
- [ ] Checked if another agent owns it
- [ ] Verified it's in the correct location
- [ ] Follows naming conventions
- [ ] Uses design tokens (if UI file)

---

## 🔄 **Coordination Protocol**

### **If You Need to Modify a Shared File:**

1. **Check status tracker** - Is anyone else modifying?
2. **If clear:**
   - Proceed with modification
   - Update status tracker
   - Commit and push

3. **If someone else is modifying:**
   - Wait for them to complete
   - Pull latest changes
   - Then proceed

4. **If urgent:**
   - Coordinate via status tracker
   - Or create separate file/approach

---

**Last Updated:** November 22, 2025, 8:40 PM CST  
**Status:** Ready for Use

