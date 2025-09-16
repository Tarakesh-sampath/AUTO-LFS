#!/bin/bash
set -e

HOOK_FILE=".git/hooks/pre-commit"

# --- Step 1: Check if inside a git repo ---
if [ ! -d ".git" ]; then
  echo "❌ Error: This is not a Git repository."
  exit 1
fi

# --- Step 2: Remove pre-commit hook ---
if [ -f "$HOOK_FILE" ]; then
  rm -f "$HOOK_FILE"
  echo "✅ Pre-commit hook removed."
else
  echo "ℹ️ No pre-commit hook found to remove."
fi

# --- Step 3: Ask about cleaning .gitattributes ---
if [ -f ".gitattributes" ]; then
  echo "⚠️ A .gitattributes file exists. It may contain Git LFS rules."
  read -p "Do you want to remove Git LFS tracking entries from .gitattributes? (y/N): " choice
  case "$choice" in
    y|Y )
      # Keep only non-lfs lines
      grep -v "filter=lfs" .gitattributes > .gitattributes.tmp || true
      mv .gitattributes.tmp .gitattributes
      git add .gitattributes
      echo "✅ Removed Git LFS rules from .gitattributes (staged for commit)."
      ;;
    * )
      echo "ℹ️ Keeping .gitattributes unchanged."
      ;;
  esac
fi

echo "🎉 Hook uninstallation complete."
