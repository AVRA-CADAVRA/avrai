## Release Gate Checklist — Core App Scope (Suggestions + Vibe Knowledge + Lists + Spots) v1

**Audience:** You + anyone doing a release cut  
**Goal:** A single go/no-go checklist for shipping a **fully functional SPOTS app** where:
- **Suggestions** are useful and vibe-aligned (not random)
- **Vibe knowledge** is visible, stable, and improves suggestions
- **Lists** are first-class (create/edit/view/share baseline UX)
- **Spot knowledge** is first-class (details, edits, persistence, offline-read)

This checklist is **repo-specific**: it points at the tests, pages, and scripts you already have.

---

## Scope (what “done” means for this release)

### In scope (must work)
- **Auth + onboarding**: user can sign in and reach the core UX.
- **Suggestions/search**: user can ask for/find “doors” (spots) and get meaningful results.
- **LLM-assisted “ask SPOTS” UX**: when the AI command UI is available, it must be helpful online and degrade gracefully offline (no crashes, no infinite spinners).
- **Vibe knowledge**: user can view/understand their vibe profile; suggestions are consistent with it.
- **Spots**: browse, view details, create/edit (as supported), and persist.
- **Lists**: browse, create/edit, view details, and persist.
- **Offline-first baseline**: app remains usable offline for previously loaded/persisted data; actions don’t crash.
  - Note: some AI features require either cloud or an enabled local model; in those cases, UX must be explicit (offline message / fallback).

### Explicitly out of scope (allowed to be incomplete *only if gated/off*)
Examples: payments, partnerships, outside-buyer exports, BLE background “24/7”, full AI2AI offline handshake.
If any of these are present in builds, they must still meet the **“no crash / safe fallback”** gates below.

---

## Gate 0 — Build + boot sanity (required)

### Pass criteria
- **Android**: `debug` and `release` build install and boot without crash loop.
- **iOS**: `debug` and `release` build install and boot without crash loop.
- App remains usable if Supabase creds are missing (shows a clear failure mode, no crash).

### Evidence
- Manual install/run on at least one iOS device + one Android device (see real-device gates).

---

## Gate 1 — Core UX: Spots (required)

### Must pass (user-visible)
- **Browse spots** works: `SpotsPage` renders with non-empty state or a correct empty state.
- **Spot details** opens and renders without exceptions.
- **Create/edit spot** works (if enabled in UI) and persists after app restart.

### Repo anchors
- Pages:
  - `lib/presentation/pages/spots/spots_page.dart`
  - `lib/presentation/pages/spots/spot_details_page.dart`
  - `lib/presentation/pages/spots/create_spot_page.dart`
  - `lib/presentation/pages/spots/edit_spot_page.dart`

### Automated verification (must be green)
- Run: `test/suites/spots_lists_suite.sh`
  - Includes widget tests under `test/widget/pages/spots/` and related repository tests.

---

## Gate 2 — Core UX: Lists (required)

### Must pass (user-visible)
- **Browse lists** works: `ListsPage` renders with non-empty state or correct empty state.
- **Create list** works end-to-end and persists.
- **List details** loads and remains stable offline for previously loaded list data.

### Repo anchors
- Pages:
  - `lib/presentation/pages/lists/lists_page.dart`
  - `lib/presentation/pages/lists/create_list_page.dart`
  - `lib/presentation/pages/lists/list_details_page.dart`
  - `lib/presentation/pages/lists/edit_list_page.dart`

### Automated verification (must be green)
- Run: `test/suites/spots_lists_suite.sh`

---

## Gate 3 — Core UX: Suggestions & search (required)

### Must pass (user-visible)
- User can query and receive results that are:
  - not empty when data exists
  - stable across repeated runs
  - plausibly aligned with the user’s vibe/profile signals
- Results UX is not “mystery meat”: basic “why this door?” affordance exists if the UI supports it.

### Repo anchors
- Page:
  - `lib/presentation/pages/search/hybrid_search_page.dart`

### Automated verification (must be green)
- Run: `test/suites/search_suite.sh`

---

