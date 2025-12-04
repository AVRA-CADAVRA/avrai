# SPOTS Service Matrix

**Last Updated:** November 25, 2025  
**Status:** 🟡 **IN PROGRESS** - Initial Matrix  
**Purpose:** Dependency relationships, ownership, and integration matrix for all SPOTS services

---

## 📊 Overview

This matrix tracks:
- **Service Dependencies**: Which services depend on which
- **Service Ownership**: Agent/file ownership (if applicable)
- **Integration Points**: How services integrate with each other
- **Data Flow**: Data flow between services

---

## 🔗 Service Dependencies

### **Admin Services**

| Service | Depends On | Used By |
|---------|-----------|---------|
| `admin_auth_service.dart` | `SharedPreferences` | `admin_god_mode_service.dart` |
| `admin_communication_service.dart` | `ConnectionMonitor` | `admin_god_mode_service.dart` |
| `admin_god_mode_service.dart` | `AdminAuthService`, `AdminCommunicationService`, `BusinessAccountService`, `PredictiveAnalytics`, `ConnectionMonitor`, `SupabaseService`, `ExpertiseService` | UI: `god_mode_dashboard_page.dart` |
| `admin_privacy_filter.dart` | None (utility) | `admin_god_mode_service.dart` |
| `role_management_service.dart` | `StorageService`, `SharedPreferences` | Various services |

### **Payment & Revenue Services**

| Service | Depends On | Used By |
|---------|-----------|---------|
| `payment_service.dart` | `StripeService`, `ExpertiseEventService` | `payment_event_service.dart`, UI: `checkout_page.dart` |
| `stripe_service.dart` | `StripeConfig` | `payment_service.dart` |
| `payout_service.dart` | None (stub) | Future: `payment_service.dart` |
| `payment_event_service.dart` | `PaymentService`, `ExpertiseEventService` | Event payment flows |
| `refund_service.dart` | `PaymentService` | Event cancellation flows |
| `revenue_split_service.dart` | `PaymentService` | Event revenue distribution |
| `sales_tax_service.dart` | `PaymentService` | `payment_service.dart` |
| `tax_compliance_service.dart` | `SalesTaxService` | `payment_service.dart` |
| `dispute_resolution_service.dart` | `PaymentService` | Admin/admin flows |

### **Business Services**

| Service | Depends On | Used By |
|---------|-----------|---------|
| `business_service.dart` | `StorageService` | Various business features |
| `business_account_service.dart` | None | `admin_god_mode_service.dart` |
| `business_verification_service.dart` | `StorageService` | Business onboarding |
| `business_expert_matching_service.dart` | `LLMService`, `ExpertiseService` | Business-expert matching UI |
| `product_sales_service.dart` | `BusinessService` | Product tracking |
| `product_tracking_service.dart` | `ProductSalesService` | Product analytics |
| `brand_analytics_service.dart` | `BusinessService` | Brand analytics |
| `brand_discovery_service.dart` | `BusinessService` | Brand discovery |

### **Expertise Services**

| Service | Depends On | Used By |
|---------|-----------|---------|
| `expertise_service.dart` | `StorageService` | `admin_god_mode_service.dart`, various expertise features |
| `expertise_calculation_service.dart` | `ExpertiseService` | `expertise_service.dart` |
| `expertise_community_service.dart` | `ExpertiseService` | Community expertise features |
| `expertise_curation_service.dart` | `ExpertiseService` | Expertise curation |
| `expertise_event_service.dart` | `ExpertiseService` | `payment_service.dart`, event features |
| `expertise_matching_service.dart` | `ExpertiseService` | Matching features |
| `expertise_network_service.dart` | `ExpertiseService` | Network features |
| `expertise_recognition_service.dart` | `ExpertiseService` | Recognition features |
| `expert_recommendations_service.dart` | `ExpertiseService` | Recommendation features |
| `expert_search_service.dart` | `ExpertiseService` | Search features |
| `expansion_expertise_gain_service.dart` | `ExpertiseService` | Expansion features |
| `multi_path_expertise_service.dart` | `ExpertiseService` | Multi-path features |
| `golden_expert_ai_influence_service.dart` | `ExpertiseService` | AI influence features |

### **Event Services**

| Service | Depends On | Used By |
|---------|-----------|---------|
| `event_template_service.dart` | None | Event creation UI |
| `event_matching_service.dart` | `ExpertiseEventService` | Event matching |
| `event_recommendation_service.dart` | `ExpertiseEventService` | Event recommendations |
| `event_safety_service.dart` | `ExpertiseEventService` | Event safety checks |
| `event_success_analysis_service.dart` | `ExpertiseEventService` | Post-event analysis |
| `post_event_feedback_service.dart` | `ExpertiseEventService` | Feedback collection |
| `cancellation_service.dart` | `ExpertiseEventService`, `PaymentService` | Event cancellation |
| `automatic_check_in_service.dart` | `ExpertiseEventService` | Check-in automation |

