{ lib, ... }:

{
  lib = {

    # Type of a declaration of init children.
    types.children = { extraOptions }:
      with lib;
      mkOption {
        default = { };
        type = with types;
          attrsOf (submodule {
            options = {

              binary = mkOption {
                description =
                  "Program binary for this child. Must be an ERIS URN.";
                default = null;
                type = types.nullOr types.str;
                example =
                  "urn:erisx2:AEAU4KT7AGJLA5BHPWFZ7HX2OVVNVFGDM2SIS726OPZBGXDED64QIDPHN2M5P5HIMOG3YDSWBGDPNUMZKCG4CRVU4DI5BOS5IJRFCSLQQY";
              };

              coreROMs = mkOption {
                type = with types; listOf str;
                default = [ ];
                description = ''
                  List of label suffixes that when matched against
                  ROM requests shall be forwared to the core.
                '';
                example = [ "platform_info" ];
              };

              configFile = mkOption {
                type = types.path;
                description = ''
                  Dhall configuration of child.
                  See https://git.sr.ht/~ehmry/dhall-genode/tree/master/Init/Child/Type
                '';
              };

              extraErisInputs = mkOption {
                description = "List of ERIS inputs to add to the init closure.";
                default = [ ];
                type = types.listOf types.attrs;
              };

              extraInputs =
                # TODO: deprecated?
                mkOption {
                  description = "List of packages to build a ROM store with.";
                  default = [ ];
                  type = types.listOf types.package;
                };

              package = mkOption {
                description = "Package to source the binary for this child.";
                type = lib.types.package;
                example = literalExample "pkg.genodePackages.init";
              };

              uplinks = import ./uplinks-option.nix { inherit lib; };

            } // extraOptions;
          });
      };

    /* Map a set of children to the config and
       ROM closure of each child.
    */
    children.freeze = children:
      with builtins;
      lib.attrsets.mapAttrs (_:
        { binary, configFile, extraErisInputs, package, ... }:
        let
          toRoms = { cap, closure, path }:
            [{
              name = cap;
              value = path;
            }] ++ (lib.mapAttrsToList (value: name: { inherit name value; })
              closure);
          extraRoms = map toRoms extraErisInputs;
        in if binary != null then {
          config = ''${configFile} "${binary}"'';
          roms = extraRoms;
        } else
          let bin = lib.getEris "bin" package;
          in {
            config = ''${configFile} "${bin.cap}"'';
            roms = toRoms bin ++ extraRoms;
          }) children;
  };
}
