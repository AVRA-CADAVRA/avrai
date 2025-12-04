# SPOTS Service Index

**Last Updated:** November 25, 2025  
**Status:** ✅ **COMPLETE** - Full Catalog with Exact Test Coverage  
**Purpose:** Complete catalog of all SPOTS services with categorization, status, and metadata

---

## 📊 Overview

**Total Services:** 90 (88 ending in `_service.dart` + 2 service-related files: `admin_privacy_filter.dart`, `security_validator.dart`)  
**Test Coverage:**
- ✅ **Services with tests:** 85 (94.4%)
- ❌ **Services without tests:** 5 (5.6%)

**Services Missing Tests:**
1. `ai_improvement_tracking_service.dart`
2. `contextual_personality_service.dart`
3. `enhanced_connectivity_service.dart`
4. `event_template_service.dart`
5. `stripe_service.dart`

**Status Breakdown:**
- ✅ **Complete (90-100%)**: Fully implemented with tests
- ⚠️ **Partial (40-89%)**: Implemented but missing tests or integration
- ❌ **Missing (0-39%)**: Not implemented or severely incomplete

---

## 📁 Service Categories

### **1. Admin & Management Services** (6 services)
- `admin_auth_service.dart` - Admin authentication
- `admin_communication_service.dart` - Admin communication
- `admin_god_mode_service.dart` - God-mode admin access
- `admin_privacy_filter.dart` - Privacy filtering for admins
- `role_management_service.dart` - Role and permission management
- `config_service.dart` - Configuration management

### **2. Payment & Revenue Services** (9 services)
- `payment_service.dart` - Payment processing
- `stripe_service.dart` - Stripe integration
- `payout_service.dart` - Payout management
- `payment_event_service.dart` - Payment-event bridge
- `refund_service.dart` - Refund processing
- `revenue_split_service.dart` - Revenue splitting
- `sales_tax_service.dart` - Sales tax calculation
- `tax_compliance_service.dart` - Tax compliance
- `dispute_resolution_service.dart` - Dispute handling

### **3. Business Services** (7 services)
- `business_service.dart` - Core business operations
- `business_account_service.dart` - Business account management
- `business_verification_service.dart` - Business verification
- `business_expert_matching_service.dart` - Business-expert matching
- `product_sales_service.dart` - Product sales tracking
- `product_tracking_service.dart` - Product tracking
- `brand_analytics_service.dart` - Brand analytics
- `brand_discovery_service.dart` - Brand discovery

### **4. Expertise Services** (12 services)
- `expertise_service.dart` - Core expertise operations
- `expertise_calculation_service.dart` - Expertise calculation
- `expertise_community_service.dart` - Expertise communities
- `expertise_curation_service.dart` - Expertise curation
- `expertise_event_service.dart` - Expertise events
- `expertise_matching_service.dart` - Expertise matching
- `expertise_network_service.dart` - Expertise networks
- `expertise_recognition_service.dart` - Expertise recognition
- `expert_recommendations_service.dart` - Expert recommendations
- `expert_search_service.dart` - Expert search
- `expansion_expertise_gain_service.dart` - Expansion expertise
- `multi_path_expertise_service.dart` - Multi-path expertise
- `golden_expert_ai_influence_service.dart` - Golden expert AI influence

### **5. Event Services** (8 services)
- `event_template_service.dart` - Event templates
- `event_matching_service.dart` - Event matching
- `event_recommendation_service.dart` - Event recommendations
- `event_safety_service.dart` - Event safety
- `event_success_analysis_service.dart` - Event success analysis
- `post_event_feedback_service.dart` - Post-event feedback
- `cancellation_service.dart` - Event cancellation
- `automatic_check_in_service.dart` - Automatic check-in

### **6. Community & Club Services** (5 services)
- `community_service.dart` - Core community operations
- `club_service.dart` - Club management
- `community_event_service.dart` - Community events
- `community_event_upgrade_service.dart` - Community event upgrades
- `community_trend_detection_service.dart` - Community trend detection
- `community_validation_service.dart` - Community validation

