{ username }:
{ pkgs, config, lib, ... }: {

  # --- Home Manager Configuration ---
  home = {
    stateVersion = "24.11";
    username = username;
    homeDirectory = if pkgs.stdenv.isDarwin then
      "/Users/${username}"
    else
      "/home/${username}";
      
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
    ] ++ (if pkgs.stdenv.isLinux then [
      # Linux pkgs
      # USE FLATPAK ON LINUX!!!!!!
    ] else [
      # GUI Apps
      librewolf
      vscodium
      audacity
      ungoogled-chromium
      qbittorrent
      telegram-desktop
      # MacOS specific
      libreoffice-bin
      whisky
      lunarfyi
      iina
      utm
      kap-bin
    ]);

    # --- Dotfiles Management ---
    file = {
      ".nanorc".text = ''
        include ${pkgs.nanorc}/share/*.nanorc
      '';

      ".bash_sessions_disable".text = ''
      '';
    };
  };

  # Global Font Config
  fonts.fontconfig.enable = true;

  # --- Programs Configuration ---
  programs = {
    direnv = {
      enable = true;
      enableFishIntegration = false;
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
          signingkey = "~/.ssh/id_rsa.pub";
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
        # --- Completion & History ---
        zstyle ':completion:*' menu select
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        
        HISTFILE="$HOME/.zsh_history"
        HISTSIZE=50000                  # Lines in memory
        SAVEHIST=10000                  # Lines in the file

        export LESSHISTFILE=-

        setopt AUTO_CD                  # Type 'src' instead of 'cd src'
        setopt AUTO_PUSHD               # cd automatically pushes old dir to stack
        setopt PUSHD_IGNORE_DUPS        # Don't push duplicate directories to stack
        setopt interactivecomments      # Allow comments starting with # in interactive shell
        setopt HIST_IGNORE_SPACE        # Don't save commands starting with a space
        setopt HIST_IGNORE_ALL_DUPS     # Remove older duplicate entries from history
        setopt INC_APPEND_HISTORY       # Write to history file immediately, not when shell exits
        setopt HIST_VERIFY              # Don't execute immediate upon history expansion (allows editing) 
        setopt EXTENDED_GLOB            # Enable extended globbing

        HISTORY_IGNORE='(less *|ls *|ll|la|which *|git *|echo *|cd|cd *|clear|codium *|open *|cat *|eza *|exit|history)'

        # --- Powerlevel10k ---
        if [[ $TERM = "xterm-256color" ]]; then
            source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
            source ~/.p10k.zsh
        fi

        # --- Custom Functions ---
        ns() { 
          pkgs=() 
          for x in "$@"; do pkgs+=("nixpkgs#$x"); done
          nix shell "''${pkgs[@]}" 
        }

        fix-quarantine() {
          sudo xattr -rd com.apple.quarantine "$1"
        }

        # --- Welcome Banner ---
        ${pkgs.fortune-kind}/bin/fortune-kind | ${pkgs.cowsay}/bin/cowsay -f koala
      '';

      shellAliases = {
        cat = "${pkgs.bat}/bin/bat --paging=never";
        less = "${pkgs.bat}/bin/bat";
        ls = "${pkgs.eza}/bin/eza -l --no-permissions --no-time --no-user -o -X -h --group-directories-first -F";
        gc = "sudo nix-collect-garbage -d";
        fix-rsa = "chmod 600 ~/.ssh/id_rsa";
        fix-launchpad = "sudo find 2>/dev/null /private/var/folders/ -type d -name com.apple.dock.launchpad -exec rm -rf {} +; killall Dock";
        fix-dock-size = "defaults delete com.apple.dock tilesize; killall Dock";
        fix-ds_store = "chflags nouchg .DS_Store; rm -rf .DS_Store; pkill Finder; touch .DS_Store; chflags uchg .DS_Store";
      };
    };
  };

  # --- MacOS (Darwin) Specific Settings ---
  targets.darwin.defaults = {
    NSGlobalDomain = { 
      _NS_4445425547 = true; # Enable Debug Menu
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
      _FXSortFoldersFirst = true;
      FXPreferredViewStyle = "Nlsv"; # List view
      AppleShowAllFiles = true;
      QuitMenuItem = true;
      FXEnableExtensionChangeWarning = false;
      ShowPathbar = true;
    };
    "com.apple.controlcenter.plist" = { BatteryShowPercentage = true; };
  }; 

  # --- Linux (GNOME) Specific Settings ---
  dconf.settings = if pkgs.stdenv.isLinux then {
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
