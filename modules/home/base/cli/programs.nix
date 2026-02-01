{
  programs = {
    micro = {
      enable = true;
      settings = {
        clipboard = "terminal";
        mkparents = true;
        scrollbar = true;
      };
    };
    btop = {
      enable = true;
      settings = {
        graph_symbol = "block";
        update_ms = 1000;
        proc_sorting = "cpu direct";
        proc_tree = true;
        proc_gradient = false;
        proc_filter_kernel = true;
        proc_aggregate = true;
        disks_filter = "/ /srv /nix";
        swap_disk = false;
        use_fstab = false;
        disk_free_priv = true;
        show_coretemp = false;
        proc_per_core = true;
      };
    };
  };
}