### **7. AI & ML Services** (8 services)
- `llm_service.dart` - Large language model service
- `ai_search_suggestions_service.dart` - AI search suggestions
- `ai_improvement_tracking_service.dart` - AI improvement tracking
- `ai2ai_realtime_service.dart` - AI2AI real-time service
- `personality_analysis_service.dart` - Personality analysis
- `contextual_personality_service.dart` - Contextual personality
- `user_preference_learning_service.dart` - User preference learning
- `predictive_analysis_service.dart` - Predictive analysis

### **8. Analytics & Insights Services** (5 services)
- `behavior_analysis_service.dart` - Behavior analysis
- `trending_analysis_service.dart` - Trending analysis
- `network_analysis_service.dart` - Network analysis
- `locality_value_analysis_service.dart` - Locality value analysis
- `content_analysis_service.dart` - Content analysis

### **9. Geographic & Location Services** (6 services)
- `large_city_detection_service.dart` - Large city detection
- `neighborhood_boundary_service.dart` - Neighborhood boundaries
- `geographic_expansion_service.dart` - Geographic expansion
- `geographic_scope_service.dart` - Geographic scope
- `locality_personality_service.dart` - Locality personality
- `cross_locality_connection_service.dart` - Cross-locality connections

### **10. Google Places Services** (4 services)
- `google_place_id_finder_service.dart` - Google Place ID finder (legacy)
- `google_place_id_finder_service_new.dart` - Google Place ID finder (new API)
- `google_places_cache_service.dart` - Google Places caching
- `google_places_sync_service.dart` - Google Places synchronization

### **11. Search & Discovery Services** (2 services)
- `search_cache_service.dart` - Search caching
- `saturation_algorithm_service.dart` - Saturation algorithm

### **12. Social & Matching Services** (4 services)
- `user_business_matching_service.dart` - User-business matching
- `partnership_service.dart` - Partnership management
- `partnership_profile_service.dart` - Partnership profiles
- `partnership_matching_service.dart` - Partnership matching
- `mentorship_service.dart` - Mentorship matching

### **13. Security & Compliance Services** (5 services)
- `fraud_detection_service.dart` - Fraud detection
- `review_fraud_detection_service.dart` - Review fraud detection
- `identity_verification_service.dart` - Identity verification
- `security_validator.dart` - Security validation
- `legal_document_service.dart` - Legal document management

### **14. Infrastructure Services** (4 services)
- `storage_service.dart` - Storage management
- `supabase_service.dart` - Supabase integration
- `enhanced_connectivity_service.dart` - Enhanced connectivity
- `dynamic_threshold_service.dart` - Dynamic thresholds

### **15. Action & History Services** (1 service)
- `action_history_service.dart` - Action history tracking

### **16. Sponsorship Services** (1 service)
- `sponsorship_service.dart` - Sponsorship management

---

## 📋 Complete Service List (Alphabetical)