### **Community & Club Services**

| Service | Depends On | Used By |
|---------|-----------|---------|
| `community_service.dart` | `StorageService` | Community features |
| `club_service.dart` | `CommunityService` | Club features |
| `community_event_service.dart` | `CommunityService`, `ExpertiseEventService` | Community events |
| `community_event_upgrade_service.dart` | `CommunityService`, `ExpertiseEventService` | Event upgrades |
| `community_trend_detection_service.dart` | `CommunityService` | Trend detection |
| `community_validation_service.dart` | `StorageService`, `SharedPreferences` | Validation features |

### **AI & ML Services**

| Service | Depends On | Used By |
|---------|-----------|---------|
| `llm_service.dart` | `ConfigService`, `SupabaseService` | `business_expert_matching_service.dart`, AI features |
| `ai_search_suggestions_service.dart` | `HybridSearchRepository` | Search UI |
| `ai_improvement_tracking_service.dart` | `StorageService` | AI improvement tracking |
| `ai2ai_realtime_service.dart` | `PersonalityLearning`, `VibeConnectionOrchestrator` | AI2AI features |
| `personality_analysis_service.dart` | `PersonalityLearning` | Personality features |
| `contextual_personality_service.dart` | `PersonalityAnalysisService` | Contextual personality |
| `user_preference_learning_service.dart` | `StorageService` | Preference learning |
| `predictive_analysis_service.dart` | `StorageService` | `admin_god_mode_service.dart` |

### **Geographic & Location Services**

| Service | Depends On | Used By |
|---------|-----------|---------|
| `large_city_detection_service.dart` | None | `neighborhood_boundary_service.dart` |
| `neighborhood_boundary_service.dart` | `LargeCityDetectionService`, `StorageService` | Location features |
| `geographic_expansion_service.dart` | `GeographicScopeService` | Expansion features |
| `geographic_scope_service.dart` | `StorageService` | Scope features |
| `locality_personality_service.dart` | `PersonalityAnalysisService` | Locality personality |
| `cross_locality_connection_service.dart` | `LocalityPersonalityService` | Cross-locality features |

### **Google Places Services**

| Service | Depends On | Used By |
|---------|-----------|---------|
| `google_place_id_finder_service.dart` | `http.Client` | Legacy (deprecated) |
| `google_place_id_finder_service_new.dart` | `http.Client` | `google_places_sync_service.dart` |
| `google_places_cache_service.dart` | None | `google_places_sync_service.dart` |
| `google_places_sync_service.dart` | `GooglePlaceIdFinderServiceNew`, `GooglePlacesCacheService`, `GooglePlacesDataSource`, `SpotsLocalDataSource`, `Connectivity` | Spot sync |

### **Infrastructure Services**

| Service | Depends On | Used By |
|---------|-----------|---------|
| `storage_service.dart` | `SharedPreferences` | Many services |
| `supabase_service.dart` | None | `admin_god_mode_service.dart`, `llm_service.dart` |
| `enhanced_connectivity_service.dart` | `Connectivity` | Connectivity features |
| `config_service.dart` | None | `llm_service.dart` |

---

## 👥 Service Ownership

### **Agent 1: Payment Processing & Revenue**
**Owns (Can Create/Modify):**
- `payment_service.dart` ✅
- `stripe_service.dart` ✅
- `payout_service.dart` ✅
- `payment_event_service.dart` ✅
- `refund_service.dart` ✅
- `revenue_split_service.dart` ✅
- `sales_tax_service.dart` ✅
- `tax_compliance_service.dart` ✅
- `dispute_resolution_service.dart` ✅

**Can Read (But NOT Modify):**
- `expertise_event_service.dart` (Agent 2 might modify)
- `expertise_service.dart` (Agent 3 might modify)

### **Agent 2: Event Discovery & Hosting UI**
**Owns (Can Create/Modify):**
- `event_template_service.dart` ✅
- `event_matching_service.dart` ✅
- `event_recommendation_service.dart` ✅
- `event_safety_service.dart` ✅
- `event_success_analysis_service.dart` ✅
- `post_event_feedback_service.dart` ✅
- `cancellation_service.dart` ✅
- `automatic_check_in_service.dart` ✅

**Can Read (But NOT Modify):**
- `payment_service.dart` (Agent 1 owns)
- `expertise_event_service.dart` (can use, but coordinate changes)

**Note:** `expertise_event_service.dart` is shared - all agents can use, but coordinate changes

### **Agent 3: Expertise UI & Testing**
**Owns (Can Create/Modify):**
- `expertise_service.dart` ✅ (may modify)
- `expertise_calculation_service.dart` ✅
- `expertise_community_service.dart` ✅
- `expertise_curation_service.dart` ✅
- `expertise_matching_service.dart` ✅
- `expertise_network_service.dart` ✅
- `expertise_recognition_service.dart` ✅
- `expert_recommendations_service.dart` ✅
- `expert_search_service.dart` ✅
- `expansion_expertise_gain_service.dart` ✅
- `multi_path_expertise_service.dart` ✅
- `golden_expert_ai_influence_service.dart` ✅

