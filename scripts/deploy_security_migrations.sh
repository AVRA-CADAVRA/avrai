#!/bin/bash

# Deploy Security Migrations Script
# Phase 7, Section 43-44: Data Anonymization & Database Security
#
# This script deploys database migrations for:
# - Audit log table
# - Enhanced RLS policies
#
# Usage:
#   ./scripts/deploy_security_migrations.sh [environment]
#   environment: local, staging, production (default: local)

set -e  # Exit on error

ENVIRONMENT=${1:-local}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Deploying Security Migrations"
echo "Environment: $ENVIRONMENT"
echo "=========================================="

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Error: Supabase CLI not found"
    echo "Install from: https://supabase.com/docs/guides/cli"
    exit 1
fi

# Navigate to project root
cd "$PROJECT_ROOT"

# Migration files
MIGRATIONS=(
    "supabase/migrations/010_audit_log_table.sql"
    "supabase/migrations/011_enhance_rls_policies.sql"
)

# Verify migration files exist
for migration in "${MIGRATIONS[@]}"; do
    if [ ! -f "$migration" ]; then
        echo "❌ Error: Migration file not found: $migration"
        exit 1
    fi
done

echo "✅ All migration files found"

# Deploy based on environment
case $ENVIRONMENT in
    local)
        echo "📦 Deploying to local Supabase..."
        
        # Start Supabase if not running
        if ! supabase status &> /dev/null; then
            echo "Starting local Supabase..."
            supabase start
        fi
        
        # Reset database and apply migrations
        echo "Applying migrations..."
        supabase db reset
        
        echo "✅ Local migrations deployed successfully"
        ;;
        
    staging|production)
        echo "📦 Deploying to $ENVIRONMENT..."
        
        # Link to project (if not already linked)
        if [ ! -f ".supabase/config.toml" ]; then
            echo "⚠️  Warning: Supabase project not linked"
            echo "Run: supabase link --project-ref <project-ref>"
            exit 1
        fi
        
        # Push migrations
        echo "Pushing migrations to $ENVIRONMENT..."
        supabase db push
        
        echo "✅ $ENVIRONMENT migrations deployed successfully"
        ;;
        
    *)
        echo "❌ Error: Unknown environment: $ENVIRONMENT"
        echo "Valid environments: local, staging, production"
        exit 1
        ;;
esac

# Verify migrations
echo ""
echo "=========================================="
echo "Verifying Migrations"
echo "=========================================="

# Check if audit_logs table exists
echo "Checking audit_logs table..."
if supabase db execute "SELECT 1 FROM audit_logs LIMIT 1;" &> /dev/null; then
    echo "✅ audit_logs table exists"
else
    echo "⚠️  Warning: Could not verify audit_logs table"
fi

# Check RLS policies
echo "Checking RLS policies..."
if supabase db execute "SELECT COUNT(*) FROM pg_policies WHERE tablename = 'users';" &> /dev/null; then
    echo "✅ RLS policies exist"
else
    echo "⚠️  Warning: Could not verify RLS policies"
fi

echo ""
echo "=========================================="
echo "✅ Deployment Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Verify audit logs are working:"
echo "   SELECT * FROM audit_logs LIMIT 10;"
echo ""
echo "2. Test RLS policies:"
echo "   SELECT * FROM pg_policies WHERE tablename = 'users';"
echo ""
echo "3. Monitor for errors in application logs"
echo ""