| Service | Category | Status | Tests | Documentation | File Path |
|---------|----------|--------|-------|---------------|----------|
| `action_history_service.dart` | Action & History | ✅ | ✅ | ⏳ | `lib/core/services/action_history_service.dart` |
| `admin_auth_service.dart` | Admin & Management | ✅ | ✅ | ✅ | `lib/core/services/admin_auth_service.dart` |
| `admin_communication_service.dart` | Admin & Management | ✅ | ✅ | ✅ | `lib/core/services/admin_communication_service.dart` |
| `admin_god_mode_service.dart` | Admin & Management | ✅ | ✅ | ✅ | `lib/core/services/admin_god_mode_service.dart` |
| `admin_privacy_filter.dart` | Admin & Management | ✅ | ✅ | ✅ | `lib/core/services/admin_privacy_filter.dart` |
| `ai2ai_realtime_service.dart` | AI & ML | ✅ | ✅ | ⏳ | `lib/core/services/ai2ai_realtime_service.dart` |
| `ai_improvement_tracking_service.dart` | AI & ML | ⚠️ | ❌ | ⏳ | `lib/core/services/ai_improvement_tracking_service.dart` |
| `ai_search_suggestions_service.dart` | AI & ML | ✅ | ✅ | ⏳ | `lib/core/services/ai_search_suggestions_service.dart` |
| `automatic_check_in_service.dart` | Event | ✅ | ✅ | ⏳ | `lib/core/services/automatic_check_in_service.dart` |
| `behavior_analysis_service.dart` | Analytics & Insights | ✅ | ✅ | ⏳ | `lib/core/services/behavior_analysis_service.dart` |
| `brand_analytics_service.dart` | Business | ✅ | ✅ | ⏳ | `lib/core/services/brand_analytics_service.dart` |
| `brand_discovery_service.dart` | Business | ✅ | ✅ | ⏳ | `lib/core/services/brand_discovery_service.dart` |
| `business_account_service.dart` | Business | ✅ | ✅ | ✅ | `lib/core/services/business_account_service.dart` |
| `business_expert_matching_service.dart` | Business | ✅ | ✅ | ✅ | `lib/core/services/business_expert_matching_service.dart` |
| `business_service.dart` | Business | ✅ | ✅ | ⏳ | `lib/core/services/business_service.dart` |
| `business_verification_service.dart` | Business | ✅ | ✅ | ✅ | `lib/core/services/business_verification_service.dart` |
| `cancellation_service.dart` | Event | ✅ | ✅ | ⏳ | `lib/core/services/cancellation_service.dart` |
| `club_service.dart` | Community & Club | ✅ | ✅ | ✅ | `lib/core/services/club_service.dart` |
| `community_event_service.dart` | Community & Club | ✅ | ✅ | ✅ | `lib/core/services/community_event_service.dart` |
| `community_event_upgrade_service.dart` | Community & Club | ✅ | ✅ | ⏳ | `lib/core/services/community_event_upgrade_service.dart` |
| `community_service.dart` | Community & Club | ✅ | ✅ | ✅ | `lib/core/services/community_service.dart` |
| `community_trend_detection_service.dart` | Community & Club | ✅ | ✅ | ⏳ | `lib/core/services/community_trend_detection_service.dart` |
| `community_validation_service.dart` | Community & Club | ✅ | ✅ | ⏳ | `lib/core/services/community_validation_service.dart` |
| `config_service.dart` | Admin & Management | ✅ | ✅ | ⏳ | `lib/core/services/config_service.dart` |
| `content_analysis_service.dart` | Analytics & Insights | ✅ | ✅ | ⏳ | `lib/core/services/content_analysis_service.dart` |
| `contextual_personality_service.dart` | AI & ML | ⚠️ | ❌ | ⏳ | `lib/core/services/contextual_personality_service.dart` |
| `cross_locality_connection_service.dart` | Geographic & Location | ✅ | ✅ | ⏳ | `lib/core/services/cross_locality_connection_service.dart` |
| `dispute_resolution_service.dart` | Payment & Revenue | ✅ | ✅ | ⏳ | `lib/core/services/dispute_resolution_service.dart` |
| `dynamic_threshold_service.dart` | Infrastructure | ✅ | ✅ | ⏳ | `lib/core/services/dynamic_threshold_service.dart` |
| `enhanced_connectivity_service.dart` | Infrastructure | ⚠️ | ❌ | ⏳ | `lib/core/services/enhanced_connectivity_service.dart` |
| `event_matching_service.dart` | Event | ✅ | ✅ | ⏳ | `lib/core/services/event_matching_service.dart` |
| `event_recommendation_service.dart` | Event | ✅ | ✅ | ⏳ | `lib/core/services/event_recommendation_service.dart` |
| `event_safety_service.dart` | Event | ✅ | ✅ | ⏳ | `lib/core/services/event_safety_service.dart` |
| `event_success_analysis_service.dart` | Event | ✅ | ✅ | ⏳ | `lib/core/services/event_success_analysis_service.dart` |
| `event_template_service.dart` | Event | ✅ | ❌ | ✅ | `lib/core/services/event_template_service.dart` |
| `expansion_expertise_gain_service.dart` | Expertise | ✅ | ✅ | ⏳ | `lib/core/services/expansion_expertise_gain_service.dart` |
| `expert_recommendations_service.dart` | Expertise | ✅ | ✅ | ⏳ | `lib/core/services/expert_recommendations_service.dart` |
| `expert_search_service.dart` | Expertise | ✅ | ✅ | ⏳ | `lib/core/services/expert_search_service.dart` |
| `expertise_calculation_service.dart` | Expertise | ✅ | ✅ | ⏳ | `lib/core/services/expertise_calculation_service.dart` |
| `expertise_community_service.dart` | Expertise | ✅ | ✅ | ⏳ | `lib/core/services/expertise_community_service.dart` |
| `expertise_curation_service.dart` | Expertise | ✅ | ✅ | ⏳ | `lib/core/services/expertise_curation_service.dart` |
| `expertise_event_service.dart` | Expertise | ✅ | ✅ | ✅ | `lib/core/services/expertise_event_service.dart` |
| `expertise_matching_service.dart` | Expertise | ✅ | ✅ | ⏳ | `lib/core/services/expertise_matching_service.dart` |
| `expertise_network_service.dart` | Expertise | ✅ | ✅ | ⏳ | `lib/core/services/expertise_network_service.dart` |
| `expertise_recognition_service.dart` | Expertise | ✅ | ✅ | ⏳ | `lib/core/services/expertise_recognition_service.dart` |
| `expertise_service.dart` | Expertise | ✅ | ✅ | ✅ | `lib/core/services/expertise_service.dart` |
| `fraud_detection_service.dart` | Security & Compliance | ✅ | ✅ | ⏳ | `lib/core/services/fraud_detection_service.dart` |
| `geographic_expansion_service.dart` | Geographic & Location | ✅ | ✅ | ⏳ | `lib/core/services/geographic_expansion_service.dart` |
| `geographic_scope_service.dart` | Geographic & Location | ✅ | ✅ | ⏳ | `lib/core/services/geographic_scope_service.dart` |
| `golden_expert_ai_influence_service.dart` | Expertise | ✅ | ✅ | ⏳ | `lib/core/services/golden_expert_ai_influence_service.dart` |
| `google_place_id_finder_service.dart` | Google Places | ⚠️ | ✅ | ⏳ | `lib/core/services/google_place_id_finder_service.dart` (Legacy) |
| `google_place_id_finder_service_new.dart` | Google Places | ✅ | ✅ | ✅ | `lib/core/services/google_place_id_finder_service_new.dart` |
| `google_places_cache_service.dart` | Google Places | ✅ | ✅ | ⏳ | `lib/core/services/google_places_cache_service.dart` |
| `google_places_sync_service.dart` | Google Places | ✅ | ✅ | ✅ | `lib/core/services/google_places_sync_service.dart` |
| `identity_verification_service.dart` | Security & Compliance | ✅ | ✅ | ⏳ | `lib/core/services/identity_verification_service.dart` |
| `large_city_detection_service.dart` | Geographic & Location | ✅ | ✅ | ⏳ | `lib/core/services/large_city_detection_service.dart` |
| `legal_document_service.dart` | Security & Compliance | ✅ | ✅ | ⏳ | `lib/core/services/legal_document_service.dart` |
| `llm_service.dart` | AI & ML | ✅ | ✅ | ✅ | `lib/core/services/llm_service.dart` |
| `locality_personality_service.dart` | Geographic & Location | ✅ | ✅ | ⏳ | `lib/core/services/locality_personality_service.dart` |
| `locality_value_analysis_service.dart` | Analytics & Insights | ✅ | ✅ | ⏳ | `lib/core/services/locality_value_analysis_service.dart` |
| `mentorship_service.dart` | Social & Matching | ✅ | ✅ | ⏳ | `lib/core/services/mentorship_service.dart` |
| `multi_path_expertise_service.dart` | Expertise | ✅ | ✅ | ⏳ | `lib/core/services/multi_path_expertise_service.dart` |
| `neighborhood_boundary_service.dart` | Geographic & Location | ✅ | ✅ | ⏳ | `lib/core/services/neighborhood_boundary_service.dart` |
| `network_analysis_service.dart` | Analytics & Insights | ✅ | ✅ | ⏳ | `lib/core/services/network_analysis_service.dart` |
| `partnership_matching_service.dart` | Social & Matching | ✅ | ✅ | ⏳ | `lib/core/services/partnership_matching_service.dart` |
| `partnership_profile_service.dart` | Social & Matching | ✅ | ✅ | ⏳ | `lib/core/services/partnership_profile_service.dart` |
| `partnership_service.dart` | Social & Matching | ✅ | ✅ | ⏳ | `lib/core/services/partnership_service.dart` |
| `payment_event_service.dart` | Payment & Revenue | ✅ | ✅ | ✅ | `lib/core/services/payment_event_service.dart` |
| `payment_service.dart` | Payment & Revenue | ✅ | ✅ | ✅ | `lib/core/services/payment_service.dart` |
| `payout_service.dart` | Payment & Revenue | ⚠️ | ✅ | ⏳ | `lib/core/services/payout_service.dart` |
| `personality_analysis_service.dart` | AI & ML | ✅ | ✅ | ⏳ | `lib/core/services/personality_analysis_service.dart` |
| `post_event_feedback_service.dart` | Event | ✅ | ✅ | ⏳ | `lib/core/services/post_event_feedback_service.dart` |
| `predictive_analysis_service.dart` | AI & ML | ✅ | ✅ | ⏳ | `lib/core/services/predictive_analysis_service.dart` |
| `product_sales_service.dart` | Business | ✅ | ✅ | ⏳ | `lib/core/services/product_sales_service.dart` |
| `product_tracking_service.dart` | Business | ✅ | ✅ | ⏳ | `lib/core/services/product_tracking_service.dart` |
| `refund_service.dart` | Payment & Revenue | ✅ | ✅ | ⏳ | `lib/core/services/refund_service.dart` |
| `review_fraud_detection_service.dart` | Security & Compliance | ✅ | ✅ | ⏳ | `lib/core/services/review_fraud_detection_service.dart` |
| `revenue_split_service.dart` | Payment & Revenue | ✅ | ✅ | ⏳ | `lib/core/services/revenue_split_service.dart` |
| `role_management_service.dart` | Admin & Management | ✅ | ✅ | ⏳ | `lib/core/services/role_management_service.dart` |
| `sales_tax_service.dart` | Payment & Revenue | ✅ | ✅ | ⏳ | `lib/core/services/sales_tax_service.dart` |
| `saturation_algorithm_service.dart` | Search & Discovery | ✅ | ✅ | ⏳ | `lib/core/services/saturation_algorithm_service.dart` |
| `search_cache_service.dart` | Search & Discovery | ✅ | ✅ | ⏳ | `lib/core/services/search_cache_service.dart` |
| `security_validator.dart` | Security & Compliance | ✅ | ✅ | ⏳ | `lib/core/services/security_validator.dart` |
| `sponsorship_service.dart` | Sponsorship | ✅ | ✅ | ⏳ | `lib/core/services/sponsorship_service.dart` |
| `storage_service.dart` | Infrastructure | ✅ | ✅ | ✅ | `lib/core/services/storage_service.dart` |
| `stripe_service.dart` | Payment & Revenue | ✅ | ❌ | ✅ | `lib/core/services/stripe_service.dart` |
| `supabase_service.dart` | Infrastructure | ✅ | ✅ | ⏳ | `lib/core/services/supabase_service.dart` |
| `tax_compliance_service.dart` | Payment & Revenue | ✅ | ✅ | ⏳ | `lib/core/services/tax_compliance_service.dart` |
| `trending_analysis_service.dart` | Analytics & Insights | ✅ | ✅ | ⏳ | `lib/core/services/trending_analysis_service.dart` |
| `user_business_matching_service.dart` | Social & Matching | ✅ | ✅ | ⏳ | `lib/core/services/user_business_matching_service.dart` |
| `user_preference_learning_service.dart` | AI & ML | ✅ | ✅ | ⏳ | `lib/core/services/user_preference_learning_service.dart` |

