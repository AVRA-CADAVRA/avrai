# Mock Data Replacement Protocol

**Status:** 🎯 MANDATORY - Follow during Integration Phase  
**When to Use:** When backend service becomes available  
**Reference:** `DEVELOPMENT_METHODOLOGY.md` → Phase 2: Integration  
**Last Updated:** December 2024

---

## 🎯 Purpose

This protocol provides a systematic approach for replacing mock data with real data when backend services become available. It ensures consistent, reliable integration while maintaining code quality and user experience.

**Key Principles:**
- ✅ Replace incrementally (not all at once)
- ✅ Test with real data before removing mocks
- ✅ Handle loading and error states properly
- ✅ Clean up mock code completely
- ✅ Follow SPOTS offline-first patterns

---

## ⚡ Quick Reference (2 min)

### 5-Step Checklist

```
☑️ Step 1: Identify Mock Data
   - Search for "// Mock data" or "// TODO: Load"
   - Check for hardcoded fake data
   - Verify service availability

☑️ Step 2: Verify Service Exists
   - Check service in lib/core/services/
   - Verify registration in injection_container.dart
   - Ensure methods match requirements

☑️ Step 3: Replace Incrementally
   - Add service dependency via DI
   - Replace mock with service call
   - Handle loading/error states
   - Update UI with real data

☑️ Step 4: Test with Real Data
   - Test with actual backend
   - Validate data mapping
   - Handle edge cases

☑️ Step 5: Clean Up
   - Remove hardcoded mock data
   - Remove "// Mock data" comments
   - Remove unused variables
```

**When to Use:**
- Backend service is ready and tested
- Service is registered in dependency injection
- Service methods match UI requirements
- During Integration Phase (Phase 2)

---

## 📋 Full Protocol (10 min)

### Step 1: Identify Mock Data

**How to Find Mock Data:**

```bash
# Search for mock data comments
grep -r "// Mock data" lib/presentation/
grep -r "// TODO: Load" lib/presentation/
grep -r "Mock.*data" lib/presentation/ -i

# Search for hardcoded fake data
grep -r "mock-.*-1" lib/presentation/
grep -r "fake.*data" lib/presentation/ -i
```

**Types of Mock Data:**
1. **UI Mock Data** - Hardcoded in widget state
   - Example: `_brandAccount = BrandAccount(id: 'brand-mock-1', ...)`
   - Location: `lib/presentation/pages/`

2. **Service Mock Data** - Returned by mock services
   - Example: Service returns empty list or null
   - Location: `lib/core/services/`

3. **Repository Mock Data** - Mock data sources
   - Example: Remote data source returns fake data
   - Location: `lib/data/datasources/`

**Current SPOTS Examples:**
- `lib/presentation/pages/brand/brand_dashboard_page.dart` (line 40-121)
- `lib/presentation/pages/brand/brand_analytics_page.dart` (line 66)
- `lib/presentation/pages/brand/sponsorship_management_page.dart` (line 105)

---

### Step 2: Verify Service Availability

**Check Service Exists:**

```bash
# Search for service
glob_file_search('**/*service_name*.dart')
grep('class.*ServiceName', path: 'lib/core/services/')

# Check if registered
grep('ServiceName', path: 'lib/injection_container.dart')
```

**Verification Checklist:**
- [ ] Service class exists in `lib/core/services/`
- [ ] Service is registered in `injection_container.dart`
- [ ] Service methods match what UI needs
- [ ] Service has proper error handling
- [ ] Service follows SPOTS patterns (offline-first, etc.)

**Example Service Check:**

```dart
// ✅ Good: Service exists and registered
// lib/core/services/brand_account_service.dart
class BrandAccountService {
  Future<BrandAccount?> getBrandAccountByUserId(String userId) async {
    // Real implementation
  }
}

// lib/injection_container.dart
sl.registerLazySingleton<BrandAccountService>(() => BrandAccountService());
```

---

### Step 3: Replace Incrementally

**3.1 Add Service Dependency**

```dart
// Before (mock data):
class BrandDashboardPage extends StatefulWidget {
  // No service dependency
}

// After (real service):
class BrandDashboardPage extends StatefulWidget {
  // Get service via dependency injection
  final BrandAccountService? brandAccountService;
  final BrandAnalyticsService? brandAnalyticsService;
  
  const BrandDashboardPage({
    this.brandAccountService,
    this.brandAnalyticsService,
  });
  
  // Or get from context:
  // final service = context.read<BrandAccountService>();
}
```

**3.2 Replace Mock with Service Call**

