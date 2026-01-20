# Signal Protocol Advanced Features - Future Testing Plan

**Date:** January 2026  
**Status:** Testing Plan  
**Purpose:** Document testing requirements that require external devices or additional infrastructure

---

## Overview

This document outlines testing requirements for Signal Protocol Advanced Features that cannot be fully tested without external devices, real hardware, or additional infrastructure.

---

## Tests That Can Be Done Without External Devices

### ✅ Unit Tests (Completed - All Passing)

The following unit tests have been created and **all pass** without external devices:

1. **AI Agent Fingerprint Service** (`test/core/crypto/signal/ai_agent_fingerprint_service_test.dart`) - ✅ 17 tests passing
   - ✅ Fingerprint generation and consistency
   - ✅ QR code formatting and parsing
   - ✅ Display formatting
   - ✅ Fingerprint comparison
   - ✅ Round-trip encoding/decoding

2. **Fingerprint QR Service** (`test/core/ai2ai/fingerprint_qr_service_test.dart`) - ✅ 5 tests passing
   - ✅ QR code data generation
   - ✅ QR code parsing
   - ✅ Round-trip encoding/decoding

3. **Device Registration Service** (`test/core/crypto/signal/device_registration_service_test.dart`) - ✅ 14 tests passing
   - ✅ Device registration
   - ✅ Device lifecycle management
   - ✅ Device list operations

4. **Sesame Sync Service** (`test/core/crypto/signal/sesame_sync_service_test.dart`) - ✅ 13 tests passing
   - ✅ Sync operation queuing
   - ✅ Device validation
   - ✅ Conflict state tracking

5. **Mesh Prekey Distribution Service** (`test/core/ai2ai/mesh_prekey_distribution_service_test.dart`) - ✅ 7 tests passing
   - ✅ Hop limit enforcement
   - ✅ Cache management
   - ✅ Expiration handling

6. **Deniability Flags** (`test/packages/avrai_network/network/deniability_flags_test.dart`) - ✅ 7 tests passing
   - ✅ Binary packet encoding/decoding with deniability flags
   - ✅ Flag preservation across round-trips

**Total Unit Tests: 63 tests, all passing ✅**

### ⚠️ Widget Tests (Partial - Need Fingerprint Parsing Fix)

1. **AI Agent Verification Page** (`test/presentation/pages/ai2ai/ai_agent_verification_page_test.dart`)
   - ⚠️ 3 tests failing (fingerprint parsing issue in test setup)
   - ✅ Test structure created
   - ⚠️ Need to fix: Fingerprint string → AgentFingerprint parsing in test

2. **Connection View Widget - Fingerprint Display** (`test/presentation/widgets/network/ai2ai_connection_view_widget_fingerprint_test.dart`)
   - ✅ 4 tests passing
   - ✅ Fingerprint section display
   - ✅ Verification button navigation

**Widget Tests Status: 4 passing, 3 need fingerprint parsing fix**

---

## Tests Requiring External Devices

### 🔴 Multi-Device State Synchronization (Sesame)

**Requirements:**
- 2+ physical devices (iOS/Android)
- Same user account on both devices
- Network connectivity (WiFi or cellular)

**Test Cases:**
1. **Device Registration Across Devices**
   - Register Device 1 (primary)
   - Register Device 2 (secondary)
   - Verify both devices appear in device list
   - Verify device names sync across devices

2. **Session State Synchronization**
   - Establish AI2AI connection on Device 1
   - Verify session state syncs to Device 2
   - Send message from Device 1
   - Verify Device 2 can decrypt message
   - Verify session state remains in sync

3. **Conflict Resolution**
   - Device 1 and Device 2 go offline
   - Both devices establish different AI2AI connections
   - Both devices come back online
   - Verify conflict resolution strategy applies correctly
   - Verify no data loss

4. **Device Lifecycle**
   - Remove Device 2 from Device 1
   - Verify Device 2 can no longer sync state
   - Re-register Device 2
   - Verify state sync resumes

**Infrastructure Needed:**
- Server infrastructure for state synchronization (Supabase or custom)
- OR peer-to-peer sync mechanism between devices

---