## Gate 3.5 — LLM + “Ask SPOTS” command UX (required)

This gate is specifically about the **LLM-backed UI flows** that power “ask SPOTS” style suggestions and action parsing.

### Must pass (user-visible)
- The command UI can:
  - respond when online (cloud path)
  - show the thinking indicator and finish (no stuck overlay)
  - handle failure modes without crashing (timeouts, 429/rate limit, cloud outage)
- Offline behavior must be **truthful and explicit**:
  - If a local model is **not enabled/available**, show an offline error message (not a spinner).
  - If a local model **is enabled and installed**, local generation must work without network.

### What the app actually does today (truthful implementation notes)
- LLM entrypoint: `lib/core/services/llm_service.dart`
  - **Cloud** uses a failover backend: `CloudFailoverBackend(primary: CloudGeminiBackend(), fallback: CloudGeminiGenerationBackend())`.
  - Cloud requests are protected by a **circuit breaker** (opens after 5 consecutive failures for ~5 minutes).
  - **Local** is optional + gated:
    - Eligibility is checked via `DeviceCapabilityService` + `OnDeviceAiCapabilityGate`.
    - Local is opt-in (`offline_llm_enabled_v1`) and requires an active model directory/id in prefs.
    - Local backends are:
      - Android: `llama_flutter_android` (`AndroidLlamaFlutterAndroidBackend`)
      - iOS/other: platform channel `spots/local_llm` (`LocalPlatformLlmBackend`) — requires native integration to exist on that platform build.
- The “ask SPOTS” UI path uses `AICommandProcessor`:
  - `lib/presentation/widgets/common/ai_command_processor.dart`
  - Integrated in home/chat UI and has dedicated tests (see below).

### Automated verification (must be green)
- Run: `test/suites/ai_ml_suite.sh`
  - Includes:
    - `test/unit/services/llm_service_test.dart`
    - `test/unit/services/llm_service_language_style_test.dart`
    - `test/integration/ui_llm_integration_test.dart`

### Real-device verification (recommended, because app-switch + thermal + streaming differ)
- On one iOS device + one Android device:
  - online request succeeds
  - induced network drop produces a clean offline failure state
  - local model (if enabled) can answer offline

---

## Gate 4 — Vibe knowledge (required)

### Must pass (user-visible)
- User can view their vibe/personality status without crashes.
- Vibe representation is stable across app restarts (persisted).
- “Learning” features do not degrade into placeholders silently.

### Repo anchors
- Pages:
  - `lib/presentation/pages/profile/profile_page.dart`
  - `lib/presentation/pages/profile/ai_personality_status_page.dart`

### Automated verification (must be green)
- Run: `test/suites/ai_ml_suite.sh`
  - Includes `test/widget/pages/profile/` plus multiple AI-learning integration tests.

---

## Gate 5 — Offline-first baseline (required)

### Must pass (user-visible)
- With airplane mode / no network:
  - app still boots
  - previously loaded spots/lists still render (cached/persisted)
  - user actions do not crash (queue or clear “offline” UX)
- When network returns:
  - app recovers without needing a reinstall
  - no infinite spinners / stuck states

### Automated verification (must be green)
- Run: `test/suites/spots_lists_suite.sh`
  - Includes `test/integration/offline_online_sync_test.dart`
- Run: `test/suites/infrastructure_suite.sh`
  - Includes connectivity/storage/supabase integration checks.

---

## Gate 6 — Auth readiness (required)

### Must pass (user-visible)
- Sign in / sign out works.
- Signed-out users do not see authenticated-only data.
- Auth failures are surfaced cleanly (no crash loops).

### Automated verification (must be green)
- Run: `test/suites/auth_suite.sh`

---

## Gate 7 — Privacy + security invariants (required)

### Must pass
- No production `print()` logging (enforce `developer.log()` / `AppLogger`).
- RLS-sensitive flows do not leak data cross-user.
- AI2AI payload validation blocks identifiers/PII (even if AI2AI is not a core release feature).

### Automated verification (must be green)
- Run: `test/suites/security_suite.sh`

---

