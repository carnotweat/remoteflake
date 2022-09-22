# remoteflake
- vocabulary 
  - hermetic
	- /həːˈmɛtɪk/
    - (of a seal or closure) complete and airtight.
	  - so sandboxed here , as in, stateless atomic upgrades or something.
  - pure
	- independent of env, command line inputs , flags
  - self contained
	- independent of network
 

 
- what
  - a very minimal flake build of nixos
- why flake
  - just like emacs , I d rather rely on a set of macros in a file than checkout,registry, tarball
- why this way
  - flake is like makefile
  - configuration.nix is like ~/.config
- why not take every overlay to ~/.config
  - I am not in to too many files for sysops, even if the situtation arisres
  
  
  , I d go with too manybranches. 
- todo
  - cachix
  - nickel
  - tweak ipv6, dns config for nar.zx
  - nixops for nix-infra 
- what is not there 
  - home manager
  - darwin
  - shell.nix
- how to get it up and running
  - just ln -s it to /etc/nixos and nixos-rebuild --flake /etc/nixos#hostname
- Suggested reference
  - [1](https://zimbatm.com/notes/nixflakes)
  - [2](https://xeiaso.net/blog/nix-flakes-look-up-package)
