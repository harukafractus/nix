{
  config,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;
in
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    ignores = [
      "*.DS_Store"
      "*__pycache__/"
    ];
    signing = {
      format = "ssh";
      signByDefault = true;
    };
    settings = {
      init.defaultBranch = "main";
      user = {
        email = "106440141+fractuscontext@users.noreply.github.com";
        name = "fractuscontext";
        signingkey = "${homeDirectory}/.ssh/id_ed25519.pub";
      };
    };
  };
}