```dart
// Before (mock data):
Future<void> _loadDashboardData() async {
  // Mock data for now
  await Future.delayed(const Duration(seconds: 1));
  
  setState(() {
    _brandAccount = BrandAccount(
      id: 'brand-mock-1',
      name: 'Premium Olive Oil Co.',
      // ... hardcoded data
    );
  });
}

// After (real service):
Future<void> _loadDashboardData() async {
  final userId = context.read<AuthBloc>().state.user?.id;
  if (userId == null) return;
  
  setState(() => _isLoading = true);
  
  try {
    // Get service from DI
    final brandService = context.read<BrandAccountService>();
    final analyticsService = context.read<BrandAnalyticsService>();
    
    // Load real data
    final brand = await brandService.getBrandAccountByUserId(userId);
    if (brand == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    final analytics = await analyticsService.getBrandAnalytics(brand.id);
    final sponsorships = await sponsorshipService.getSponsorshipsForBrand(brand.id);
    
    setState(() {
      _brandAccount = brand;
      _analytics = analytics;
      _activeSponsorships = sponsorships.where((s) => 
        s.status == SponsorshipStatus.active ||
        s.status == SponsorshipStatus.locked ||
        s.status == SponsorshipStatus.approved
      ).toList();
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading dashboard: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
```

**3.3 Handle Loading/Error States**

```dart
// Always handle these states:
- Loading: Show CircularProgressIndicator
- Error: Show error message to user
- Empty: Show appropriate empty state
- Success: Show data

// Example:
if (_isLoading) {
  return const Center(child: CircularProgressIndicator());
}

if (_error != null) {
  return Center(
    child: Text('Error: $_error', style: TextStyle(color: AppColors.error)),
  );
}

if (_brandAccount == null) {
  return const Center(child: Text('No brand account found'));
}

// Show data
return _buildDashboard();
```

---

### Step 4: Test with Real Data

**4.1 Test with Backend**

```bash
# Run app with real backend
flutter run

# Test the feature
# - Navigate to page
# - Verify data loads
# - Test error cases
# - Test empty states
```

**4.2 Validate Data Mapping**

```dart
// Ensure data models match
// Service returns: BrandAccount (core model)
// UI expects: BrandAccount (presentation model)
// Verify mapping is correct

// Check for:
- Field names match
- Data types match
- Null handling
- Date formatting
```

**4.3 Handle Edge Cases**

```dart
// Test these scenarios:
- Service returns null
- Service throws error
- Network is offline (if applicable)
- Data is empty
- Data is malformed
- User is not authenticated
```

---

### Step 5: Clean Up

**5.1 Remove Mock Code**

```dart
// Remove:
- Hardcoded mock data
- Mock data variables
- Mock data comments
- Unused imports
- Unused methods

// Example cleanup:
// ❌ Remove:
double _totalInvestment = 3200.0; // Mock data
double _totalReturns = 1847.0; // Mock data

// ❌ Remove:
await Future.delayed(const Duration(seconds: 1)); // Mock delay

// ❌ Remove:
// Mock data for now
```

**5.2 Update Comments**

```dart
// ❌ Remove:
// TODO: Load brand account when service available
// Mock data for now

// ✅ Add (if needed):
// Loads brand account data from BrandAccountService
// Handles loading, error, and empty states
```

**5.3 Remove Unused Variables**

```dart
// Remove any variables that were only used for mock data
// Example:
// ❌ Remove if no longer needed:
List<Sponsorship> _mockSponsorships = [];
```

---

## 🔄 Common Scenarios

### Scenario 1: UI Mock Data (Brand Dashboard)

**File:** `lib/presentation/pages/brand/brand_dashboard_page.dart`

**Before:**
```dart
// Mock analytics data
double _totalInvestment = 3200.0;
double _totalReturns = 1847.0;

// TODO: Load brand account when service available
// Mock data for now
await Future.delayed(const Duration(seconds: 1));
_brandAccount = BrandAccount(id: 'brand-mock-1', ...);
```

**After:**
```dart
// Get service from DI
final brandService = context.read<BrandAccountService>();
final analyticsService = context.read<BrandAnalyticsService>();

// Load real data
final brand = await brandService.getBrandAccountByUserId(userId);
final analytics = await analyticsService.getBrandAnalytics(brand.id);

setState(() {
  _brandAccount = brand;
  _analytics = analytics;
});
```

**Steps:**
1. Add service dependencies
2. Replace `Future.delayed` with service call
3. Replace hardcoded `BrandAccount` with service result
4. Remove mock variables
5. Add error handling
6. Test with real backend

---

### Scenario 2: Service Integration (Repository Pattern)

**SPOTS uses offline-first repository pattern:**

```dart
// Repository handles local + remote automatically
final repository = context.read<SpotsRepository>();

// Repository pattern already handles:
// - Local data first (offline)
// - Remote sync when online
// - Error handling
// - Caching

// Just use repository - no mock replacement needed!
final spots = await repository.getSpots();
```

**When to Use:**
- Repository pattern is already implemented
- No mock data in repository layer
- Just wire UI to repository

---

### Scenario 3: Offline-First Pattern

**SPOTS Architecture:**
- Local data sources (Sembast) - always available
- Remote data sources (Supabase) - when online
- Repository pattern - handles both automatically

