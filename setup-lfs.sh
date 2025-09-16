#!/bin/bash
set -e

# --- Step 1: Check if Git is installed ---
if ! command -v git >/dev/null 2>&1; then
  echo "❌ Error: Git is not installed on this system."
  exit 1
fi

# --- Step 2: Check if Git LFS is installed ---
if ! command -v git-lfs >/dev/null 2>&1; then
  echo "❌ Git LFS is not installed."

  # Try auto-install if apt is available (Linux)
  if command -v apt >/dev/null 2>&1; then
    echo "👉 Installing Git LFS via apt..."
    sudo apt update && sudo apt install git-lfs -y
    echo "🔧 Running git lfs install..."
    git lfs install --system
    echo "✅ Git LFS installed successfully."
  else
    echo "👉 Please install Git LFS manually:"
    echo "   - Linux: https://git-lfs.com"
    echo "   - macOS: brew install git-lfs"
    echo "   - Windows: Download installer from https://git-lfs.com/"
    exit 1
  fi
fi

echo "✅ Git LFS is installed."

# --- Step 3: Ensure this is a Git repo ---
if [ ! -d ".git" ]; then
  echo "❌ Error: This is not a Git repository."
  exit 1
fi

# --- Step 4: Initialize Git LFS locally ---
if ! git lfs env >/dev/null 2>&1; then
  echo "🔧 Initializing Git LFS in this repo..."
  git lfs install --local
else
  echo "✅ Git LFS already initialized for this repo."
fi

# --- Step 5: Setup pre-commit hook ---
HOOK_FILE=".git/hooks/pre-commit"

cat > "$HOOK_FILE" <<'EOF'
#!/bin/bash
threshold=$((100*1024*1024)) # 100MB threshold

for file in $(git diff --cached --name-only); do
  if [ -f "$file" ]; then
    size=$(wc -c <"$file")
    if [ "$size" -gt $threshold ]; then
      echo "⚠️ File $file is larger than 100MB. Moving to Git LFS..."

      # Track in LFS
      git lfs track "$file"

      # Stage updated .gitattributes
      git add .gitattributes

      # Re-stage file as LFS pointer
      git rm --cached "$file"
      git add "$file"
    fi
  fi
done
EOF

chmod +x "$HOOK_FILE"

echo "✅ Pre-commit hook installed successfully."
echo "🎉 Setup complete! Large files will now be auto-tagged with Git LFS."
