# Legacy Services Inventory

**Date:** December 2, 2025, 5:04 PM CST  
**Status:** Active Documentation

---

## Overview

This document lists all legacy and deprecated services in the SPOTS codebase. These services are kept for reference but are no longer used in production and should not be used in new code.

---

## Legacy Services

### 1. **GooglePlaceIdFinderService** ⚠️ DEPRECATED

**Location:** `lib/core/services/google_place_id_finder_service.dart`

**Status:** ⚠️ **DEPRECATED**  
**Reason:** Uses legacy Google Places API  
**Migration:** ✅ Complete  
**Replacement:** `GooglePlaceIdFinderServiceNew`

**Details:**
- Uses legacy Google Places API (old endpoints)
- Kept for reference only
- Migration completed: See `GOOGLE_PLACES_API_NEW_MIGRATION_COMPLETE.md`

**Replacement Service:**
- **File:** `lib/core/services/google_place_id_finder_service_new.dart`
- **Class:** `GooglePlaceIdFinderServiceNew`
- **Uses:** New Places API (New) endpoints

**Test File:** `test/unit/services/google_place_id_finder_service_test.dart`
- ✅ Has ignore comments for deprecation warnings
- Tests legacy service intentionally

---

### 2. **GooglePlacesDataSourceImpl** ⚠️ DEPRECATED

**Location:** `lib/data/datasources/remote/google_places_datasource_impl.dart`

**Status:** ⚠️ **DEPRECATED**  
**Reason:** Uses legacy Google Places API  
**Migration:** ✅ Complete  
**Replacement:** `GooglePlacesDataSourceNewImpl`

**Details:**
- Implements `GooglePlacesDataSource` interface
- Uses legacy Google Places API (old endpoints)
- Kept for reference only
- Migration completed: See `GOOGLE_PLACES_API_NEW_MIGRATION_COMPLETE.md`

**Replacement Service:**
- **File:** `lib/data/datasources/remote/google_places_datasource_new_impl.dart`
- **Class:** `GooglePlacesDataSourceNewImpl`
- **Uses:** New Places API (New) endpoints

---

## Migration Status

### ✅ **Google Places API Migration - COMPLETE**

**Migration Date:** 2024  
**Status:** ✅ **COMPLETE**

**Migrated Services:**
1. ✅ `GooglePlaceIdFinderService` → `GooglePlaceIdFinderServiceNew`
2. ✅ `GooglePlacesDataSourceImpl` → `GooglePlacesDataSourceNewImpl`

**Migration Documentation:**
- Migration Plan: `docs/plans/google_places_migration/GOOGLE_PLACES_API_NEW_MIGRATION_PLAN.md`
- Migration Complete: `docs/plans/google_places_migration/GOOGLE_PLACES_API_NEW_MIGRATION_COMPLETE.md`

---

## Service Replacement Guide

### When to Use Legacy Services

❌ **DO NOT USE** legacy services in:
- New code
- Production code
- Feature implementations
- Service updates

✅ **ONLY USE** legacy services in:
- Legacy test files (with deprecation warnings ignored)
- Reference/documentation purposes
- Understanding old implementations

### How to Migrate

1. **Identify Legacy Service Usage:**
   - Search for imports of legacy services
   - Check for deprecation warnings

2. **Replace with New Service:**
   - Use the replacement service listed above
   - Update imports
   - Update method signatures if needed

3. **Update Tests:**
   - Migrate tests to use new service
   - Or add ignore comments if testing legacy intentionally

4. **Remove Legacy Service:**
   - After migration is complete and verified
   - Only remove if no longer needed for reference

---

## Legacy Service Summary

| Service | Location | Status | Replacement | Migration Status |
|---------|----------|--------|-------------|------------------|
| `GooglePlaceIdFinderService` | `lib/core/services/google_place_id_finder_service.dart` | ⚠️ Deprecated | `GooglePlaceIdFinderServiceNew` | ✅ Complete |
| `GooglePlacesDataSourceImpl` | `lib/data/datasources/remote/google_places_datasource_impl.dart` | ⚠️ Deprecated | `GooglePlacesDataSourceNewImpl` | ✅ Complete |

---

## Notes

1. **All legacy services are kept for reference** - They are not deleted to maintain historical context
2. **Migration is complete** - All services have been migrated to new implementations
3. **New code should never use legacy services** - Always use the new implementations
4. **Tests may intentionally test legacy services** - These should have deprecation warnings ignored

---

## Related Documentation

- **Service Index:** `docs/plans/services/SERVICE_INDEX.md`
- **Service Matrix:** `docs/plans/services/SERVICE_MATRIX.md`
- **Migration Complete:** `docs/plans/google_places_migration/GOOGLE_PLACES_API_NEW_MIGRATION_COMPLETE.md`
- **Migration Plan:** `docs/plans/google_places_migration/GOOGLE_PLACES_API_NEW_MIGRATION_PLAN.md`

---

**Last Updated:** December 2, 2025, 5:04 PM CST

