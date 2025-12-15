#!/bin/bash

# SPOTS Code Quality Checker Script
# Runs every hour for code quality monitoring
# Date: July 29, 2025

set -e  # Exit on any error

# Configuration
PROJECT_DIR="/Users/reisgordon/SPOTS"
LOG_DIR="$PROJECT_DIR/test/testing/logs"
REPORT_DIR="$PROJECT_DIR/test/testing/reports"
ALERT_DIR="$PROJECT_DIR/test/testing/alerts"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Create directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$REPORT_DIR"
mkdir -p "$ALERT_DIR"

# Log file for this run
LOG_FILE="$LOG_DIR/quality_$TIMESTAMP.log"
REPORT_FILE="$REPORT_DIR/quality_report_$TIMESTAMP.md"

# Function to log messages
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to create alert
create_alert() {
    local alert_type="$1"
    local message="$2"
    local alert_file="$ALERT_DIR/${alert_type}_${TIMESTAMP}.txt"
    echo "[$alert_type] $message" > "$alert_file"
    log_message "ALERT: $alert_type - $message"
}

# Function to count issues by type
count_issues() {
    local log_file="$1"
    local issue_type="$2"
    grep -c "$issue_type" "$log_file" 2>/dev/null || echo "0"
}

# Start quality checking
log_message "=== SPOTS Code Quality Checker Started ==="
log_message "Timestamp: $TIMESTAMP"
log_message "Project Directory: $PROJECT_DIR"

# Change to project directory
cd "$PROJECT_DIR"

# 1. Run Unified Analysis
log_message "Running unified analysis..."
if [ -f "$PROJECT_DIR/unified_analysis.sh" ]; then
    cd "$PROJECT_DIR"
    chmod +x unified_analysis.sh
    
    # Run all analysis modes
    log_message "Running background agent mode..."
    ./unified_analysis.sh auto-fix > "$LOG_DIR/analyzer_auto_fix_$TIMESTAMP.log" 2>&1
    
    log_message "Running critical analysis..."
    ./unified_analysis.sh critical > "$LOG_DIR/analyzer_critical_$TIMESTAMP.log" 2>&1
    
    log_message "Running full analysis..."
    ./unified_analysis.sh full > "$LOG_DIR/analyzer_full_$TIMESTAMP.log" 2>&1
    
    ANALYZER_RESULT="PASS"
    log_message "✅ Unified analysis completed successfully"
else
    # Fallback to standard analysis
    log_message "Unified analysis script not found, using standard analysis..."
    flutter analyze > "$LOG_DIR/analyzer_$TIMESTAMP.log" 2>&1
    ANALYZER_EXIT_CODE=$?
    
    if [ $ANALYZER_EXIT_CODE -eq 0 ]; then
        log_message "✅ Dart analyzer completed successfully"
        ANALYZER_RESULT="PASS"
    else
        log_message "❌ Dart analyzer found issues"
        ANALYZER_RESULT="FAIL"
        create_alert "WARNING" "Dart analyzer found issues - check $LOG_DIR/analyzer_$TIMESTAMP.log"
    fi
fi

# 2. Check Code Formatting
log_message "Checking code formatting..."
dart format --set-exit-if-changed . > "$LOG_DIR/format_$TIMESTAMP.log" 2>&1
FORMAT_EXIT_CODE=$?

if [ $FORMAT_EXIT_CODE -eq 0 ]; then
    log_message "✅ Code formatting is correct"
    FORMAT_RESULT="PASS"
else
    log_message "❌ Code formatting issues found"
    FORMAT_RESULT="FAIL"
    create_alert "WARNING" "Code formatting issues found - run 'dart format .'"
fi

# 3. Count Issue Types (Unified Analysis)
log_message "Analyzing issue types from unified analysis..."
if [ -f "$LOG_DIR/analyzer_full_$TIMESTAMP.log" ]; then
    ERRORS=$(count_issues "$LOG_DIR/analyzer_full_$TIMESTAMP.log" "error")
    WARNINGS=$(count_issues "$LOG_DIR/analyzer_full_$TIMESTAMP.log" "warning")
    INFOS=$(count_issues "$LOG_DIR/analyzer_full_$TIMESTAMP.log" "info")
    TOTAL_ISSUES=$((ERRORS + WARNINGS + INFOS))
    
    # Get auto-fix results
    AUTO_FIX_ISSUES=$(count_issues "$LOG_DIR/analyzer_auto_fix_$TIMESTAMP.log" "error")
    CRITICAL_ISSUES=$(count_issues "$LOG_DIR/analyzer_critical_$TIMESTAMP.log" "error")
    
    log_message "📊 Unified Issue Breakdown:"
    log_message "  Full Analysis - Errors: $ERRORS, Warnings: $WARNINGS, Info: $INFOS"
    log_message "  Auto-Fix Mode - Issues: $AUTO_FIX_ISSUES"
    log_message "  Critical Only - Issues: $CRITICAL_ISSUES"
    log_message "  Total Issues: $TOTAL_ISSUES"
