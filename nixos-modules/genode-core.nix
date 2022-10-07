{ config, pkgs, lib, modulesPath, ... }:

with lib;
let
  localPackages = pkgs.buildPackages;

  children' = config.lib.children.freeze
    (config.genode.core.children // config.genode.core.auxiliaryChildren);

  coreErisCaps = with builtins;
    let pkgNames = [ "rtc_drv" ];
    in listToAttrs (map (name:
      let pkg = pkgs.genodePackages.${name};
      in {
        inherit name;
        value = lib.getEris "bin" pkg;
      }) pkgNames);

  tarball =
    "${config.system.build.tarball}/tarball/${config.system.build.tarball.fileName}.tar";

  bootConfigFile = let

    storeBackendInputs =
      lib.optional (config.genode.core.storeBackend == "memory")
      config.system.build.tarball;

    coreInputs =
      # TODO: get rid of this?
      with builtins;
      concatMap (getAttr "extraInputs")
      ((attrValues config.genode.core.children)
        ++ (attrValues config.genode.core.auxiliaryChildren));

    mergeManifests = inputs:
      with builtins;
      let
        f = head: input:
          if hasAttr "manifest" input then
            ''
              ${head}, { mapKey = "${
                lib.getName input
              }", mapValue = ${input.manifest} }''
          else
            abort "${input.pname} does not have a manifest";
      in (foldl' f "([" inputs)
      + "] : List { mapKey : Text, mapValue : List { mapKey : Text, mapValue : Text } }) ";

    addManifest = drv:
      drv // {
        manifest =
          localPackages.runCommand "${drv.name}.dhall" { inherit drv; } ''
            set -eu
            echo -n '[' >> $out
            find $drv/ -type f -printf ',{mapKey= "%p",mapValue="%p"}' >> $out
            ${if builtins.elem "lib" drv.outputs then
              ''
                find ${drv.lib}/ -type f -printf ',{mapKey= "%p",mapValue="%p"}' >> $out''
            else
              ""}
            echo -n ']' >> $out
          '';
      };

    manifest =
      # Manifests are Dhall metadata to be attached to every
      # package to be used for dynamically buildings enviroments
      # using Dhall expressions. Probably not worth pursuing.
      pkgs.writeText "manifest.dhall" (mergeManifests (map addManifest
        (with pkgs.genodePackages; storeBackendInputs ++ coreInputs))
        + lib.optionalString (config.genode.core.romModules != { }) ''
          # [ { mapKey = "romModules", mapValue = [ ${
            lib.concatStringsSep ", " (lib.lists.flatten ((mapAttrsToList
              (k: v: ''{ mapKey = "${k}", mapValue = "${v}" }'')
              config.genode.core.romModules)))
          }] } ]'');

    extraRoutes = lib.concatStringsSep ", " (lib.lists.flatten (let
      toRoutes = prefix:
        lib.mapAttrsToList (name: value:
          map (suffix: ''
            { service =
              { name = "ROM"
              , label =
                  Sigil.Init.LabelSelector.Type.Partial
                    { prefix = Some "${prefix}${name}", suffix = Some "${suffix}" }
              }
            , route = Sigil.Init.Route.parent (Some "${suffix}")
            }
          '') value.coreROMs);
    in (toRoutes "" config.genode.core.children)
    ++ (toRoutes "nixos -> " config.genode.init.children)));

    extraCoreChildren = "[ ${
        lib.concatStringsSep ", " (lib.mapAttrsToList
          (name: value: ''{ mapKey = "${name}", mapValue = ${value.config} }'')
          children')
      } ]";

  in with coreErisCaps;
  localPackages.runCommand "boot.dhall" { } ''
    cat > $out << EOF
    let Sigil = env:DHALL_SIGIL in
    let VFS = Sigil.VFS
    let XML = Sigil.Prelude.XML
    in
    ${./store-wrapper.dhall}
    { binaries = { rtc_drv = "${rtc_drv.cap}" }
    , extraCoreChildren = ${extraCoreChildren}
    , subinit = ${config.genode.init.configFile}
    , storeSize = $(stat --format '%s' ${tarball})
    , routes = [${extraRoutes} ] : List Sigil.Init.ServiceRoute.Type
    , bootManifest = ${manifest}
    }
    EOF
  '';

  erisContents = lib.attrsets.mapAttrsToList (urn: source: {
    target = urn;
    inherit source;
  }) config.genode.init.romModules;

