# Setup Scripts

Bootstrap scripts that install the `qtk` CLI from the Azure Artifacts feed.

| File | Platform |
|------|----------|
| `setup.ps1` | Windows (PowerShell 5.1+) |
| `setup.bat` | Windows (double-click launcher for `setup.ps1`) |
| `setup.sh` | Linux / macOS |

## Prerequisites

Install these tools before running the setup script.

### Windows: Chocolatey

Node.js installation on Windows uses Chocolatey. If you don't have it yet:

```powershell
powershell -c "irm https://community.chocolatey.org/install.ps1 | iex"
```

### uv

**Windows:**
```powershell
irm https://astral.sh/uv/install.ps1 | iex
```

**macOS / Linux:**
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Alternatively: `winget install astral-sh.uv` · `choco install astral-uv` · `brew install uv`

### Node.js

Required for MCP servers that use `npx`.

**Windows:**
```powershell
choco install nodejs-lts
```

**macOS:**
```bash
brew install node
```

**Linux (Debian/Ubuntu):**
```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

Or download the installer from [nodejs.org](https://nodejs.org/) (LTS recommended).

Verify both are installed:
```bash
uv --version
npx --version
```

## Usage

The script requires `UV_EXTRA_INDEX_URL` to be set beforehand. See the [main README](https://github.com/quartile-openapi/ai#installation) for PAT generation and environment variable setup.

```powershell
# Windows (PowerShell)
irm https://raw.githubusercontent.com/quartile-openapi/ai/main/setup.ps1 | iex

# Linux/macOS
curl -sSf https://raw.githubusercontent.com/quartile-openapi/ai/main/setup.sh | bash
```

You can also pass the feed URL directly:

```powershell
# Windows
powershell -ExecutionPolicy ByPass -c "irm https://raw.githubusercontent.com/quartile-openapi/ai/main/setup.ps1 | iex" -FeedUrl "<FEED_URL>"

# Linux/macOS
curl -sSf https://raw.githubusercontent.com/quartile-openapi/ai/main/setup.sh | bash -s "<FEED_URL>"
```

## What the script does

1. Validates `UV_EXTRA_INDEX_URL` is set (or accepts it as an argument)
2. Checks that Node.js (`npx`) is installed
3. Checks that `uv` is installed
4. Installs the `qtk` CLI via `uv tool install quartile-dev-toolkit`

After setup, use `qtk` to install skills, agents, and hooks:

```bash
qtk install --level global
qtk doctor
```