else
    # Fallback to standard counting
    ERRORS=$(count_issues "$LOG_DIR/analyzer_$TIMESTAMP.log" "error")
    WARNINGS=$(count_issues "$LOG_DIR/analyzer_$TIMESTAMP.log" "warning")
    INFOS=$(count_issues "$LOG_DIR/analyzer_$TIMESTAMP.log" "info")
    TOTAL_ISSUES=$((ERRORS + WARNINGS + INFOS))
    
    log_message "📊 Standard Issue Breakdown:"
    log_message "  Errors: $ERRORS"
    log_message "  Warnings: $WARNINGS"
    log_message "  Info: $INFOS"
    log_message "  Total: $TOTAL_ISSUES"
fi

# 4. Check for Deprecated APIs
log_message "Checking for deprecated API usage..."
DEPRECATED_APIS=$(grep -c "deprecated" "$LOG_DIR/analyzer_$TIMESTAMP.log" 2>/dev/null || echo "0")
log_message "🔍 Deprecated APIs Found: $DEPRECATED_APIS"

if [ "$DEPRECATED_APIS" -gt 0 ]; then
    create_alert "WARNING" "Found $DEPRECATED_APIS deprecated API usages"
fi

# 5. Check for Unused Code
log_message "Checking for unused code..."
UNUSED_IMPORTS=$(grep -c "unused import" "$LOG_DIR/analyzer_$TIMESTAMP.log" 2>/dev/null || echo "0")
UNUSED_VARIABLES=$(grep -c "unused" "$LOG_DIR/analyzer_$TIMESTAMP.log" 2>/dev/null || echo "0")
UNUSED_ELEMENTS=$(grep -c "isn't referenced" "$LOG_DIR/analyzer_$TIMESTAMP.log" 2>/dev/null || echo "0")

log_message "🧹 Unused Code Analysis:"
log_message "  Unused Imports: $UNUSED_IMPORTS"
log_message "  Unused Variables: $UNUSED_VARIABLES"
log_message "  Unused Elements: $UNUSED_ELEMENTS"

# 6. Check for Security Issues
log_message "Checking for security issues..."
SECURITY_ISSUES=$(grep -c "security\|vulnerability\|insecure" "$LOG_DIR/analyzer_$TIMESTAMP.log" 2>/dev/null || echo "0")
log_message "🔒 Security Issues Found: $SECURITY_ISSUES"

if [ "$SECURITY_ISSUES" -gt 0 ]; then
    create_alert "CRITICAL" "Found $SECURITY_ISSUES potential security issues"
fi

# 7. Check for Performance Issues
log_message "Checking for performance issues..."
PERFORMANCE_ISSUES=$(grep -c "performance\|memory\|leak" "$LOG_DIR/analyzer_$TIMESTAMP.log" 2>/dev/null || echo "0")
log_message "⚡ Performance Issues Found: $PERFORMANCE_ISSUES"

if [ "$PERFORMANCE_ISSUES" -gt 0 ]; then
    create_alert "WARNING" "Found $PERFORMANCE_ISSUES potential performance issues"
fi

# 8. Check for BuildContext Issues
log_message "Checking for BuildContext issues..."
BUILD_CONTEXT_ISSUES=$(grep -c "BuildContext" "$LOG_DIR/analyzer_$TIMESTAMP.log" 2>/dev/null || echo "0")
log_message "🎨 BuildContext Issues Found: $BUILD_CONTEXT_ISSUES"

if [ "$BUILD_CONTEXT_ISSUES" -gt 0 ]; then
    create_alert "WARNING" "Found $BUILD_CONTEXT_ISSUES BuildContext-related issues"
fi