**Mock Replacement in Offline-First:**
```dart
// ✅ Good: Use repository (handles offline/online)
final repository = context.read<SpotsRepository>();
final spots = await repository.getSpots(); // Works offline + online

// ❌ Bad: Direct service call (breaks offline)
final service = context.read<SpotsService>();
final spots = await service.getSpots(); // Only works online
```

**Key Point:** In SPOTS, mock data replacement often means connecting UI to repository, not directly to service.

---

## 🔗 Integration Points

### When in Workflow

**This protocol is used during:**
- **Phase 2: Integration** (DEVELOPMENT_METHODOLOGY.md)
- **Pattern 4: Backend-First Features** (DEVELOPMENT_METHODOLOGY.md)
- **Step 3: Cross-Reference Plans** (SESSION_START_CHECKLIST.md)

### Dependencies

**Before replacing mock data:**
- [ ] Backend service is implemented
- [ ] Service is tested and working
- [ ] Service is registered in DI
- [ ] Service methods match UI needs
- [ ] Error handling is in place

### Related Protocols

- **DEVELOPMENT_METHODOLOGY.md** - Full development workflow
- **SESSION_START_CHECKLIST.md** - Session start protocol
- **Repository Pattern** - SPOTS offline-first architecture

---

## 🐛 Troubleshooting

### Issue 1: Service Not Found

**Problem:** `ServiceNotFoundException` or service is null

**Solution:**
```dart
// Check service is registered
grep('ServiceName', path: 'lib/injection_container.dart')

// If not registered, add:
sl.registerLazySingleton<ServiceName>(() => ServiceName());

// Verify registration before use
if (!sl.isRegistered<ServiceName>()) {
  throw Exception('ServiceName not registered');
}
```

---

### Issue 2: Data Model Mismatch

**Problem:** Service returns different model than UI expects

**Solution:**
```dart
// Check model types
// Service: core.BrandAccount
// UI: presentation.BrandAccount

// Use mapping if needed:
final coreBrand = await service.getBrandAccount(userId);
final uiBrand = BrandAccount.fromCoreModel(coreBrand);

// Or ensure models are compatible
```

---

### Issue 3: Service Returns Null

**Problem:** Service returns null, UI breaks

**Solution:**
```dart
// Always handle null
final brand = await service.getBrandAccount(userId);
if (brand == null) {
  // Show empty state or error
  setState(() {
    _brandAccount = null;
    _isEmpty = true;
  });
  return;
}
```

---

### Issue 4: Network Errors

**Problem:** Service throws network errors

**Solution:**
```dart
try {
  final data = await service.getData();
} on NetworkException catch (e) {
  // Handle network error
  setState(() => _error = 'Network error: ${e.message}');
} catch (e) {
  // Handle other errors
  setState(() => _error = 'Error: $e');
}
```

---

## 📚 Examples from SPOTS

### Example 1: Brand Dashboard (Current State)

**File:** `lib/presentation/pages/brand/brand_dashboard_page.dart`

**Current (Mock):**
```dart
// Mock analytics data
double _totalInvestment = 3200.0;
double _totalReturns = 1847.0;

// TODO: Load brand account when service available
// Mock data for now
await Future.delayed(const Duration(seconds: 1));
_brandAccount = BrandAccount(id: 'brand-mock-1', ...);
```

**Target (Real):**
```dart
// Get services
final brandService = context.read<BrandAccountService>();
final analyticsService = context.read<BrandAnalyticsService>();

// Load real data
final brand = await brandService.getBrandAccountByUserId(userId);
final analytics = await analyticsService.getBrandAnalytics(brand.id);

setState(() {
  _brandAccount = brand;
  _analytics = analytics;
});
```

---

### Example 2: Repository Pattern (Already Real)

**File:** `lib/data/repositories/spots_repository_impl.dart`

**Already Using Real Data:**
```dart
// Repository already uses real data sources
final remoteSpots = await remoteDataSource.getSpots();
final localSpots = await localDataSource.getAllSpots();

// No mock replacement needed - already real!
```

**Key Point:** Some parts of SPOTS already use real data. Only replace actual mock data.

---

## ✅ Completion Checklist

**Before marking complete:**
- [ ] All mock data identified
- [ ] Service verified and registered
- [ ] Mock data replaced with service calls
- [ ] Loading states handled
- [ ] Error states handled
- [ ] Empty states handled
- [ ] Tested with real backend
- [ ] All mock code removed
- [ ] Comments updated
- [ ] No linter errors
- [ ] No compilation errors

---

## 📖 Reference Documents

- **DEVELOPMENT_METHODOLOGY.md** - Full development workflow
- **SESSION_START_CHECKLIST.md** - Session start protocol
- **START_HERE_NEW_TASK.md** - New task protocol
- **OUR_GUTS.md** - SPOTS philosophy
- **Repository Pattern** - Offline-first architecture

---

**Last Updated:** December 2024  
**Status:** Active - Mandatory Protocol  
**Version:** 1.0

