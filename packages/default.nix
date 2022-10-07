{ final, prev }:

let
  upstream = import ./genodelabs { inherit final prev; };
  inherit (upstream) genodeSources;

  inherit (final) callPackage;
  inherit (prev) buildPackages;

  dhallPackages =
    buildPackages.callPackage ./dhall { };

  buildDepotWorld = let
    genodeWorld = prev.fetchFromGitHub {
      owner = "genodelabs";
      repo = "genode-world";
      rev = "0ed545e55a90c39df23a86eb733961de71d56241";
      hash = "sha256-sirmUtLmZ5YnfLKrOvOBafnZW3UW+1LtkiGu85Ma820=";
    };
  in attrs:
  genodeSources.buildDepot (attrs // {
    postConfigure = ''
      cp -r --no-preserve=mode ${genodeWorld} $GENODE_DIR/repos
    '';
  });

in upstream // {

  bender = buildPackages.callPackage ./bender { };

  block_router = callPackage ./block_router { };

  device_manager = callPackage ./device_manager { };

  dhallSigil = dhallPackages.sigil;

  nic_bus = callPackage ./nic_bus { };

  NOVA = callPackage ./NOVA { };

  rtc-dummy = callPackage ./rtc-dummy { };

  show_input = callPackage ./show_input { };

  solo5 = let drv = callPackage ./solo5 { };
  in drv // { tests = drv.tests // { pname = "solo5-tests"; }; };

  sotest-producer = callPackage ./sotest-producer { };

  ssh_client = buildDepotWorld {
    name = "ssh_client";
    portInputs = with genodeSources.ports; [ libc libssh openssl zlib ];
  };

  worldSources = prev.fetchFromGitHub {
    owner = "genodelabs";
    repo = "genode-world";
    rev = "521f9fb5a66b18441f53a96e3993a84b772f27e5";
    sha256 = "0dy906ffbw6khkwd05vhppcw2mr4ma0h3b6n52a71cfail87jfnw";
  };

}
