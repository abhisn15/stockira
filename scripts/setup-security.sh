#!/bin/bash

# ===========================================
# Stockira App - Security Setup Script
# ===========================================
# This script helps set up secure configuration files
# Run this script to create secure environment files

set -e  # Exit on any error

echo "🔐 Stockira App - Security Setup"
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

echo "Setting up secure configuration files..."
echo ""

# 1. Setup .env file
print_info "Setting up environment variables (.env)..."
if [ ! -f ".env" ]; then
    if [ -f "env.example" ]; then
        cp env.example .env
        print_status "Created .env file from template"
        print_warning "Please edit .env file with your actual API keys and credentials"
    else
        print_error "env.example file not found!"
        exit 1
    fi
else
    print_warning ".env file already exists, skipping..."
fi

# 2. Setup Android local.properties
print_info "Setting up Android configuration..."
if [ ! -f "android/local.properties" ]; then
    if [ -f "android/local.properties.example" ]; then
        cp android/local.properties.example android/local.properties
        print_status "Created android/local.properties from template"
        print_warning "Please edit android/local.properties with your actual values"
    else
        print_error "android/local.properties.example file not found!"
        exit 1
    fi
else
    print_warning "android/local.properties already exists, skipping..."
fi

# 3. Setup iOS ApiKeys.xcconfig
print_info "Setting up iOS configuration..."
if [ ! -f "ios/Configuration/ApiKeys.xcconfig" ]; then
    if [ -f "ios/Configuration/ApiKeys.xcconfig.example" ]; then
        cp ios/Configuration/ApiKeys.xcconfig.example ios/Configuration/ApiKeys.xcconfig
        print_status "Created ios/Configuration/ApiKeys.xcconfig from template"
        print_warning "Please edit ios/Configuration/ApiKeys.xcconfig with your actual values"
    else
        print_error "ios/Configuration/ApiKeys.xcconfig.example file not found!"
        exit 1
    fi
else
    print_warning "ios/Configuration/ApiKeys.xcconfig already exists, skipping..."
fi

# 4. Verify .gitignore
print_info "Verifying .gitignore configuration..."
if grep -q "\.env" .gitignore && grep -q "local\.properties" .gitignore && grep -q "ApiKeys\.xcconfig" .gitignore; then
    print_status ".gitignore is properly configured"
else
    print_warning ".gitignore might not be properly configured for security files"
fi

# 5. Check for existing sensitive files in git
print_info "Checking for sensitive files in git..."
if git status --porcelain | grep -E "\.(env|properties|xcconfig)$" | grep -v "example"; then
    print_error "Sensitive files detected in git staging area!"
    print_error "Please remove them before committing:"
    git status --porcelain | grep -E "\.(env|properties|xcconfig)$" | grep -v "example"
    exit 1
else
    print_status "No sensitive files detected in git"
fi

echo ""
echo "🎉 Security setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Edit .env file with your actual API keys"
echo "2. Edit android/local.properties with your actual values"
echo "3. Edit ios/Configuration/ApiKeys.xcconfig with your actual values"
echo "4. Test the app to ensure everything works"
echo "5. Never commit these files to version control"
echo ""
echo "📚 For more information, see SECURITY_SETUP.md"
echo ""
print_status "Security setup script completed successfully!"
