{
  pkgs,
  lib,
  pkgs-stable-linux ? null,
  pkgs-stable-darwin ? null,
  pkgs-haruka-darwin ? null,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin;
  pkgs-stable = if isDarwin then pkgs-stable-darwin else pkgs-stable-linux;

  fonts = with pkgs; [
    # Normal CLI apps & Fonts (Unstable)
    source-han-serif
    source-han-code-jp
    meslo-lgs-nf
  ];

  unstablePackages = with pkgs; [
    fortune-kind
    cowsay
    eza
    bat
    uv
    htop
    asciinema
    asciinema-agg
    nixd
    nixfmt
    git-filter-repo
    ansible
    ansible-lint
  ];

  stablePackages = with pkgs-stable; [
    # Heavy CLI apps (Stable)
    ffmpeg
    imagemagick
    podman
    unar
  ];

  darwinGuiStable = with pkgs-stable; [
    # Heavy GUI apps (Stable)
    remmina
    wireshark
  ];

  darwinGuiUnstable = with pkgs; [
    # GUI apps that need unstable for binary cache
    qbittorrent
    utm
    iina
    libreoffice-bin
  ];

  darwinGuiHaruka = with pkgs-haruka-darwin; [
    # Overlay GUI apps
    librewolf
    ungoogled-chromium
    telegram-desktop
    lunarfyi
  ];

in
{
  home.packages =
    unstablePackages
    ++ fonts
    ++ stablePackages
    ++ lib.optionals isDarwin (darwinGuiStable ++ darwinGuiUnstable ++ darwinGuiHaruka);
}