# 9. Check for Print Statements
log_message "Checking for print statements..."
PRINT_STATEMENTS=$(grep -c "avoid_print" "$LOG_DIR/analyzer_$TIMESTAMP.log" 2>/dev/null || echo "0")
log_message "🖨️ Print Statements Found: $PRINT_STATEMENTS"

if [ "$PRINT_STATEMENTS" -gt 10 ]; then
    create_alert "INFO" "Found $PRINT_STATEMENTS print statements (consider using proper logging)"
fi

# 10. Check for Code Complexity
log_message "Analyzing code complexity..."
COMPLEX_FUNCTIONS=$(grep -c "complex\|cyclomatic" "$LOG_DIR/analyzer_$TIMESTAMP.log" 2>/dev/null || echo "0")
log_message "🧮 Complex Functions Found: $COMPLEX_FUNCTIONS"

if [ "$COMPLEX_FUNCTIONS" -gt 5 ]; then
    create_alert "WARNING" "Found $COMPLEX_FUNCTIONS potentially complex functions"
fi

# 11. Generate Quality Score
log_message "Calculating quality score..."
QUALITY_SCORE=100

# Deduct points for issues
QUALITY_SCORE=$((QUALITY_SCORE - ERRORS * 10))
QUALITY_SCORE=$((QUALITY_SCORE - WARNINGS * 5))
QUALITY_SCORE=$((QUALITY_SCORE - DEPRECATED_APIS * 3))
QUALITY_SCORE=$((QUALITY_SCORE - SECURITY_ISSUES * 20))
QUALITY_SCORE=$((QUALITY_SCORE - PERFORMANCE_ISSUES * 5))

# Ensure score doesn't go below 0
if [ "$QUALITY_SCORE" -lt 0 ]; then
    QUALITY_SCORE=0
fi

log_message "📊 Quality Score: ${QUALITY_SCORE}/100"

# Alert if quality score is low
if [ "$QUALITY_SCORE" -lt 70 ]; then
    create_alert "CRITICAL" "Low code quality score: ${QUALITY_SCORE}/100"
elif [ "$QUALITY_SCORE" -lt 85 ]; then
    create_alert "WARNING" "Code quality score needs improvement: ${QUALITY_SCORE}/100"
fi

# 12. Run Dart Automated Quality Checker
log_message "Running Dart automated quality checker..."
QUALITY_ASSURANCE_DIR="$PROJECT_DIR/test/quality_assurance"
if [ -f "$QUALITY_ASSURANCE_DIR/comprehensive_test_quality_runner.dart" ]; then
    cd "$QUALITY_ASSURANCE_DIR"
    dart comprehensive_test_quality_runner.dart > "$LOG_DIR/dart_quality_checker_$TIMESTAMP.log" 2>&1
    DART_QUALITY_EXIT_CODE=$?
    
    if [ $DART_QUALITY_EXIT_CODE -eq 0 ]; then
        log_message "✅ Dart automated quality checker completed successfully"
        DART_QUALITY_RESULT="PASS"
    else
        log_message "⚠️ Dart automated quality checker found issues (exit code: $DART_QUALITY_EXIT_CODE)"
        DART_QUALITY_RESULT="WARN"
        # Don't fail the entire script for quality checker warnings
    fi
    
    # Extract quality score from the log if available
    DART_QUALITY_SCORE=$(grep -oP "Overall Quality Score: \K[0-9.]+" "$LOG_DIR/dart_quality_checker_$TIMESTAMP.log" 2>/dev/null || echo "N/A")
    if [ "$DART_QUALITY_SCORE" != "N/A" ]; then
        log_message "📊 Dart Quality Score: $DART_QUALITY_SCORE/10.0"
        
        # Alert if quality score is low
        DART_SCORE_NUM=$(echo "$DART_QUALITY_SCORE" | cut -d. -f1)
        if [ "$DART_SCORE_NUM" -lt 8 ]; then
            create_alert "WARNING" "Dart quality checker score below threshold: $DART_QUALITY_SCORE/10.0"
        fi
    fi
else
    log_message "⚠️ Dart quality checker script not found at $QUALITY_ASSURANCE_DIR/comprehensive_test_quality_runner.dart"
    DART_QUALITY_RESULT="SKIP"
fi

cd "$PROJECT_DIR"

# 13. Generate Quality Report
log_message "Generating quality report..."
cat > "$REPORT_FILE" << EOF
# SPOTS Code Quality Report
**Date:** $(date +"%Y-%m-%d %H:%M:%S")
**Quality Score:** ${QUALITY_SCORE}/100

