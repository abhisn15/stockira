#!/bin/bash

# ===========================================
# Stockira App - Security Check Script
# ===========================================
# This script checks for security issues in the codebase
# Run this script to verify security configuration

set -e  # Exit on any error

echo "🔍 Stockira App - Security Check"
echo "================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "This script must be run from the project root directory"
    exit 1
fi

echo "Checking security configuration..."
echo ""

# Initialize counters
ISSUES_FOUND=0
WARNINGS_FOUND=0

# Function to increment issue counter
increment_issue() {
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
}

# Function to increment warning counter
increment_warning() {
    WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
}

# 1. Check for sensitive files in git
print_info "Checking for sensitive files in git..."
SENSITIVE_FILES=$(git ls-files | grep -E "\.(env|properties|xcconfig)$" | grep -v "example" || true)
if [ -n "$SENSITIVE_FILES" ]; then
    print_error "Sensitive files found in git repository:"
    echo "$SENSITIVE_FILES"
    increment_issue
else
    print_status "No sensitive files found in git repository"
fi

# 2. Check for hardcoded API keys in source code
print_info "Checking for hardcoded API keys in source code..."
API_KEY_PATTERNS=(
    "AIza[0-9A-Za-z_-]{35}"
    "sk_[0-9A-Za-z]{48}"
    "pk_[0-9A-Za-z]{48}"
    "AKIA[0-9A-Z]{16}"
    "[0-9a-f]{32}"
    "[0-9a-f]{40}"
    "[0-9a-f]{64}"
)

for pattern in "${API_KEY_PATTERNS[@]}"; do
    HARDCODED_KEYS=$(grep -r "$pattern" lib/ --include="*.dart" 2>/dev/null || true)
    if [ -n "$HARDCODED_KEYS" ]; then
        print_error "Potential hardcoded API keys found:"
        echo "$HARDCODED_KEYS"
        increment_issue
    fi
done

if [ $ISSUES_FOUND -eq 0 ]; then
    print_status "No hardcoded API keys found in source code"
fi

# 3. Check for .env file
print_info "Checking for .env file..."
if [ -f ".env" ]; then
    print_status ".env file exists"
    
    # Check if .env contains placeholder values
    if grep -q "your_.*_here" .env; then
        print_warning ".env file contains placeholder values"
        increment_warning
    fi
else
    print_warning ".env file not found"
    increment_warning
fi

# 4. Check for Android local.properties
print_info "Checking for Android local.properties..."
if [ -f "android/local.properties" ]; then
    print_status "android/local.properties exists"
    
    # Check if it contains placeholder values
    if grep -q "your_.*_here" android/local.properties; then
        print_warning "android/local.properties contains placeholder values"
        increment_warning
    fi
else
    print_warning "android/local.properties not found"
    increment_warning
fi

# 5. Check for iOS ApiKeys.xcconfig
print_info "Checking for iOS ApiKeys.xcconfig..."
if [ -f "ios/Configuration/ApiKeys.xcconfig" ]; then
    print_status "ios/Configuration/ApiKeys.xcconfig exists"
    
    # Check if it contains placeholder values
    if grep -q "your_.*_here" ios/Configuration/ApiKeys.xcconfig; then
        print_warning "ios/Configuration/ApiKeys.xcconfig contains placeholder values"
        increment_warning
    fi
else
    print_warning "ios/Configuration/ApiKeys.xcconfig not found"
    increment_warning
fi

# 6. Check .gitignore configuration
print_info "Checking .gitignore configuration..."
REQUIRED_IGNORES=(".env" "local.properties" "ApiKeys.xcconfig")
for ignore in "${REQUIRED_IGNORES[@]}"; do
    if grep -q "$ignore" .gitignore; then
        print_status "$ignore is properly ignored"
    else
        print_error "$ignore is not in .gitignore"
        increment_issue
    fi
done

# 7. Check for example files
print_info "Checking for example files..."
EXAMPLE_FILES=("env.example" "android/local.properties.example" "ios/Configuration/ApiKeys.xcconfig.example")
for example in "${EXAMPLE_FILES[@]}"; do
    if [ -f "$example" ]; then
        print_status "$example exists"
    else
        print_warning "$example not found"
        increment_warning
    fi
done

# 8. Check for debug prints in production code
print_info "Checking for debug prints in production code..."
DEBUG_PRINTS=$(grep -r "print(" lib/ --include="*.dart" 2>/dev/null | grep -v "// TODO: Remove debug print" || true)
if [ -n "$DEBUG_PRINTS" ]; then
    print_warning "Debug prints found in production code:"
    echo "$DEBUG_PRINTS"
    increment_warning
else
    print_status "No debug prints found in production code"
fi

# 9. Check for TODO comments with sensitive information
print_info "Checking for TODO comments with sensitive information..."
SENSITIVE_TODOS=$(grep -r "TODO.*password\|TODO.*key\|TODO.*secret\|TODO.*token" lib/ --include="*.dart" 2>/dev/null || true)
if [ -n "$SENSITIVE_TODOS" ]; then
    print_warning "TODO comments with potentially sensitive information found:"
    echo "$SENSITIVE_TODOS"
    increment_warning
else
    print_status "No sensitive TODO comments found"
fi

# 10. Check for unused imports
print_info "Checking for unused imports..."
if command -v dart &> /dev/null; then
    UNUSED_IMPORTS=$(dart analyze --no-fatal-infos 2>&1 | grep "unused_import" || true)
    if [ -n "$UNUSED_IMPORTS" ]; then
        print_warning "Unused imports found (may indicate incomplete refactoring):"
        echo "$UNUSED_IMPORTS"
        increment_warning
    else
        print_status "No unused imports found"
    fi
else
    print_warning "Dart analyzer not available, skipping unused imports check"
fi

echo ""
echo "🔍 Security Check Summary"
echo "========================="
echo ""

if [ $ISSUES_FOUND -eq 0 ] && [ $WARNINGS_FOUND -eq 0 ]; then
    print_status "All security checks passed! 🎉"
    echo ""
    echo "Your codebase appears to be secure and properly configured."
    exit 0
elif [ $ISSUES_FOUND -eq 0 ]; then
    print_warning "Security check completed with $WARNINGS_FOUND warning(s)"
    echo ""
    echo "No critical issues found, but please review the warnings above."
    exit 0
else
    print_error "Security check failed with $ISSUES_FOUND issue(s) and $WARNINGS_FOUND warning(s)"
    echo ""
    echo "Please fix the issues above before proceeding."
    exit 1
fi