## Gate 7.25 — Ops checklist: Paperwork retention + ledger receipts (required if shipped)

This gate applies if the release build includes **any** of:
- tax docs (W-9 / 1099-K flows)
- disputes (evidence upload / display)
- “Receipts” UI (ledger receipts)

Full technical contract: `docs/agents/protocols/PAPERWORK_DOCUMENTS_RETENTION_AND_LEDGER_RECEIPTS.md`

### Must be present (backend artifacts)
- **Ledger receipts (tamper-evident)**
  - Migration: `supabase/migrations/060_ledger_receipts_v0.sql`
  - Edge function deployed: `supabase/functions/ledger-receipts-v0/index.ts`
- **Tax docs storage + retention**
  - Migrations:
    - `supabase/migrations/061_tax_documents_supabase_storage_v1.sql`
    - `supabase/migrations/062_tax_documents_retention_lock_v1.sql`
- **Paperwork docs bucket (disputes/contracts/etc.) + retention**
  - Migration: `supabase/migrations/063_paperwork_documents_bucket_v1.sql`
  - Expected buckets (private):
    - `tax-documents`
    - `paperwork-documents`

### Sanity checks (Supabase Dashboard)
- **Bucket privacy**
  - Storage → Buckets → confirm `tax-documents` and `paperwork-documents` are **not public**
- **Retention lock**
  - Storage → Policies (or DB policies on `storage.objects`) → confirm there are **no user policies** that allow `UPDATE` or `DELETE` on objects for:
    - bucket `tax-documents`
    - bucket `paperwork-documents`
- **Path ownership rule (paperwork-documents)**
  - Confirm user upload policy is constrained to `storage.foldername(name)[1] = auth.uid()`

### Sanity checks (app behavior, manual)
- **No overwrite**
  - Upload the “same” tax doc twice (same path/key) → second upload must fail (no silent overwrite).
  - Upload dispute evidence twice with the same object name/key → second upload must fail.
- **Evidence renders**
  - Submit dispute with 1–2 images → Dispute status page displays thumbnails (via signed URLs).
- **Receipts are showable**
  - Profile → Receipts shows the new events and verification is non-error (signed when available).

---

## Gate 7.5 — Federated learning (truthful + non-blocking) (required if user-visible)

Federated learning exists in the repo in **two different layers** today. This gate ensures release messaging/UX is honest and that the feature cannot destabilize the core app.

### A) Federated “rounds” system (local / simulated)
- **Code**: `lib/core/p2p/federated_learning.dart` (`FederatedLearningSystem`)
- **UI**: `lib/presentation/pages/settings/federated_learning_page.dart` and widgets under `lib/presentation/widgets/settings/`
- **Truth note**: this subsystem is implemented as a local/system simulation with persistence and UI, not as a production-grade cross-device aggregation pipeline.

### B) Federated cloud sync v1 (AI2AI delta upload → global-average priors)
- **Edge Function**: `supabase/functions/federated-sync/index.ts`
  - Accepts `schema_version=1` and a bounded `deltas` array (max 50 per request).
  - Clamps delta values to \([-0.35, 0.35]\).
  - Returns `global_average_deltas` (category → vector) over a 24h window (best-effort).
- **Client**: `lib/core/ai2ai/connection_orchestrator.dart`
  - Uploads a queued batch to `federated-sync` (source: `ai2ai_ble`).
  - Applies returned `global_average_deltas` as a lightweight prior via `OnnxDimensionScorer().updateWithDeltas(priors)`.

### Must pass (user-visible + stability)
- If federated learning UI is reachable in the build:
  - The page loads without crashing and toggles persist locally.
  - Any privacy claims shown to users must match what is truly happening in this release build.
- Federated sync must be **best-effort**:
  - failures do not crash the app
  - no UI hangs / infinite spinners caused by sync

### Automated verification (must be green if federated UI is shipped)
- Unit:
  - `test/unit/p2p/federated_learning_test.dart`
  - `test/unit/ai2ai/federated_learning_codec_test.dart`