## Analysis Results

### Overall Status
- **Dart Analyzer:** $ANALYZER_RESULT
- **Code Formatting:** $FORMAT_RESULT
- **Dart Quality Checker:** ${DART_QUALITY_RESULT:-SKIP}
- **Total Issues:** $TOTAL_ISSUES

### Issue Breakdown
| Issue Type | Count | Priority |
|------------|-------|----------|
| Errors | $ERRORS | High |
| Warnings | $WARNINGS | Medium |
| Info | $INFOS | Low |
| Deprecated APIs | $DEPRECATED_APIS | Medium |
| Security Issues | $SECURITY_ISSUES | Critical |
| Performance Issues | $PERFORMANCE_ISSUES | Medium |
| BuildContext Issues | $BUILD_CONTEXT_ISSUES | Medium |
| Print Statements | $PRINT_STATEMENTS | Low |
| Complex Functions | $COMPLEX_FUNCTIONS | Medium |

### Unused Code Analysis
- **Unused Imports:** $UNUSED_IMPORTS
- **Unused Variables:** $UNUSED_VARIABLES
- **Unused Elements:** $UNUSED_ELEMENTS

## Quality Metrics

### Score Breakdown
- **Base Score:** 100
- **Error Penalty:** -$((ERRORS * 10))
- **Warning Penalty:** -$((WARNINGS * 5))
- **Deprecated API Penalty:** -$((DEPRECATED_APIS * 3))
- **Security Issue Penalty:** -$((SECURITY_ISSUES * 20))
- **Performance Issue Penalty:** -$((PERFORMANCE_ISSUES * 5))
- **Final Score:** ${QUALITY_SCORE}

### Quality Levels
- **90-100:** Excellent
- **80-89:** Good
- **70-79:** Fair
- **60-69:** Poor
- **0-59:** Critical

## Log Files
- **Quality Log:** \`$LOG_FILE\`
- **Analyzer Output:** \`$LOG_DIR/analyzer_$TIMESTAMP.log\`
- **Format Check:** \`$LOG_DIR/format_$TIMESTAMP.log\`

## Alerts Generated
$(ls -la "$ALERT_DIR"/*"$TIMESTAMP"* 2>/dev/null | wc -l || echo "0") alerts

## Recommendations

### Immediate Actions
- Fix all errors (priority 1)
- Address security issues (priority 1)
- Update deprecated APIs (priority 2)
- Fix code formatting issues (priority 2)

### Improvement Areas
- Reduce unused code
- Replace print statements with proper logging
- Simplify complex functions
- Address BuildContext issues

### Quality Targets
- **Target Quality Score:** >85
- **Target Error Count:** 0
- **Target Warning Count:** <20
- **Target Deprecated APIs:** 0
EOF

log_message "✅ Quality report generated: $REPORT_FILE"

# 14. Auto-fix Simple Issues (if enabled)
if [ "${AUTO_FIX:-false}" = "true" ]; then
    log_message "Attempting auto-fixes..."
    
    # Auto-format code
    if [ "$FORMAT_RESULT" = "FAIL" ]; then
        log_message "Auto-formatting code..."
        dart format . > "$LOG_DIR/auto_format_$TIMESTAMP.log" 2>&1
    fi
    
    # Remove unused imports (basic)
    if [ "$UNUSED_IMPORTS" -gt 0 ]; then
        log_message "Attempting to remove unused imports..."
        # This would require more sophisticated analysis
        log_message "Note: Manual review needed for unused imports"
    fi
fi

# 15. Final Summary
log_message "=== Quality Checker Summary ==="
log_message "Quality Score: ${QUALITY_SCORE}/100"
log_message "Total Issues: $TOTAL_ISSUES"
log_message "Errors: $ERRORS"
log_message "Warnings: $WARNINGS"
log_message "Deprecated APIs: $DEPRECATED_APIS"
log_message "Security Issues: $SECURITY_ISSUES"
log_message "Alerts: $(ls -la "$ALERT_DIR"/*"$TIMESTAMP"* 2>/dev/null | wc -l || echo "0")"
log_message "=== Quality Checker Completed ==="

# Exit with appropriate code
if [ "$QUALITY_SCORE" -lt 60 ] || [ "$ERRORS" -gt 0 ] || [ "$SECURITY_ISSUES" -gt 0 ]; then
    exit 1
else
    exit 0
fi 