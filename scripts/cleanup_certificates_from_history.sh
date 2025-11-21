#!/bin/bash
# Git History Cleanup Script for SSL Certificates
# 
# ⚠️  WARNING: This script rewrites Git history!
# 
# This will:
# 1. Remove all .cer files from Git history
# 2. Force-update all branches
# 
# USE ONLY IF:
# - Repository is private OR
# - All collaborators are informed and can re-clone
# - You have backups
#
# After running this, all collaborators must:
# git fetch origin
# git reset --hard origin/main

set -e

echo "⚠️  WARNING: This will rewrite Git history!"
echo "============================================="
echo ""
echo "This script will remove all .cer files from Git history."
echo "This is a destructive operation that cannot be undone."
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "🧹 Cleaning Git history..."

# Use git filter-branch to remove .cer files from all commits
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch *.cer Certificates/*.cer backend.cer supabase.cer" \
  --prune-empty --tag-name-filter cat -- --all

echo ""
echo "✅ Git history cleaned!"
echo ""
echo "📋 Next steps:"
echo "   1. Force push to remote (if you're sure):"
echo "      git push origin --force --all"
echo "      git push origin --force --tags"
echo ""
echo "   2. Inform all collaborators to re-clone the repository"
echo ""
echo "⚠️  IMPORTANT: Only force-push if repository is private"
echo "   or all collaborators are informed!"

