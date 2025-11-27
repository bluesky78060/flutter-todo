#!/bin/bash

# Provider Optimization Rollback Script
# This script restores the original provider implementation from backup

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ORIGINAL_FILE="$PROJECT_ROOT/lib/presentation/providers/todo_providers.dart"
BACKUP_FILE="$PROJECT_ROOT/lib/presentation/providers/todo_providers_backup.dart"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Provider Optimization Rollback"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Verify backup exists
echo "📋 Step 1: Verifying backup file..."
if [ ! -f "$BACKUP_FILE" ]; then
  echo "❌ Error: Backup file not found: $BACKUP_FILE"
  echo ""
  echo "Cannot rollback without backup. Migration may not have been run."
  exit 1
fi

echo "✅ Backup file found: $BACKUP_FILE"
echo ""

# Step 2: Confirm rollback
echo "⚠️  Step 2: Rollback confirmation"
echo ""
echo "This will restore the original provider implementation."
echo ""
read -p "Continue with rollback? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "❌ Rollback cancelled"
  exit 1
fi

# Step 3: Restore backup
echo ""
echo "🔄 Step 3: Restoring backup..."
cp "$BACKUP_FILE" "$ORIGINAL_FILE"
echo "✅ Rollback complete!"
echo ""

# Step 4: Cleanup
echo "🧹 Step 4: Cleanup..."
read -p "Delete backup file? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  rm "$BACKUP_FILE"
  echo "✅ Backup file deleted"
else
  echo "ℹ️  Backup file kept at: $BACKUP_FILE"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Rollback successful! ✅"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Hot reload Flutter app: Press 'r'"
echo "  2. Verify functionality is restored"
echo ""
