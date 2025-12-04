# Agent 2 - Week 26: EventsBrowsePage Review & Tab Structure Design

**Date:** November 24, 2025  
**Agent:** Agent 2 (Frontend & UX Specialist)  
**Phase:** Phase 6, Week 26  
**Status:** ✅ Review Complete, Design Ready

---

## 📋 **EventsBrowsePage Review**

### **Current Structure**

**File:** `lib/presentation/pages/events/events_browse_page.dart`

**Key Components:**
1. **Search Bar** (`_buildSearchBar()`)
   - TextField with search icon
   - Searches by title, category, location
   - Uses AppColors/AppTheme ✅

2. **Filters** (`_buildFilters()`)
   - Category filter (dropdown)
   - Location filter (text input)
   - Date filter (upcoming, this week, this month)
   - Price filter (free, paid)
   - Clear filters button
   - Uses AppColors/AppTheme ✅

3. **Event List** (`_buildEventList()`)
   - ListView.builder with ExpertiseEventWidget
   - Loading state (CircularProgressIndicator)
   - Error state (error message + retry button)
   - Empty state (no events message)
   - Pull-to-refresh support

**State Management:**
- Uses StatefulWidget with local state
- `_events`: All loaded events
- `_filteredEvents`: Events after search/filtering
- `_isLoading`: Loading state
- `_error`: Error message

**Service Integration:**
- Uses `ExpertiseEventService.searchEvents()`
- Filters: category, location, eventType, startDate, maxResults

**Design System Compliance:**
- ✅ 100% AppColors/AppTheme adherence
- ✅ No direct Colors.* usage
- ✅ Consistent with existing UI patterns

---

## 🎨 **Tab Structure Design**

### **Tab Hierarchy**

Based on geographic scope and event types:

1. **Community** - Non-expert events (community-organized)
2. **Locality** - Events in user's locality (neighborhood-level)
3. **City** - Events in user's city
4. **State** - Events in user's state/region
5. **Nation** - Events in user's nation/country
6. **Globe** - Global events (worldwide)
7. **Universe** - All events (no geographic restriction)
8. **Clubs/Communities** - Events from clubs/communities user is part of

### **Tab UI Design**

**Pattern:** Follow existing tab implementations (e.g., `my_events_page.dart`, `ai2ai_connections_page.dart`)

**Implementation:**
- Use `TabBar` with `TabBarView`
- Use `TabController` for programmatic control
- Place tabs below AppBar (using `bottom` property)
- Horizontal scrollable tabs (if needed for smaller screens)

**Styling (AppColors/AppTheme):**
- **Tab Bar Background:** `AppColors.surface` or `AppColors.grey100`
- **Selected Tab:** `AppTheme.primaryColor` (electricGreen)
- **Unselected Tab:** `AppColors.textSecondary`
- **Indicator Color:** `AppTheme.primaryColor`
- **Tab Text:** `AppColors.textPrimary`

**Tab Icons (Optional):**
- Community: `Icons.people`
- Locality: `Icons.location_on`
- City: `Icons.location_city`
- State: `Icons.map`
- Nation: `Icons.public`
- Globe: `Icons.language`
- Universe: `Icons.explore`
- Clubs/Communities: `Icons.group`

---

## 🔄 **Filtering Logic Per Tab**

### **Community Tab**
- Filter: Events where host is NOT an expert (or community flag)
- Display: All community events

### **Locality Tab**
- Filter: Events in user's locality
- Extract locality from user location
- Match events by locality (from event.location)
- Display: Events in user's neighborhood/locality

### **City Tab**
- Filter: Events in user's city
- Extract city from user location
- Match events by city (from event.location)
- Display: Events in user's city

### **State Tab**
- Filter: Events in user's state/region
- Extract state from user location
- Match events by state (from event.location)
- Display: Events in user's state

### **Nation Tab**
- Filter: Events in user's nation/country
- Extract nation from user location
- Match events by nation (from event.location)
- Display: Events in user's country

### **Globe Tab**
- Filter: Events worldwide (all nations)
- Display: All global events

### **Universe Tab**
- Filter: No geographic filter
- Display: All events (no restrictions)

### **Clubs/Communities Tab**
- Filter: Events from clubs/communities user is member of
- Display: Community/club events

---

## 📍 **Location Parsing**

**Event Location Format:**
- Format: `"Locality, City, State, Country"`
- Example: `"Greenpoint, Brooklyn, New York, USA"`

**Parsing Logic:**
- Split by comma
- Extract components:
  - Locality: `parts[0]`
  - City: `parts[1]`
  - State: `parts[2]` (if exists)
  - Nation: `parts[3]` (if exists)

**User Location:**
- Get from `AuthBloc` → `Authenticated.user.location`
- Parse same way as event location

---

## 🔧 **Implementation Plan**

### **Phase 1: Tab Widget (Week 26, Day 3-5)**
1. Create `lib/presentation/widgets/events/event_scope_tab_widget.dart`
2. Implement tab switching logic
3. Use AppColors/AppTheme (100% adherence)
4. Follow existing UI patterns

### **Phase 2: Integration (Week 27)**
1. Integrate tabs into EventsBrowsePage
2. Implement scope-based filtering
3. Update event search to filter by scope
4. Integrate with EventRecommendationService (Week 27)

---

## 📝 **Notes**

- **Location Parsing:** Need to handle edge cases (missing components, different formats)
- **User Location:** May be null - handle gracefully
- **Tab State:** Persist selected tab (optional enhancement)
- **Performance:** Consider lazy loading per tab
- **Accessibility:** Ensure tabs are accessible (screen readers, keyboard navigation)

---

## ✅ **Deliverables Status**

- [x] EventsBrowsePage reviewed and understood
- [x] Tab structure designed
- [x] Filtering logic planned
- [x] UI design specified (AppColors/AppTheme)
- [x] Tab widget created (Week 26, Day 3-5) ✅
- [x] Ready for Week 27 implementation ✅

---

## ✅ **Week 26-27 Status: COMPLETE**

**Week 26:** ✅ Tab widget created, design complete  
**Week 27:** ✅ Tabs integrated, service integrations complete  
**See:** `week_27_completion.md` for full Week 27 completion details

