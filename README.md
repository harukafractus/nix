# ❄️ nix-dotfiles / fractuscontext

A single-user `nix-darwin` + `home-manager` flake for my NixOS/nix-darwin setup.

## Structure

```
.
├── flake.nix              # Main flake (inputs + darwin config)
├── rebuild-darwin.sh      # Auto-bootstrap & rebuild script
└── configs/
    ├── darwin.nix         # System-level macOS config
    └── home.nix           # Home Manager (packages, dotfiles, programs)
```

## 🛠️ Usage

### Install Nix (if not installed) or Apply Configuration
```sh
./rebuild-darwin.sh # uses Determinate Systems installer btw
```
*Automatically detects hostname (`$HOST` or `apple-seeds`) and builds the flake.*

Targets `.#apple-seeds` by default. Override with `export HOST=other-machine` before running.

## What
### System (darwin.nix)
- **System Tweaks**:
  - Blocks Apple OCSP (telemetry).
  - Enables Terminal Developer Mode.
  - Mutes startup chime.

### Home (home.nix)
- **Mac App Util**: Properly links GUI apps to `/Applications/Nix Apps`.
- **Packages**: LibreWolf, VSCodium, Ungoogled Chromium, Whisky, UTM, etc.
- **Git**: SSH signing, main as default branch
- **macOS defaults**: Finder list view, show hidden files, tap-to-click, battery %
- **Zsh Config**: Powerlevel10k, syntax highlighting, and custom aliases.

## NUR Overlay

Uses [`fractuscontext/nix-nur`](https://github.com/fractuscontext/nix-nur) for custom macOS app packages (auto-updated DMGs).

**License:** MIT, i mean, who cares 