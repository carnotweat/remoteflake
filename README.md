# remoteflake
- a very minimal flake build of nixos
- why 
-- besides trying new things , the differences are ideological
--- nix vs bazel
--- flake vs niv 
--- emacs vs vscode
--- risc v vs intel
--- linux vs windows
--- nixos vs android
- well you get the gist
- todo
-- cachix
-- nickel
-- tweak ipv6, dns config for nar.zx
-- nixops for nix-infra 
- what is not there 
-- home manager
-- darwin
-- shell.nix
- how to get it up and running
-- just ln -s it to /etc/nixos and nixos-rebuild --flake /etc/nixos#hostname
Suggested reference
-- [1](https://zimbatm.com/notes/nixflakes)
-- [2](https://xeiaso.net/blog/nix-flakes-look-up-package)