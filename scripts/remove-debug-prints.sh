#!/bin/bash

# ===========================================
# Stockira App - Remove Debug Prints Script
# ===========================================
# This script removes debug print statements from production code

set -e  # Exit on any error

echo "🧹 Stockira App - Removing Debug Prints"
echo "======================================="
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

echo "Removing debug print statements from production code..."
echo ""

# Count total print statements
TOTAL_PRINTS=$(grep -r "print(" lib/ --include="*.dart" 2>/dev/null | wc -l)
print_info "Found $TOTAL_PRINTS print statements in lib/ directory"

if [ $TOTAL_PRINTS -eq 0 ]; then
    print_status "No debug prints found!"
    exit 0
fi

# Ask for confirmation
echo ""
print_warning "This will remove ALL print statements from the lib/ directory"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Operation cancelled"
    exit 0
fi

# Remove print statements (but keep TODO comments)
print_info "Removing debug print statements..."

# Create backup
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
print_info "Creating backup in $BACKUP_DIR/"

# Copy files to backup
cp -r lib/ "$BACKUP_DIR/"

# Remove print statements using sed
find lib/ -name "*.dart" -type f -exec sed -i '' '/^\s*print(/d' {} \;

# Count remaining print statements
REMAINING_PRINTS=$(grep -r "print(" lib/ --include="*.dart" 2>/dev/null | wc -l)
REMOVED_PRINTS=$((TOTAL_PRINTS - REMAINING_PRINTS))

print_status "Removed $REMOVED_PRINTS print statements"
print_info "Remaining print statements: $REMAINING_PRINTS"

if [ $REMAINING_PRINTS -gt 0 ]; then
    print_warning "Some print statements remain:"
    grep -r "print(" lib/ --include="*.dart" 2>/dev/null || true
fi

echo ""
print_status "Debug print removal completed!"
echo ""
echo "📋 Next steps:"
echo "1. Test the app to ensure it still works"
echo "2. Run 'flutter analyze' to check for issues"
echo "3. Commit the changes if everything works"
echo "4. Backup is available in $BACKUP_DIR/ if you need to restore"
echo ""
print_status "Debug print removal script completed successfully!"