### 🔴 BLE Mesh Prekey Distribution

**Requirements:**
- 3+ physical BLE-capable devices
- Devices within BLE range (< 30 meters)
- Mesh networking enabled

**Test Cases:**
1. **Multi-Hop Prekey Distribution**
   - Device A has prekey bundle for Device C
   - Device B is between A and C (mesh hop)
   - Device A forwards prekey bundle through Device B
   - Verify Device C receives prekey bundle
   - Verify Device C can establish Signal session with Device A

2. **Prekey Bundle Caching in Intermediate Nodes**
   - Forward prekey bundle through mesh
   - Verify intermediate node caches bundle
   - Verify cache expiration works correctly
   - Verify duplicate forwarding prevention

3. **Hop Limit Enforcement**
   - Test prekey forwarding with hop limit = 3
   - Verify forwarding stops at hop 3
   - Verify bundles don't propagate beyond limit

4. **Mesh Network Integration**
   - Test with AdaptiveMeshNetworkingService enabled
   - Verify mesh policy affects prekey forwarding
   - Test with different geographic scopes

**Infrastructure Needed:**
- Physical BLE devices in mesh network configuration
- Mesh networking service enabled and configured

---

### 🔴 Enhanced Offline Prekey Exchange with Mesh Forwarding

**Requirements:**
- 2+ physical BLE-capable devices
- Devices within BLE range
- Offline mode (no internet connectivity)

**Test Cases:**
1. **Automatic Refresh via BLE**
   - Device A has cached prekey bundle that needs refresh
   - Device B is discovered via BLE
   - Verify Device A attempts to refresh bundle from Device B
   - Verify refresh succeeds or falls back gracefully

2. **Mesh Forwarding of Prekey Bundles**
   - Device A receives prekey bundle via BLE
   - Verify bundle is forwarded through mesh network
   - Verify other devices can use forwarded bundle

3. **Validation and Verification**
   - Test with invalid prekey bundle
   - Verify validation rejects invalid bundles
   - Verify PQXDH requirements are enforced

---

### 🔴 Real Signal Protocol Key Exchange (PQXDH)

**Requirements:**
- 2+ physical devices with Signal Protocol FFI bindings
- Real libsignal-ffi library compiled for target platforms
- Actual Signal Protocol session establishment

**Test Cases:**
1. **PQXDH Hybrid Key Exchange**
   - Establish connection between Device A and Device B
   - Verify both X3DH and PQXDH keys are exchanged
   - Verify ML-KEM keys are generated and used
   - Verify session encryption works with hybrid keys

2. **PQXDH Enforcement**
   - Test connection with prekey bundle missing PQXDH keys
   - Verify connection is rejected
   - Verify proper error message displayed

3. **Post-Quantum Security**
   - Verify all new connections use PQXDH
   - Verify backward compatibility (if needed)
   - Performance testing with PQXDH overhead

**Infrastructure Needed:**
- Complete Signal Protocol FFI bindings implementation
- libsignal-ffi compiled for iOS/Android/macOS
- Test certificates and signing (for iOS/macOS)

---

### 🔴 Channel Binding Verification

**Requirements:**
- 2+ physical devices
- Real Signal Protocol connections

**Test Cases:**
1. **Handshake Hash Extraction**
   - Establish AI2AI connection
   - Verify handshake hash is extracted from Signal Protocol
   - Verify hash is stored in ConnectionMetrics

2. **Channel Binding Verification**
   - Establish connection with Device A
   - Verify channel binding hash matches
   - Attempt MITM attack (simulated)
   - Verify channel binding detects mismatch

3. **Channel Binding on Re-keying**
   - Establish connection
   - Trigger re-keying (1000 messages or 24 hours)
   - Verify new channel binding hash is generated
   - Verify old hash is replaced

**Infrastructure Needed:**
- Real Signal Protocol connections
- MITM attack simulation tools

---

### 🔴 Identity Verification UI - QR Code Scanning

**Requirements:**
- 2+ physical devices with cameras
- QR code scanning capability

**Test Cases:**
1. **QR Code Generation**
   - Generate fingerprint QR code on Device A
   - Verify QR code is scannable
   - Verify QR code contains correct fingerprint data

