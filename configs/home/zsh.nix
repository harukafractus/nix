{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin isLinux;
  homeDirectory = config.home.homeDirectory;

  myWebDavServerFunction = ''
    function webdav() {
      local PORT="''${1:-8081}"
      local TMP_DIR="/tmp/webdav_burner"
      local CERT="$TMP_DIR/webdav.crt"
      local KEY="$TMP_DIR/webdav.key"
      local MY_USERNAME="claire"
      local MY_PASSWORD=$(${pkgs.openssl}/bin/openssl rand -base64 30 | tr -dc '0-9' | head -c 6)

      echo "Firing up Dufs (Web UI + WebDAV) in: $PWD"
      mkdir -p "$TMP_DIR"

      if [[ ! -f "$CERT" ]]; then
          echo "Generating new burner SSL certs..."
          ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -keyout "$KEY" -out "$CERT" \
              -days 7 -nodes -subj "/CN=localhost" 2>/dev/null
      else
          echo "Reusing existing burner certs from $TMP_DIR..."
      fi

    ${
      if isDarwin then
        ''
          local IP=$(route get default | grep interface | awk '{print $2}' | xargs ipconfig getifaddr)
        ''
      else
        ''
          local IP=$(hostname -I | awk '{print $1}')
        ''
    }

    if [[ -z "$IP" ]]; then
      echo "Error, Could not detect local IP. Are you connected to a network?"
      return 1
    fi

    echo ""
    echo "✅ Dufs Burner Server is live!"
    echo "🌐 Browser & WebDAV URL: https://$IP:$PORT"
    echo "👤 User:  $MY_USERNAME"
    echo "🔑 Pass:  $MY_PASSWORD"
    echo "🛑 Press Ctrl+C to stop."
    echo ""

    # Dufs serves both the Web GUI and WebDAV automatically
    # The :rw at the end of the auth string grants Read/Write/Delete permissions
    ${pkgs.dufs}/bin/dufs . \
      --bind "0.0.0.0" \
      --port "$PORT" \
      --tls-cert "$CERT" \
      --tls-key "$KEY" \
      --auth "$MY_USERNAME:$MY_PASSWORD@/:rw" \
      -A
    }
  '';

  myNixShellFunction = ''
    ns() { 
      local pkg_args=() 
      for x in "$@"; do pkg_args+=("nixpkgs#$x"); done
      nix --extra-experimental-features 'nix-command flakes' shell "''${pkg_args[@]}" 
    }
  '';

  customAddHistory = ''
    zshaddhistory() {
      local line="''${1%%$'\n'}"
      local words=(''${(z)line})
      local cmd
      
      # Find the actual command by skipping over ENV=var assignments
      for cmd in $words; do
        [[ "$cmd" == *=* ]] || break
      done

      if [[ "$line" == *['|<>']* ]]; then
        return 0
      fi

      # DO NOT ADD READ-ONLY COMMANDS
      case "$line" in
        ls|ls\ *|ll|la|exa\ *|eza\ *|tree\ *)               return 1 ;;
        cd|cd\ *|pwd|popd|popd\ *|pushd|pushd\ *|dirs)      return 1 ;;
        clear|exit|history|date|jobs|fg|bg)                 return 1 ;;
        htop|htop\ *)                                       return 1 ;;
        man\ *|which\ *|file\ *|open\ *|codium\ *)          return 1 ;;
        ping\ *|dig\ *|nslookup\ *)                         return 1 ;;
        echo\ *|cat\ *|less\ *|bat\ *)                      return 1 ;;
        source\ .venv*|source\ venv*|conda\ activate\ *)    return 1 ;;
        git\ status|git\ status\ *|git\ add\ *|git\ diff\ *) return 1 ;;
        git\ log\ *|git\ show\ *)                            return 1 ;;
      esac

      whence "$cmd" > /dev/null || return 1
      return 0
    }
  '';

in
{
  programs.zsh = {
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

      setopt AUTO_CD
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
      setopt INTERACTIVE_COMMENTS
      setopt HIST_IGNORE_SPACE
      setopt HIST_IGNORE_ALL_DUPS
      setopt INC_APPEND_HISTORY
      setopt HIST_VERIFY
      setopt EXTENDED_GLOB

      ${lib.optionalString isDarwin ''
        fix-quarantine() { sudo xattr -rd com.apple.quarantine "$@"; }
        rm() { echo "macOS: Use trash (or /bin/rm if you must)."; return 1; }
      ''}

      ${lib.optionalString isLinux ''
        alias rm='rm -I'
      ''}

      ls() {
        if [[ $# -eq 0 ]]; then
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
          ${pkgs.eza}/bin/eza --group-directories-first "$@"
        fi
      }

      ${customAddHistory}
      ${myWebDavServerFunction}
      ${myNixShellFunction}

      if [[ $TERM = "xterm-256color" ]]; then
          source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
          [[ -f ${homeDirectory}/.p10k.zsh ]] && source ${homeDirectory}/.p10k.zsh
      fi

      # --- Welcome Banner ---
      ${pkgs.fortune-kind}/bin/fortune-kind | ${pkgs.cowsay}/bin/cowsay -f koala
    '';

    # Merge common aliases with platform-specific ones
    shellAliases = {
      cat = "${pkgs.bat}/bin/bat -pp";
      mkdir = "mkdir -p";
      mv = "mv -i";
      cp = "cp -i";
      fix-ssh-perms = "find ${homeDirectory}/.ssh -type f -exec chmod 600 {} +";
      gc-nix = "sudo nix store gc -v && sudo nix store optimise -v";
      gc-git = "git reflog expire --expire=now --all && git gc --aggressive --prune=now";
    }
    // lib.optionalAttrs isDarwin {
      # macOS Only Aliases
      fix-launchpad = "sudo find 2>/dev/null /private/var/folders/ -type d -name com.apple.dock.launchpad -exec rm -rf {} +; killall Dock";
      fix-ds_store = "chflags nouchg .DS_Store; rm -rf .DS_Store; pkill Finder; touch .DS_Store; chflags uchg .DS_Store";
    };
  };
}