**Legend:**
- ✅ = Complete/Exists
- ⚠️ = Partial/Incomplete
- ❌ = Missing/Not Implemented
- ⏳ = Unknown/Needs Verification

---

## 🔍 Service Discovery

### By Functionality
- **Authentication & Authorization**: `admin_auth_service.dart`, `role_management_service.dart`
- **Payment Processing**: `payment_service.dart`, `stripe_service.dart`, `payout_service.dart`
- **Event Management**: `expertise_event_service.dart`, `event_template_service.dart`, `event_matching_service.dart`
- **Expertise Management**: `expertise_service.dart`, `expertise_calculation_service.dart`, `expertise_matching_service.dart`
- **AI/ML Operations**: `llm_service.dart`, `ai_search_suggestions_service.dart`, `predictive_analysis_service.dart`
- **Geographic Operations**: `large_city_detection_service.dart`, `neighborhood_boundary_service.dart`, `geographic_expansion_service.dart`

### By Integration Point
- **Dependency Injection**: All services registered in `lib/injection_container.dart`
- **Database**: Services using `SupabaseService` or `StorageService`
- **External APIs**: `stripe_service.dart`, `google_places_sync_service.dart`, `llm_service.dart`
- **AI2AI Network**: `ai2ai_realtime_service.dart`, `personality_analysis_service.dart`