- Widget:
  - `test/widget/pages/settings/federated_learning_page_test.dart`
  - `test/widget/widgets/settings/federated_learning_settings_section_test.dart`
  - `test/widget/widgets/settings/federated_learning_status_widget_test.dart`
  - `test/widget/widgets/settings/federated_participation_history_widget_test.dart`
- Integration:
  - `test/integration/federated_learning_backend_integration_test.dart`
  - `test/integration/federated_learning_e2e_test.dart`

### Real-device experimentation (recommended)
- If `federated-sync` is enabled in production:
  - verify requests succeed under real mobile networking conditions
  - verify the app remains stable under repeated background/foreground cycles

---

## Truth Notes — Current “Overclaims” (and what would make them true later)

This section is intentionally blunt: it lists **specific user-facing copy** that currently describes a *future* federated learning system more than the one running in this repo today.

Use this as:
- a release-comms guardrail (don’t promise what’s not shipping yet),
- and a “future checklist” (so these statements stop being overclaims later).

### Overclaim #1: “Your device trains a local model… sends encrypted model updates… improved global model distributed back”

**Where it appears (current build):**
- `lib/presentation/pages/settings/federated_learning_page.dart` (footer text)
- `lib/presentation/widgets/settings/federated_learning_settings_section.dart` (info dialog)
- `lib/presentation/widgets/settings/federated_learning_status_widget.dart` (info dialog)

**Why it’s an overclaim today (truth):**
- The **federated rounds UI** is backed by `FederatedLearningSystem` (`lib/core/p2p/federated_learning.dart`), which is a **local/system simulation** (persistence + UI + “rounds” objects), not a production multi-device training pipeline.
- The **cloud federated path that is real today** is `federated-sync`:
  - clients upload **bounded embedding deltas** (not model weights/gradients),
  - and the server returns **global_average_deltas** (a lightweight prior), not a full “improved global model” artifact.

**What would make it true later:**
- A real federated training protocol with:
  - true model update computation (weights/gradients),
  - secure aggregation across devices/orgs,
  - a versioned global model artifact,
  - and a distribution mechanism back to devices (with rollback safety).

### Overclaim #2: “Your data never leaves your device” / “All learning happens on your device”

**Where it appears (current build):**
- `lib/presentation/pages/settings/federated_learning_page.dart` (“Your data never leaves your device”)
- `lib/presentation/widgets/settings/continuous_learning_controls_widget.dart` (“All learning happens on your device. Your data never leaves your device.”)

**Why it’s an overclaim today (truth):**
- If the user opts into federated participation, the app can upload **anonymized/privately bounded deltas** to the cloud via:
  - `lib/core/ai2ai/connection_orchestrator.dart` → `supabase.functions.invoke('federated-sync', …)`
  - `supabase/functions/federated-sync/index.ts` stores deltas server-side for aggregation.
- When using cloud LLM:
  - requests go to Supabase Edge Functions:
    - `llm-chat` and `llm-generation` (see `lib/core/services/llm_service.dart`)
  - which necessarily means **some user-provided text/context leaves the device** (over TLS). In the current code, `LLMContext.toJson()` can include `userId` and precise `location.lat/lng`.

**What is true today (and safe to claim):**
- Raw training data is not uploaded *as raw rows* in the federated sync path; the client uploads **bounded deltas** (privacy-preserving intent).
- A large amount of learning/personalization is indeed on-device (local persistence, local scoring), but “never leaves” is too absolute for the current build.

**What would make it fully true later:**
- A release mode where:
  - federated sync is disabled or fully local-only,
  - cloud LLM is disabled by default (or replaced by local-only inference),
  - and any network exports are provably absent (audited).

### Overclaim #3: “Encrypted model updates” (wording nuance)

**Where it appears:** federated learning UI copy (same as above).

**Why it’s misleading today (truth):**
- Current cloud sync uses HTTPS + Supabase auth; it is transport-encrypted, but **not application-layer end-to-end encryption** of updates (and the edge function writes with service role).

**What would make it true later:**
- Application-layer encryption of updates with keys not accessible to the server (plus verifiable secure aggregation).

---

