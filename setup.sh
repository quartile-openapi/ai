#!/bin/bash
#
# setup.sh — Bootstrap quartile-dev-toolkit (Linux/macOS)
#
# Prerequisites (must be installed before running this script):
#   - Node.js (npx)
#   - uv
#   See docs/prerequisites.md for installation instructions.
#
# Steps:
#   1. Validates UV_EXTRA_INDEX_URL is set
#   2. Checks that Node.js (npx) is installed
#   3. Checks that uv is installed
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
    echo "    ERROR: Node.js (npx) is not installed."
    echo ""
    echo "    Install from https://nodejs.org/ (LTS recommended)"
    echo "    or: brew install node  (macOS)"
    echo "    or: sudo apt-get install -y nodejs  (Debian/Ubuntu)"
    exit 1
fi

# ── Step 3: UV ───────────────────────────────────────────────────────────
echo ""
echo "[3/4] Checking UV..."

if command -v uv &>/dev/null; then
    echo "    Found: $(uv --version)"
else
    echo "    ERROR: uv is not installed."
    echo ""
    echo "    Install with:"
    echo "    curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

# ── Step 4: CLI ──────────────────────────────────────────────────────────
echo ""
echo "[4/4] Installing qtk CLI..."

uv tool install quartile-dev-toolkit --force 2>&1 | sed 's/^/    /'
uv_exit=${PIPESTATUS[0]}

qtk_found=false
if [ "$uv_exit" -ne 0 ]; then
    echo ""
    echo "    ERROR: uv tool install failed (exit code $uv_exit)."
    echo "    Check the output above for details."
else
    # Discover uv tool bin dir and ensure it's in session PATH
    UV_BIN_DIR="$(uv tool dir --bin 2>/dev/null || echo "$HOME/.local/bin")"
    export PATH="$UV_BIN_DIR:$HOME/.local/bin:$PATH"
    [ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"

    if command -v qtk &>/dev/null; then
        echo "    OK: $(qtk --version)"
        qtk_found=true
    else
        echo ""
        echo "    WARN: qtk was installed but is not yet available in this session."
        echo ""
        echo "    The binary was placed in: $UV_BIN_DIR"
        echo ""
        echo "    To fix, do ONE of the following:"
        echo "      1. Close and reopen your terminal"
        echo "      2. Run:  export PATH=\"$UV_BIN_DIR:\$PATH\""
        echo ""
        echo "    To verify:  qtk --version"
        echo "    Or run directly:  uv tool run --from quartile-dev-toolkit qtk --version"
    fi
fi

# ── Done ─────────────────────────────────────────────────────────────────
echo ""
if [ "$qtk_found" = true ]; then
    echo "=== Setup complete! ==="
    echo ""
    echo "    Next steps:"
    echo "      qtk install project --level global              Install all projects globally"
    echo "      qtk install project --level project -p NAME     Install one project in this directory"
    echo "      qtk doctor                                      Verify configuration"
    echo ""
    echo "    Other commands:"
    echo "      qtk sync              Upgrade to latest version"
    echo "      qtk list project      Show projects and installation status"
    echo "      qtk install mcp       Add MCP servers (interactive)"
    echo "      qtk remove project    Remove installed project components"
    echo ""
fi