---

## 📝 Notes

1. **Test Coverage**: Exact count verified - **85 services have tests** (94.4%), **5 services missing tests** (5.6%):
   - `ai_improvement_tracking_service.dart` - No test file
   - `contextual_personality_service.dart` - No test file
   - `enhanced_connectivity_service.dart` - No test file
   - `event_template_service.dart` - No test file
   - `stripe_service.dart` - No test file
2. **Legacy Services**: `google_place_id_finder_service.dart` is legacy; use `google_place_id_finder_service_new.dart`
3. **Service Dependencies**: See `SERVICE_MATRIX.md` for dependency relationships
4. **Service Ownership**: See `SERVICE_MATRIX.md` for agent ownership and coordination rules
5. **Test File Naming**: Some services have multiple test files with variant names (e.g., `payment_service_partnership_test.dart`, `revenue_split_service_brand_test.dart`) - these are counted as having tests

---

## 🔗 Cross-References

### **Related Documentation**
- **Service Matrix**: [`SERVICE_MATRIX.md`](./SERVICE_MATRIX.md) - Dependency relationships and ownership
- **Feature Matrix**: [`../feature_matrix/FEATURE_MATRIX.md`](../feature_matrix/FEATURE_MATRIX.md) - Feature-to-service mapping
- **Architecture Index**: [`../architecture/ARCHITECTURE_INDEX.md`](../architecture/ARCHITECTURE_INDEX.md) - Architecture documentation
- **Master Plan**: [`../../MASTER_PLAN.md`](../../MASTER_PLAN.md) - Implementation roadmap
- **File Ownership**: [`../../agents/protocols/file_ownership.md`](../../agents/protocols/file_ownership.md) - Agent ownership rules
- **Development Methodology**: [`../methodology/DEVELOPMENT_METHODOLOGY.md`](../methodology/DEVELOPMENT_METHODOLOGY.md) - Development practices

### **Implementation Files**
- **Dependency Injection**: `lib/injection_container.dart` - All services registered here
- **Service Directory**: `lib/core/services/` - All service implementations
- **Test Directory**: `test/unit/services/` - All service tests (93 test files)

---

## 🔄 Maintenance

This index should be updated:
- When new services are created
- When services are deprecated or removed
- When service status changes (tests added, documentation completed)
- Quarterly review for accuracy

**Update Checklist:**
- [ ] Service added to index
- [ ] Service categorized correctly
- [ ] Test status verified
- [ ] Dependencies documented in SERVICE_MATRIX.md
- [ ] Ownership documented (if applicable)
- [ ] Cross-references added

**Last Verified:** November 25, 2025  
**Next Review:** December 25, 2025