in {

  imports = [ ./lib/children.nix ];

  options.genode = {

    core = {

      prefix = mkOption {
        type = types.str;
        example = "hw-pc-";
        description = "String prefix signifying the Genode core in use.";
      };

      supportedSystems = mkOption {
        type = types.listOf types.str;
        example = [ "i686-genode" "x86_64-genode" ];
        description = "Hardware supported by this core.";
      };

      children = config.lib.types.children { extraOptions = { }; } // {
        description = ''
          Set of children at the lowest init level, these children must not
          have any dependency on a Nix store.
          Configuration format is a Dhall configuration of type
          <literal>Sigil.Init.Child.Type</literal>.
          See https://git.sr.ht/~ehmry/dhall-genode/tree/master/Init/Child/Type
        '';
      };

      auxiliaryChildren = config.lib.types.children { extraOptions = { }; } // {
        internal = true;
        description = ''
          Children added to support other children, such as drivers.
          Do not manually add children here.
        '';
      };

    };

    core = {

      configFile = mkOption {
        type = types.path;
        description = ''
          Dhall boot configuration. See
          https://git.sr.ht/~ehmry/dhall-genode/tree/master/Boot/package.dhall
        '';
      };

      image = mkOption {
        type = types.path;
        description =
          "Boot image containing the base component binaries and configuration.";
      };

      romModules = mkOption {
        type = types.attrsOf types.path;
        default = { };
        description = "Attr set of initial ROM modules";
      };

      storeBackend = mkOption {
        type = types.enum [ "fs" "memory" ]; # "parent"?
        default = "memory";
        description = ''
          Backend for the initial ROM store.

          <variablelist>
            <varlistentry>
              <term>
                <literal>fs</literal>
              </term>
              <listitem>
                <para>Store backed by a File_system session.</para>
              </listitem>
            </varlistentry>
            <varlistentry>
              <term>
                <literal>tarball</literal>
              </term>
              <listitem>
                <para>An in-memory tarball.</para>
              </listitem>
            </varlistentry>
          </variablelist>
        '';
      };

      storePaths = mkOption {
        type = with types; listOf path;
        description = ''
          Derivations to be included in the Nix store in the generated boot image.
        '';
      };

    };

  };

  config = {

    assertions = [{
      assertion = builtins.any (s:
        s == config.nixpkgs.system || s == config.nixpkgs.crossSystem.system)
        config.genode.core.supportedSystems;
      message = "invalid Genode core for this system";
    }];

    genode.core.romModules = with builtins;
      listToAttrs (lib.lists.flatten
        ((map (getAttr "roms") (attrValues children')) ++ (map
          ({ cap, path, ... }: {
            name = cap;
            value = path;
          }) (attrValues coreErisCaps)))) // {
            "init" = "${pkgs.genodePackages.init}/bin/init";
            "report_rom" = "${pkgs.genodePackages.report_rom}/bin/report_rom";
          };

    genode.core.children.jitter_sponge = {
      package = pkgs.genodePackages.jitter_sponge;
      configFile = pkgs.writeText "jitter_sponge.dhall" ''
        let Sigil = env:DHALL_SIGIL

        let Init = Sigil.Init

        in  λ(binary : Text) →
              Init.Child.flat
                Init.Child.Attributes::{
                , binary
                , config = Init.Config::{
                  , policies =
                    [ Init.Config.Policy::{
                      , service = "Terminal"
                      , label = Init.LabelSelector.suffix "entropy"
                      }
                    ]
                  }
                }
      '';
    };

    system.build.configFile = bootConfigFile;

    # Create the tarball of the store to live in core ROM
    system.build.tarball =
      pkgs.buildPackages.callPackage "${modulesPath}/../lib/make-system-tarball.nix" {
        extraInputs = lib.attrsets.mapAttrsToList (_: child: child.package)
          config.genode.init.children;
        contents = erisContents;
        compressCommand = "cat";
        compressionExtension = "";
        storeContents = lib.attrsets.mapAttrsToList (name: child: {
          object = child.configFile;
          symlink = "/config/${name}";
        }) config.genode.init.children;
      };

    system.build.initXml = pkgs.buildPackages.runCommand "init.xml" {
      nativeBuildInputs = with pkgs.buildPackages; [ dhall xorg.lndir libxml2 ];
      DHALL_SIGIL = "${pkgs.genodePackages.dhallSigil}/binary.dhall";
    } ''
      export XDG_CACHE_HOME=$NIX_BUILD_TOP
      lndir -silent \
        ${pkgs.genodePackages.dhallSigil}/.cache \
        $XDG_CACHE_HOME
      dhall text <<< "(env:DHALL_SIGIL).Init.render (${bootConfigFile}).config" > $out
      xmllint --noout $out
    '';

    block.partitions.store = rec {
      image = pkgs.callPackage "${modulesPath}/../lib/make-iso9660-image.nix" {
        contents = erisContents;
        compressImage = true;
        storeContents = lib.attrsets.mapAttrsToList (name: child: {
          object = child.configFile;
          symlink = "/config/${name}";
        }) config.genode.init.children;
        volumeID = "sigil-store";
      } + "/iso/cd.iso.zst";
      guid = lib.uuidFrom (toString image);
    };

    virtualisation.diskImage = if config.genode.core.storeBackend == "fs" then
      import ./lib/make-bootable-image.nix { inherit config lib pkgs; }
    else
      null;

    virtualisation.useBootLoader = config.genode.core.storeBackend == "fs";

    virtualisation.qemu.options = {
      fs = [ "-bios ${pkgs.buildPackages.buildPackages.OVMF.fd}/FV/OVMF.fd" ];
    }.${config.genode.core.storeBackend} or [ ];

  };

}
