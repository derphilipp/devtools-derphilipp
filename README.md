# devtools-derphilipp

> An opinionated selection of developer & debugging tools, packaged as a `.deb` — easy to install "just like that".

## Quick Install

Paste this into your terminal to download and install the latest release in one step:

```bash
curl -sL "$(curl -s https://api.github.com/repos/derphilipp/devtools-derphilipp/releases/latest \
  | grep -oP '"browser_download_url":\s*"\K[^"]+\.deb')" -o /tmp/devtools-derphilipp.deb \
  && sudo apt install -y /tmp/devtools-derphilipp.deb
```

Then open a new shell (or run `source ~/.bashrc`) and verify with `mise list`.

## What gets installed?

The package installs [mise](https://mise.jdx.dev/) (a polyglot tool manager) and automatically configures the following tools:

| Tool | Description |
|------|-------------|
| **ripgrep** (`rg`) | Blazing fast grep |
| **fzf** | Fuzzy finder for shell history, files, etc. |
| **jq** | CLI JSON processor |
| **fd** | Fast alternative to `find` |
| **bat** | `cat` with syntax highlighting |
| **delta** | Better diff / git-diff viewer |
| **lazygit** | Terminal UI for Git |
| **btop** | Modern system monitor |
| **watchexec** | File watcher, runs commands on changes |
| **zellij** | Terminal multiplexer with tiling |
| **helix** | Modern terminal editor focused on speed |
| **croc** | Simple tool for sending files across the network |

## Project structure

```
devtools-deb/
├── nfpm.yaml              # nfpm package configuration
├── mise.toml              # Tool configuration (shipped to target machine)
├── build.sh               # Local build script
├── scripts/
│   ├── postinstall.sh     # Runs after installation / upgrade
│   └── preremove.sh       # Runs before uninstallation
├── .github/workflows/
│   └── build.yml          # GitHub Actions: auto-build on push
└── README.md              # This file
```

## Prerequisites (build machine)

- **nfpm** installed (to build the `.deb`):
  ```bash
  # Via mise (recommended if you already have mise locally):
  mise use -g nfpm

  # Or via Go:
  go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest

  # Or via script:
  curl -sfL https://install.goreleaser.com/github.com/goreleaser/nfpm.sh | sh
  ```

## Building locally

```bash
# Default build (version 1.0.0):
./build.sh

# With a custom version:
./build.sh 1.2.0
```

Produces: `devtools-derphilipp_1.0.0_all.deb`

## Automated builds (GitHub Actions)

Every push to `main` automatically:
1. Determines the next patch version from the latest git tag
2. Builds the `.deb` package
3. Creates a GitHub Release with the `.deb` attached
4. Tags the commit with the new version

To bump the **minor** or **major** version, create a tag manually:
```bash
git tag v2.0.0
git push --tags
```
The next automatic build will increment from there.

## Installation on target machine

```bash
# 1. Copy .deb to the target:
scp devtools-derphilipp_*.deb user@<host>:~/

# 2. Install:
ssh user@<host>
sudo apt install -y ./devtools-derphilipp_*.deb

# 3. Open a new shell (or source):
source ~/.bashrc

# 4. Verify:
mise list
```

## Upgrades

Installing a newer version of the package will:
- Back up the existing `~/.config/mise/config.toml` (as `.bak.<timestamp>`)
- Overwrite it with the new tool list from the package
- Run `mise install` to install any new or updated tools
- Skip mise installation if it is already present
- Skip `.bashrc` modification if the activation block already exists

## User detection

The package automatically detects the target user:

1. **`SUDO_USER`** — automatically set when installed via `sudo apt install`
2. **Fallback** — first user with UID ≥ 1000 (typically `pi` on Raspberry Pi)
3. **Manual** — if no user is found, the script prints instructions for manual setup

## Customizing tools

The tool list lives in `mise.toml`. Edit before building:

```toml
[tools]
# Add a tool:
golang = "1.22"

# Remove a tool: just delete the line
```

After installation, users can also add tools themselves:

```bash
# Add a single tool:
mise use node@20

# Or edit ~/.config/mise/config.toml directly, then:
mise install
```

## Uninstallation

```bash
sudo apt remove devtools-derphilipp
```

> **Note:** Uninstallation removes the mise entry from `.bashrc` but does **not** remove mise itself or the installed tools. To fully remove everything:
> ```bash
> rm -rf ~/.local/share/mise ~/.local/bin/mise ~/.config/mise
> ```

## Architecture

- Target: **all** (architecture-independent — works on arm64, armhf, x86_64)
- mise detects the target architecture automatically and downloads matching binaries
