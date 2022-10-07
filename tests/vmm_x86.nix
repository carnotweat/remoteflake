{
  name = "vmm_x86";
  constraints = specs:
    with builtins;
    all (f: any f specs) [ (spec: spec == "nova") (spec: spec == "x86") ];
  machine = { pkgs, ... }: {
    genode.init.children.vmm = {
      package = pkgs.genodePackages.test-vmm_x86;
      configFile = ./vmm_x86.dhall;
      coreROMs = [ "platform_info" ];
    };
  };
}
