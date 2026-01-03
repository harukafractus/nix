{ username }:
{ pkgs, config, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  homeDirectory =     # Explicit home directory logic
      if isDarwin then "/Users/${username}"
      else if isLinux then "/home/${username}"
      else builtins.throw "wtf is this system";
in {
  # --- Home Manager Configuration ---
  home = {
    stateVersion = "24.11";
    username = username;
    inherit homeDirectory;

    sessionVariables = {
      PYTHONDONTWRITEBYTECODE = 1;
      PYTHON_HISTORY = "/dev/null";
    };

    # --- Packages ---
    packages = with pkgs; [
      # Fonts
      noto-fonts
      source-han-sans
      source-han-mono
      source-han-serif
      source-han-code-jp
      meslo-lgs-nf

      # CLI Utilities
      fortune-kind
      cowsay
      eza
      bat
      imagemagick
      python315FreeThreading
      uv
      htop
      wget
      unar
      ffmpeg
      asciinema
      asciinema-agg
    ] ++ (
      if isLinux then with pkgs; [
        # Linux GUI apps: ALWAYS USE FLATPAK!!!!!!
        hello   # hello from the other side
                # I must've called a thousand times
      ] 
      else if isDarwin then with pkgs; [
        # GUI Apps
        librewolf
        vscodium
        audacity
        ungoogled-chromium
        qbittorrent
        telegram-desktop
        # MacOS specific utilities
        libreoffice-bin
        whisky
        lunarfyi
        iina
        utm
        kap-bin
      ] 
      else []
    );

    # --- Dotfiles Management ---
    file = {
      ".nanorc".text = ''
        include ${pkgs.nanorc}/share/*.nanorc
      '';

      ".bash_sessions_disable".text = '''';
    };
  };

  # Global Font Config
  fonts.fontconfig.enable = true;

  # --- Programs Configuration ---
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    git = {
      enable = true;
      ignores = [
        "*.DS_Store"
        "*__pycache__/"
      ];
      settings = {
        init = { defaultBranch = "main"; };
        user = {
          email = "106440141+fractuscontext@users.noreply.github.com";
          name = "fractuscontext";
          signingkey = "${homeDirectory}/.ssh/id_rsa.pub";
        };
        gpg = { format = "ssh"; };
        commit = { gpgSign = true; };
      };
    };

    bash = {
      enable = true;
      bashrcExtra = ''
        unset HISTFILE
      '';
    };

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      initContent = ''
        # --- Completion & Colors ---
        zstyle ':completion:*' menu select
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        
        # --- History Config ---
        HISTFILE="$HOME/.zsh_history"
        HISTSIZE=50000
        SAVEHIST=10000
        export LESSHISTFILE=-

        setopt AUTO_CD                  # Type 'src' instead of 'cd src'
        setopt AUTO_PUSHD               # cd automatically pushes old dir to stack
        setopt PUSHD_IGNORE_DUPS        # Don't push duplicate directories to stack
        setopt INTERACTIVE_COMMENTS     # Allow comments starting with #
        setopt HIST_IGNORE_SPACE        # Don't save commands starting with a space
        setopt HIST_IGNORE_ALL_DUPS     # Remove older duplicate entries
        setopt INC_APPEND_HISTORY       # Write to history file immediately
        setopt HIST_VERIFY              # Don't execute immediate upon history expansion
        setopt EXTENDED_GLOB            # Required for complex HISTORY_IGNORE patterns

        # --- Smart History Filtering ---
        zshaddhistory() {
          local line="''${1%%$'\n'}"
          local cmd="''${''${(z)line}[1]}"

          # --- 1. Always save lines with pipes (|) or redirects (> <) ---
          if [[ "$line" == *['|<>']* ]]; then
            return 0
          fi

          # --- 2. Filter Noisy Commands without pipes/redirects ---
          case "$line" in
            # > Navigation & Listing
            ls|ls\ *|ll|la|exa\ *|eza\ *|tree\ *)               return 1 ;;
            cd|cd\ *|pwd|popd|popd\ *|pushd|pushd\ *|dirs)      return 1 ;;

            # > Session & Process Management    
            clear|exit|history|date|jobs|fg|bg)                 return 1 ;;
            htop|htop\ *)                                       return 1 ;;

            # > Help & Lookups
            man\ *|which\ *|file\ *|open\ *|codium\ *)          return 1 ;;
            ping\ *|dig\ *|nslookup\ *)                         return 1 ;;
            
            # > File Reading (bat/cat/less)
            # (Note: These are only ignored if NOT piped/redirected)
            echo\ *|cat\ *|less\ *|bat\ *)                      return 1 ;;

            # > Environment Noise
            source\ .venv*|source\ venv*|conda\ activate\ *)    return 1 ;;
            
            # > Git Status/Navigation (Read-only operations)
            git\ status|git\ status\ *|git\ add\ *|git\ diff\ *)          return 1 ;;
            git\ log\ *|git\ show\ *|git\ branch\ *)                      return 1 ;;
            git\ switch\ *|git\ checkout\ *|git\ fetch\ *|git\ pull\ *)   return 1 ;;
            git\ push\ *|git\ stash\ *|git\ restore\ *)                   return 1 ;;
          esac

          # --- 3. Prevent "Command Not Found" (err 127) from being saved ---
          whence "$cmd" > /dev/null || return 1
          return 0
        }

        # --- Powerlevel10k ---
        if [[ $TERM = "xterm-256color" ]]; then
            source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
            [[ -f ${homeDirectory}/.p10k.zsh ]] && source ${homeDirectory}/.p10k.zsh
        fi

        # --- Custom Functions ---
        ns() { 
          local pkg_args=() 
          for x in "$@"; do pkg_args+=("nixpkgs#$x"); done
          nix shell "''${pkg_args[@]}" 
        }

        fix-quarantine() {
          sudo xattr -rd com.apple.quarantine "$1"
        }

        # --- Prettier ls ---
        ls() {
          if [[ $# -eq 0 ]]; then
            # No arguments? Use the clean, octal, minimal view
            ${pkgs.eza}/bin/eza \
              --long \
              --octal-permissions \
              --no-permissions \
              --no-time \
              --no-user \
              --dereference \
              --icons=auto \
              --group-directories-first
          else
            # Arguments provided (e.g., ls -al)? Use standard eza behavior
            ${pkgs.eza}/bin/eza --group-directories-first "$@"
          fi
        }

        # --- Welcome Banner ---
        ${pkgs.fortune-kind}/bin/fortune-kind | ${pkgs.cowsay}/bin/cowsay -f koala
      '';

      shellAliases = {
        # --- Modern Replacements ---
        # -pp: Plain (no line numbers/grid), behaves like real cat for copy-paste
        cat = "${pkgs.bat}/bin/bat -pp";
        less = "${pkgs.bat}/bin/bat";

        # --- Safety & QoL ---
        mkdir = "mkdir -p";       # Auto-create parent directories
        rm = "rm -i";             # Ask before deleting
        mv = "mv -i";             # Ask before overwriting
        cp = "cp -i";             # Ask before overwriting

        # --- Nix ---
        gc = "sudo nix-collect-garbage -d"; 
        
        # --- macOS ---
        fix-rsa = "chmod 600 ${homeDirectory}/.ssh/id_rsa";
        fix-launchpad = "sudo find 2>/dev/null /private/var/folders/ -type d -name com.apple.dock.launchpad -exec rm -rf {} +; killall Dock";
        fix-dock-size = "defaults delete com.apple.dock tilesize; killall Dock";
        fix-ds_store = "chflags nouchg .DS_Store; rm -rf .DS_Store; pkill Finder; touch .DS_Store; chflags uchg .DS_Store";
      };
    };
  };

  # --- MacOS (Darwin) Specific Settings ---
  targets = if isDarwin then {
    darwin.defaults = {
      NSGlobalDomain = { 
        _NS_4445425547 = true;
        AppleShowAllExtensions = true; 
        "com.apple.mouse.tapBehavior" = 1; 
        AppleICUForce24HourTime = 1;
      };
      "com.apple.AppleMultitouchTrackpad" = {
        ActuationStrength = 0;
        Clicking = 1;
       };
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.finder" = {
        _FXSortFoldersFirst = true;               # Folders before files
        FXPreferredViewStyle = "Nlsv";            # List view by default
        AppleShowAllFiles = true;                 # Show hidden files
        QuitMenuItem = true;                      # Allow quitting Finder (Cmd+Q)
        FXEnableExtensionChangeWarning = false;   # Don't warn about changing extensions
        ShowPathbar = true;                       # Show path at bottom
      };
      "com.apple.controlcenter.plist" = { BatteryShowPercentage = true; };
    };
  } else {};

  # --- Linux (GNOME) Specific Settings ---
  dconf.settings = if isLinux then {
    "org/gnome/desktop/peripherals/touchpad" = {
      "natural-scroll" = false;
      "tap-to-click" = true;
    };
    "org/gnome/desktop/interface" = {
      enable-hot-corners = false;
      show-battery-percentage = true;
    };
    "org/gnome/nautilus/preferences" = { default-folder-viewer = "list-view"; };
    "org/gnome/nautilus/list-view" = { default-zoom-level = "small"; };
    "org/gnome/settings-daemon/peripherals/touchscreen" = { orientation-lock = true; };
    "org/gnome/desktop/datetime" = { automatic-timezone = true; };
    "org/gnome/system/location" = { enabled = true; };
    "org/gnome/mutter" = {
      edge-tiling = true;
      experimental-features = [ "scale-monitor-framebuffer" ];
    };
    "org/gnome/desktop/app-folders" = {
      folder-children = [ "LibreOffice" "Utilities" ];
    };
    "org/gnome/desktop/app-folders/folders/LibreOffice" = {
      name = "LibreOffice";
      apps = [
        "org.libreoffice.LibreOffice.desktop"
        "org.libreoffice.LibreOffice.base.desktop"
        "org.libreoffice.LibreOffice.calc.desktop"
        "org.libreoffice.LibreOffice.draw.desktop"
        "org.libreoffice.LibreOffice.impress.desktop"
        "startcenter.desktop"
        "org.libreoffice.LibreOffice.math.desktop"
        "org.libreoffice.LibreOffice.writer.desktop"
        "math.desktop"
        "writer.desktop"
        "impress.desktop"
        "draw.desktop"
        "calc.desktop"
        "base.desktop"
      ];
    };
    "org/gnome/shell" = { app-picker-layout = [ ]; };
  } else {};
}
