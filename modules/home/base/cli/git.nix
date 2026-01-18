{
  programs.git = {
    enable = true;
    settings = {
      # personal
      user = {
        name = "Nevan McLarty";
        email = "37232202+nmclarty@users.noreply.github.com";
      };

      # signing
      tag.gpgSign = true;
      commit.gpgSign = true;
      gpg = {
        format = "ssh";
        ssh.defaultKeyCommand = "ssh-add -L";
      };

      # ui
      column.ui = "auto";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";

      # general
      init.defaultBranch = "main";
      push = {
        autoSetupRemote = true;
        followTags = true;
      };
      fetch = {
        prune = true;
        pruneTags = true;
        all = true;
      };
    };
    ignores = [
      ".DS_Store"
      "**/.claude/settings.local.json"
    ];
  };
}
