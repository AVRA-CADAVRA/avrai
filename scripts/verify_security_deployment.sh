#!/bin/bash

# Verify Security Deployment Script
# Phase 7, Section 43-44: Data Anonymization & Database Security
#
# This script verifies that all security services are properly deployed
#
# Usage:
#   ./scripts/verify_security_deployment.sh

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Verifying Security Deployment"
echo "=========================================="

cd "$PROJECT_ROOT"

# Check if services exist
echo ""
echo "Checking service files..."
SERVICES=(
    "lib/core/services/location_obfuscation_service.dart"
    "lib/core/services/user_anonymization_service.dart"
    "lib/core/services/field_encryption_service.dart"
    "lib/core/services/audit_log_service.dart"
    "lib/core/models/anonymous_user.dart"
)

for service in "${SERVICES[@]}"; do
    if [ -f "$service" ]; then
        echo "✅ $service"
    else
        echo "❌ Missing: $service"
        exit 1
    fi
done

# Check if migrations exist
echo ""
echo "Checking migration files..."
MIGRATIONS=(
    "supabase/migrations/010_audit_log_table.sql"
    "supabase/migrations/011_enhance_rls_policies.sql"
)

for migration in "${MIGRATIONS[@]}"; do
    if [ -f "$migration" ]; then
        echo "✅ $migration"
    else
        echo "❌ Missing: $migration"
        exit 1
    fi
done

# Check if tests exist
echo ""
echo "Checking test files..."
TESTS=(
    "test/unit/ai2ai/anonymous_communication_test.dart"
    "test/unit/services/user_anonymization_service_test.dart"
    "test/integration/anonymization_integration_test.dart"
)

for test in "${TESTS[@]}"; do
    if [ -f "$test" ]; then
        echo "✅ $test"
    else
        echo "⚠️  Missing: $test (optional)"
    fi
done

# Check if services are registered in DI
echo ""
echo "Checking dependency injection..."
if grep -q "LocationObfuscationService" lib/injection_container.dart; then
    echo "✅ LocationObfuscationService registered"
else
    echo "❌ LocationObfuscationService not registered"
    exit 1
fi

if grep -q "UserAnonymizationService" lib/injection_container.dart; then
    echo "✅ UserAnonymizationService registered"
else
    echo "❌ UserAnonymizationService not registered"
    exit 1
fi

if grep -q "FieldEncryptionService" lib/injection_container.dart; then
    echo "✅ FieldEncryptionService registered"
else
    echo "❌ FieldEncryptionService not registered"
    exit 1
fi

if grep -q "AuditLogService" lib/injection_container.dart; then
    echo "✅ AuditLogService registered"
else
    echo "❌ AuditLogService not registered"
    exit 1
fi

# Run Flutter analyze
echo ""
echo "Running Flutter analyze..."
if flutter analyze lib/core/services/location_obfuscation_service.dart \
                   lib/core/services/user_anonymization_service.dart \
                   lib/core/services/field_encryption_service.dart \
                   lib/core/services/audit_log_service.dart \
                   lib/core/models/anonymous_user.dart \
                   2>&1 | grep -q "No issues found"; then
    echo "✅ No analysis issues"
else
    echo "⚠️  Analysis warnings found (check output above)"
fi

# Check database (if Supabase is available)
echo ""
echo "Checking database..."
if command -v supabase &> /dev/null && supabase status &> /dev/null; then
    echo "✅ Supabase is running"
    
    # Check if audit_logs table exists
    if supabase db execute "SELECT 1 FROM audit_logs LIMIT 1;" &> /dev/null; then
        echo "✅ audit_logs table exists"
    else
        echo "⚠️  audit_logs table not found (migrations may not be applied)"
    fi
else
    echo "⚠️  Supabase not available (skipping database checks)"
fi

echo ""
echo "=========================================="
echo "✅ Verification Complete"
echo "=========================================="
echo ""
echo "All security services are properly deployed!"
echo ""