## Safe-to-claim wording (current repo truth)

Below are copy blocks you can use **today** without overclaiming. They’re written to preserve the important distinction you care about:
- **User data**: raw personal data (identity, precise location history, contacts, raw messages you didn’t explicitly choose to send).
- **Agent data**: privacy-bounded, derived learning signals (e.g., small delta vectors / anonymized summaries) produced by the agent.

### A) Federated learning (learning claims)

**Short (settings subtitle):**
> “Learning happens on your device. If you opt in to network learning, your agent may share small, privacy‑bounded updates — not your raw personal data.”

**Medium (settings body):**
> “SPOTS does on-device learning by default. If you enable federated participation, your agent can upload small, privacy‑bounded delta vectors derived from learning events (patterns), so the network can compute a lightweight prior. We don’t upload raw location history, raw chat logs, or contacts for this.”

**Technical (FAQ / privacy page):**
> “Federated cloud sync v1 uploads bounded embedding deltas (clamped vectors + coarse metadata like category/timestamp). The server aggregates these into `global_average_deltas` and returns them as a network prior; it does not distribute a ‘global model’ artifact in v1.”

### B) Cloud AI / LLM (avoid absolute “never leaves device”)

If you want to keep the “only agent data leaves device” claim **strictly true**, the safe claim is conditional:

**Strict conditional (best for privacy-forward messaging):**
> “Your personal data stays on-device for learning. When you choose cloud AI, the text you submit (and the context needed to answer) is sent securely to our servers to generate a response.”

**If you want a stronger ‘agent-only’ framing (still truthful):**
> “SPOTS does not upload raw personal data for learning. Network sharing, when enabled, uses agent-derived, privacy-bounded updates. Cloud AI is separate: it processes what you explicitly send to the AI, over an encrypted connection.”

### C) What to avoid saying right now (until implementation matches)

Avoid absolute claims like:
- “Your data never leaves your device.”
- “All learning happens on your device.” (if federated sync is enabled)
- “We only send encrypted model updates.” (implies application-layer E2EE / secure aggregation)

---

## Gate 8 — On-device ML runtime (strongly recommended real-device)

### Why real devices
Simulators/emulators don’t represent real memory pressure, CPU throttling, or GPU/NN acceleration.

### Must pass on at least one iOS device + one mid-tier Android device
- App remains responsive when:
  - loading any on-device models you ship
  - generating suggestions / scoring
- No OOM / ANR / watchdog termination.

### Automated verification (must be green)
- Run: `test/suites/ai_ml_suite.sh`

---

## Gate 9 — “No crash, safe fallback” for advanced subsystems (required)

Even if these aren’t core to this release, they must not destabilize the core app.

### Signal Protocol (native)
- Must not prevent app boot if unavailable; fallback encryption must work where used.
- Real-device proof is preferred for anything claiming “Signal is on”.

### BLE / AI2AI discovery
- Must not crash the app if permissions are denied or hardware is unavailable.
- Must not drain battery unexpectedly (see real-device experimentation).

---

## Gate 10 — Real-device experimentation matrix (go/no-go for production)

This is the “truth layer” that simulators can’t cover. Mark each item:
- **GO** (validated)
- **BLOCKED** (no devices yet)
- **NO-GO** (validated failing)

### A) Signal DM over real Supabase transport (Real device)
- **Target**: iOS↔Android, plus iOS↔iOS and Android↔Android
- **Proof artifact**:
  - `integration_test/signal_two_device_transport_smoke_test.dart`
  - `scripts/smoke/run_signal_two_device_transport_smoke.sh`
- **Pass criteria**:
  - first message (PreKey) decrypts
  - second message (session) decrypts
  - no crashes during decrypt path

### B) BLE discovery + RF/OS variance (Real device)
- Validate foreground discovery reliability under real RF conditions.
- Validate deny/allow permission paths.
- Reference plan: `docs/plans/ai2ai_system/BLE_BACKGROUND_USAGE_IMPROVEMENT_PLAN.md`

### C) Background behavior (Real device)
- Android: doze, battery saver, background restrictions.
- iOS: background modes constraints.

