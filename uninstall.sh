#!/bin/bash
#
# uninstall.sh — Uninstall quartile-dev-toolkit (Linux/macOS)
#
# Steps:
#   0. (Optional) Remove globally installed components
#   1. Uninstalls qtk CLI via uv tool uninstall
#   2. Removes UV_EXTRA_INDEX_URL from shell profile
#
# Usage:
#   ./uninstall.sh

set -e

echo ""
echo "=== Quartile Dev Toolkit - Uninstall ==="
echo ""

# ── Confirmation ─────────────────────────────────────────────────────
read -r -p "This will uninstall quartile-dev-toolkit. Continue? (y/N) " confirm
case "$confirm" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Aborted."; exit 0 ;;
esac

# ── Optional: Clean up global components ─────────────────────────────
echo ""
read -r -p "Remove globally installed components (~/.claude/skills, agents, hooks, settings, MCPs)? (y/N) " cleanup
case "$cleanup" in
    [yY]|[yY][eE][sS])
        echo ""
        echo "Removing global components..."

        # Try via qtk CLI first
        if command -v qtk &>/dev/null; then
            qtk remove project --level global --yes 2>/dev/null | sed 's/^/    /' || true
        fi

        # Direct cleanup for anything remaining
        for sub in skills agents hooks; do
            dir="$HOME/.claude/$sub"
            if [ -d "$dir" ]; then
                rm -rf "$dir"
                echo "    Removed $dir"
            else
                echo "    $sub: not found (clean)"
            fi
        done

        # settings.json
        settings="$HOME/.claude/settings.json"
        if [ -f "$settings" ]; then
            rm -f "$settings"
            echo "    Removed settings.json"
        else
            echo "    settings.json: not found (clean)"
        fi

        # MCP configs: remove mcpServers key only, preserve other config
        for mcp_file in "$HOME/.claude.json" "$HOME/.cursor/mcp.json"; do
            if [ -f "$mcp_file" ]; then
                if command -v python3 &>/dev/null; then
                    python3 -c "
import json
p = '$mcp_file'
with open(p) as f:
    d = json.load(f)
if 'mcpServers' in d:
    del d['mcpServers']
    with open(p, 'w') as f:
        json.dump(d, f, indent=2)
        f.write('\n')
    print(f'    Removed mcpServers from {p}')
else:
    print(f'    {p}: no mcpServers (clean)')
"
                else
                    echo "    WARN: Cannot clean $mcp_file (python3 not available)"
                fi
            else
                echo "    $mcp_file: not found (clean)"
            fi
        done
        ;;
    *)
        echo "    Skipped."
        ;;
esac

# ── Step 1: Uninstall CLI ────────────────────────────────────────────
echo ""
echo "[1/2] Uninstalling qtk CLI..."

if command -v uv &>/dev/null; then
    if uv tool uninstall quartile-dev-toolkit 2>&1 | sed 's/^/    /'; then
        echo "    OK: qtk CLI removed"
    else
        echo "    Not installed or already removed"
    fi
else
    echo "    WARN: uv not found. Cannot uninstall via uv tool."
    echo "    If qtk was installed, it may need manual removal."
fi

# ── Step 2: Remove UV_EXTRA_INDEX_URL from shell profile ─────────────
echo ""
echo "[2/2] Removing UV_EXTRA_INDEX_URL from shell profile..."

SHELL_NAME="$(basename "$SHELL")"
case "$SHELL_NAME" in
    zsh)  PROFILE="$HOME/.zshrc" ;;
    bash) PROFILE="$HOME/.bashrc" ;;
    fish) PROFILE="$HOME/.config/fish/config.fish" ;;
    *)    PROFILE="$HOME/.profile" ;;
esac

if [ -f "$PROFILE" ] && grep -q 'UV_EXTRA_INDEX_URL' "$PROFILE"; then
    if [ "$SHELL_NAME" = "fish" ]; then
        sed -i.bak '/set -gx UV_EXTRA_INDEX_URL/d' "$PROFILE"
    else
        sed -i.bak '/export UV_EXTRA_INDEX_URL/d' "$PROFILE"
    fi
    rm -f "${PROFILE}.bak"
    echo "    Removed from $PROFILE"
else
    echo "    Not found in $PROFILE (already clean)"
fi

# Clear from current session
unset UV_EXTRA_INDEX_URL

# ── Done ─────────────────────────────────────────────────────────────
echo ""
echo "=== Uninstall complete! ==="
echo ""
echo "    Restart your terminal for changes to take effect."
echo ""