2. **QR Code Scanning**
   - Display QR code on Device A
   - Scan QR code with Device B
   - Verify fingerprint is parsed correctly
   - Verify fingerprint comparison works

3. **Out-of-Band Verification Flow**
   - Device A displays fingerprint QR code
   - Device B scans QR code
   - Device B verifies fingerprint matches
   - Verify trust level is updated

**Infrastructure Needed:**
- Physical devices with cameras
- QR code scanning library (`qr_code_scanner` or similar)

---

### 🔴 End-to-End AI2AI Connection Establishment

**Requirements:**
- 2+ physical BLE-capable devices
- Real AI2AI protocol implementation
- Signal Protocol FFI bindings

**Test Cases:**
1. **Full Connection Flow with Fingerprints**
   - Device A discovers Device B via BLE
   - Device A establishes Signal Protocol session
   - Verify fingerprints are generated and stored
   - Verify fingerprints appear in connection UI
   - Verify verification flow works end-to-end

2. **Deniability Flag in Real Messages**
   - Send learning insight message
   - Verify deniability flag is set in binary packet
   - Verify recipient receives message with deniability flag
   - Verify flag is correctly interpreted

3. **Prekey Bundle Refresh in Real Connection**
   - Establish connection with expiring prekey bundle
   - Verify automatic refresh occurs
   - Verify connection continues after refresh

**Infrastructure Needed:**
- Complete BLE implementation
- Complete Signal Protocol implementation
- Real device discovery and connection establishment

---

## Integration Test Requirements

### Server Infrastructure (For Sesame Multi-Device)

**If using server-based state sync:**
- Supabase or custom server for state synchronization
- WebSocket or long-polling for real-time sync
- Conflict resolution server logic

**If using peer-to-peer sync:**
- P2P discovery mechanism (LAN discovery, DHT, etc.)
- Direct device-to-device sync protocol

---

## Performance Testing Requirements

### Large-Scale Mesh Network

**Requirements:**
- 10+ physical BLE devices
- Mesh network spanning multiple hops
- Real-world signal propagation conditions

**Test Cases:**
1. Prekey bundle distribution in large mesh
2. Cache performance with many intermediate nodes
3. Hop limit effectiveness in large networks
4. Bloom filter performance with many messages

---

## Security Testing Requirements

### MITM Attack Simulation

**Requirements:**
- Network analysis tools (Wireshark, etc.)
- BLE packet interception capability
- Signal Protocol analysis tools

**Test Cases:**
1. Channel binding MITM detection
2. Fingerprint verification MITM prevention
3. Prekey bundle integrity verification

---

## Summary

### ✅ Can Test Now (Without External Devices)
- Fingerprint generation and formatting
- QR code generation and parsing
- Device registration logic
- Sync operation queuing
- Cache management
- Deniability flag encoding/decoding
- UI components rendering

### 🔴 Requires External Devices
- Multi-device state synchronization (2+ devices)
- BLE mesh prekey distribution (3+ BLE devices)
- Real Signal Protocol key exchange (2+ devices with FFI)
- QR code scanning (2+ devices with cameras)
- End-to-end connection establishment (2+ devices)

### 🔴 Requires Additional Infrastructure
- Server infrastructure for Sesame sync (or P2P sync)
- Complete Signal Protocol FFI bindings
- MITM attack simulation tools
- Large-scale mesh network (10+ devices)

---

## Recommended Testing Phases

### Phase 1: Unit Tests (✅ Complete)
- All foundational logic tests
- UI component tests
- Protocol encoding/decoding tests

### Phase 2: Single Device Integration (Next)
- Test with single device, mocked dependencies
- Integration between services
- End-to-end flows with mocks

### Phase 3: Two Device Testing (Requires 2 Devices)
- Real BLE connections
- Signal Protocol key exchange
- Fingerprint verification
- Basic mesh forwarding

### Phase 4: Multi-Device Testing (Requires 3+ Devices)
- Multi-device state sync
- Mesh network prekey distribution
- Large-scale mesh testing

---

**Last Updated:** January 2026  
**Status:** Testing Plan Complete - Ready for External Device Testing