**Can Read (But NOT Modify):**
- `payment_service.dart` (Agent 1 owns)
- `expertise_event_service.dart` (Agent 2 might modify)
- `event_template_service.dart` (Agent 2 owns)

### **Shared Services (All Agents - Coordinate Changes)**
- `storage_service.dart` - Core infrastructure, all agents use
- `supabase_service.dart` - Database access, all agents use
- `config_service.dart` - Configuration, all agents use
- `expertise_event_service.dart` - Shared event service, coordinate changes
- `llm_service.dart` - AI service, all agents use
- `admin_god_mode_service.dart` - Admin service, read-only access for most

### **System Services (No Specific Owner)**
- `community_service.dart` - System service
- `club_service.dart` - System service
- `business_service.dart` - System service
- `ai2ai_realtime_service.dart` - System service
- `personality_analysis_service.dart` - System service
- All analytics services - System services
- All geographic services - System services
- All security services - System services

---

## 🔄 Integration Patterns

### **Payment → Event Integration**
```
PaymentService → ExpertiseEventService
PaymentEventService (bridge)
```

### **Expertise → Event Integration**
```
ExpertiseService → ExpertiseEventService
EventTemplateService → ExpertiseEventService
```

### **AI → Business Integration**
```
LLMService → BusinessExpertMatchingService
PersonalityAnalysisService → UserBusinessMatchingService
```

### **Community → Event Integration**
```
CommunityService → CommunityEventService → ExpertiseEventService
```

### **Admin → All Services**
```
AdminGodModeService → Multiple services (read-only access)
AdminPrivacyFilter → All admin data access
```

---

## 📊 Data Flow Matrix

### **User Action → Service Chain Examples**

1. **Create Event:**
   ```
   UI → EventTemplateService → ExpertiseEventService → StorageService
   ```

2. **Process Payment:**
   ```
   UI → PaymentService → StripeService → External API
   PaymentService → ExpertiseEventService (update event)
   ```

3. **Match Business to Expert:**
   ```
   UI → BusinessExpertMatchingService → LLMService
   BusinessExpertMatchingService → ExpertiseService
   ```

4. **Admin View Data:**
   ```
   UI → AdminGodModeService → Multiple services (read-only)
   AdminGodModeService → AdminPrivacyFilter → Return filtered data
   ```

---

## 🚨 Critical Dependencies

### **High Dependency Services** (Many services depend on these)
- `storage_service.dart` - Used by 30+ services
- `expertise_service.dart` - Used by 15+ services
- `expertise_event_service.dart` - Used by 10+ services
- `payment_service.dart` - Used by 5+ services

### **Leaf Services** (No dependencies, or minimal)
- `config_service.dart`
- `large_city_detection_service.dart`
- `event_template_service.dart`
- `admin_privacy_filter.dart`

---

## 📝 Notes

1. **Dependency Injection**: All services registered in `lib/injection_container.dart`
2. **Circular Dependencies**: Avoided through dependency injection
3. **Service Ownership**: See `docs/agents/protocols/file_ownership.md` for detailed ownership
4. **Shared Services**: Coordinate changes to shared services
5. **High-Dependency Services**: `StorageService` and `ExpertiseService` are used by many services - changes require careful coordination

---

## 🔗 Cross-References

### **Related Documentation**
- **Service Index**: [`SERVICE_INDEX.md`](./SERVICE_INDEX.md) - Complete service catalog
- **Feature Matrix**: [`../feature_matrix/FEATURE_MATRIX.md`](../feature_matrix/FEATURE_MATRIX.md) - Feature-to-service mapping
- **Architecture Index**: [`../architecture/ARCHITECTURE_INDEX.md`](../architecture/ARCHITECTURE_INDEX.md) - Architecture documentation
- **Master Plan**: [`../../MASTER_PLAN.md`](../../MASTER_PLAN.md) - Implementation roadmap
- **File Ownership**: [`../../agents/protocols/file_ownership.md`](../../agents/protocols/file_ownership.md) - Agent ownership rules
- **Development Methodology**: [`../methodology/DEVELOPMENT_METHODOLOGY.md`](../methodology/DEVELOPMENT_METHODOLOGY.md) - Development practices

### **Implementation Files**
- **Dependency Injection**: `lib/injection_container.dart` - All services registered here
- **Service Directory**: `lib/core/services/` - All service implementations
- **Test Directory**: `test/unit/services/` - All service tests

---

## 🔄 Maintenance

This matrix should be updated:
- When service dependencies change
- When new services are added
- When services are refactored
- When ownership changes
- Quarterly review for accuracy

**Update Checklist:**
- [ ] Dependencies verified
- [ ] Integration patterns documented
- [ ] Ownership updated
- [ ] Data flow examples current
- [ ] Cross-references added

**Last Verified:** November 25, 2025  
**Next Review:** December 25, 2025