### D) Permissions edge cases (Real device)
- “deny once”, “deny forever”, later enable in settings.
- iOS Bluetooth permission timing.
- Android scan permission + location behavior across OS versions.

### E) Storage persistence (Real device)
- Ensure vibe/profile + lists/spots + keys persist across app restart and device reboot.

### F) Maps/GPS + geocoding (Real device)
- Validate location permission and map rendering performance on real hardware.

### G) LLM cloud path + failover behavior (Real device)
- Validate “Ask SPOTS” produces a response when online.
- Induce a failure (toggle network mid-request or force a timeout) and confirm:
  - request fails gracefully (no stuck thinking overlay)
  - cloud failover path is exercised (best-effort)
  - repeated failures do not crash the app (circuit breaker behavior is non-fatal)

### H) Local LLM offline path (Real device; only if enabled/marketed)
- If offline LLM is offered in the build:
  - install/activate a local model pack
  - confirm offline requests succeed using the local backend
  - confirm local streaming UI completes and doesn’t hang

### I) Federated cloud sync v1 (Real device; only if enabled/marketed)
- After at least one AI2AI learning event, confirm the cloud sync path is non-blocking:
  - edge function call succeeds or fails gracefully
  - no user-visible crash/hang even under flaky networking
  - if `global_average_deltas` is returned, applying it does not destabilize scoring

### J) WiFi Scanning for Check-In (Real device)
- **Phase 10.1:** Multi-layered proximity-triggered check-in system
- **Android WiFi Scanning:**
  - Validate `wifi_scan` package can detect nearby WiFi networks (SSID, BSSID, signal strength)
  - Verify location permission is properly requested and granted
  - Test WiFi fingerprinting validation for indoor location verification
  - Confirm scanning works on Android 10+ (requires location permission)
- **iOS WiFi Current SSID:**
  - Validate `wifi_iot` package can retrieve current connected SSID/BSSID
  - Verify iOS privacy limitations (only current network, not full scanning)
- **Integration Testing:**
  - Test WiFi fingerprint validation in check-in flow
  - Verify WiFi fingerprint matching increases check-in confidence score
  - Test fallback behavior when WiFi scanning fails or is unavailable

### Optional high-value experiments (Real device)
- Deep links / OAuth app-switch return paths (`app_links`, `google_sign_in`)
- Push notification delivery behavior (if enabled)
- Stripe / 3DS / app-switch flows (if enabled)
- HealthKit / Health Connect flows (if enabled)

---

## Minimum automated test set for a release cut (must be green)

Run the focused suites first:
- `test/suites/auth_suite.sh`
- `test/suites/infrastructure_suite.sh`
- `test/suites/spots_lists_suite.sh`
- `test/suites/search_suite.sh`
- `test/suites/ai_ml_suite.sh`
- `test/suites/security_suite.sh`

If federated learning UI is shipped/visible in the build, also run:
- `flutter test test/unit/p2p/federated_learning_test.dart test/unit/ai2ai/federated_learning_codec_test.dart`
- `flutter test test/widget/pages/settings/federated_learning_page_test.dart test/widget/widgets/settings/`
- `flutter test test/integration/federated_learning_backend_integration_test.dart test/integration/federated_learning_e2e_test.dart`

Optional (when actively iterating on BLE/Signal):
- `test/suites/ble_signal_suite.sh`

---

## Release decision

### GO
All required gates (0–7) are green, and the real-device matrix has no **NO-GO** items for subsystems included in the release build.

### Conditional GO (internal/TestFlight only)
Required gates are green, but one or more real-device items are **BLOCKED** (no hardware yet). Ship only if the blocked subsystem is disabled/gated and cannot impact the core UX.

### NO-GO
Any of:
- crashes in core flows (spots/lists/search/vibe)
- data loss in lists/spots persistence
- permission denial causes crash or unrecoverable UX
- real-device Signal DM transport fails while marketed/enabled
- real-device LLM flow hangs/crashes while marketed/enabled
- federated sync causes instability/crashes while marketed/enabled

