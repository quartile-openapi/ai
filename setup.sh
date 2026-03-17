#!/bin/bash
#
# setup.sh — Bootstrap quartile-dev-toolkit (Linux/macOS)
#
# Prerequisites:
#   Set UV_EXTRA_INDEX_URL before running (see README.md for PAT + URL instructions).
#
# Steps:
#   1. Validates UV_EXTRA_INDEX_URL is set
#   2. Checks for Node.js (npx); installs via brew (macOS) or apt (Debian-based Linux) if missing
#   3. Installs UV if not present (user-level, no admin/sudo required)
#   4. Installs qtk CLI from Azure Artifacts feed
#
# Usage:
#   # Recommended: set UV_EXTRA_INDEX_URL first, then run:
#   ./setup.sh
#
#   # Or pass the URL directly:
#   ./setup.sh "https://quartiledigital:<PAT>@pkgs.dev.azure.com/quartiledigital/QD_AI/_packaging/ai-prod/pypi/simple/"

set -e

FEED_URL="${1:-}"

echo ""
echo "=== Quartile Dev Toolkit - Setup ==="
echo ""

# ── Step 1: UV_EXTRA_INDEX_URL ───────────────────────────────────────────
echo "[1/4] Checking UV_EXTRA_INDEX_URL..."

if [ -n "$FEED_URL" ]; then
    export UV_EXTRA_INDEX_URL="$FEED_URL"

    # Persist to shell profile
    SHELL_NAME="$(basename "$SHELL")"
    case "$SHELL_NAME" in
        zsh)  PROFILE="$HOME/.zshrc" ;;
        bash) PROFILE="$HOME/.bashrc" ;;
        fish) PROFILE="$HOME/.config/fish/config.fish" ;;
        *)    PROFILE="$HOME/.profile" ;;
    esac

    if grep -q 'UV_EXTRA_INDEX_URL' "$PROFILE" 2>/dev/null; then
        echo "    Already in $PROFILE"
    else
        echo "" >> "$PROFILE"
        if [ "$SHELL_NAME" = "fish" ]; then
            echo "set -gx UV_EXTRA_INDEX_URL \"$FEED_URL\"" >> "$PROFILE"
        else
            echo "export UV_EXTRA_INDEX_URL=\"$FEED_URL\"" >> "$PROFILE"
        fi
        echo "    Persisted to $PROFILE"
    fi
elif [ -n "$UV_EXTRA_INDEX_URL" ]; then
    echo "    Found in current session"
else
    echo "    ERROR: UV_EXTRA_INDEX_URL is not set."
    echo ""
    echo "    Set it before running this script (see README.md for PAT instructions):"
    echo '    export UV_EXTRA_INDEX_URL="<FEED_URL>"'
    echo ""
    echo "    Or pass it directly:"
    echo '    ./setup.sh "<FEED_URL>"'
    exit 1
fi

# ── Step 2: Node.js (npx) ──────────────────────────────────────────────────
echo ""
echo "[2/4] Checking Node.js (npx)..."

if command -v npx &>/dev/null; then
    echo "    Found: npx $(npx --version)"
else
    echo "    Not found. Attempting to install Node.js..."
    NODE_OK=0
    case "$(uname -s)" in
        Darwin)
            if command -v brew &>/dev/null; then
                if (brew install node 2>/dev/null); then
                    export PATH="$(brew --prefix)/bin:$PATH"
                    command -v npx &>/dev/null && NODE_OK=1
                fi
            fi
            if [ "$NODE_OK" -eq 0 ]; then
                echo "    ERROR: macOS requires Homebrew (brew install node). Install from https://nodejs.org/ if needed."
            fi
            ;;
        Linux)
            if [ -f /etc/debian_version ] && command -v apt-get &>/dev/null; then
                if (sudo apt-get update -qq 2>/dev/null && sudo apt-get install -y nodejs npm 2>/dev/null); then
                    command -v npx &>/dev/null && NODE_OK=1
                fi
            fi
            if [ "$NODE_OK" -eq 0 ]; then
                echo "    ERROR: Only Debian-based Linux is supported for auto-install. Install Node.js LTS from https://nodejs.org/"
            fi
            ;;
        *)
            echo "    ERROR: Unsupported platform for Node.js auto-install. Install Node.js LTS from https://nodejs.org/"
            ;;
    esac
    if [ "$NODE_OK" -eq 1 ]; then
        echo "    Installed: npx $(npx --version)"
    fi
fi

# ── Step 3: UV ───────────────────────────────────────────────────────────
echo ""
echo "[3/4] Checking UV..."

if command -v uv &>/dev/null; then
    echo "    Found: $(uv --version)"
else
    echo "    Installing UV (user-level, no sudo required)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Source env files UV may have created
    [ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"
    [ -f "$HOME/.cargo/env" ]     && source "$HOME/.cargo/env"
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v uv &>/dev/null; then
        echo "    UV installed but not in PATH. Restart terminal and re-run."
        exit 1
    fi
    echo "    Installed: $(uv --version)"
fi

# ── Step 4: CLI ──────────────────────────────────────────────────────────
echo ""
echo "[4/4] Installing qtk CLI..."

uv tool install quartile-dev-toolkit --force 2>&1 || true

if command -v qtk &>/dev/null; then
    echo "    OK: $(qtk --version)"
else
    echo "    CLI installed (restart shell if 'qtk' not found)"
fi

# ── Done ─────────────────────────────────────────────────────────────────
echo ""
echo "=== Setup complete! ==="
echo ""
echo "    Next steps:"
echo "      qtk install --level global              Install skills/agents/hooks globally"
echo "      qtk install --level project -p NAME     Install for a specific project"
echo "      qtk doctor                              Verify configuration"
echo ""
echo "    Other commands:"
echo "      qtk sync       Upgrade to latest version"
echo "      qtk list       Show installed components"
echo "      qtk remove     Remove installed components"
echo ""
