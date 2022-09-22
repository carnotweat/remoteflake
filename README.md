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

 
- So if flake doesn't get env-var from env or command flags, where does it get flake inputs  
to inherit package properties?
  - flake inputs
  - imported config
  - compose flakes  ( for multiple builds and systems) with
	- overlay
		- when a flake wants to extend nixpkgs with their own overrides
- Why 
- we want to fetch, catch and eval out refs ( objects when stored) , from specific git branch   
es and revisions irrespective of our env, network, states, flags. So that we can be detrministic  
in telling our peer, about the reproducible and consistent build , we are going to deploy in his  
machine
- what
  - a very minimal flake build of nixos
  - flake is like makefile
  - configuration.nix is like ~/.config
- why not take every overlay to ~/.config
  - I am not in to too many files for sysops, even if the situtation arisres    
  , I d go with too many branches.
- why not direnv
  - By exatension, I avoid converting a dir to flake project everytime I use a flake.nix 
- todo
  - overlay
	- nur
	- devshell
	- flake-utils
- what is not there 
  - home manager
  - darwin
  - shell.nix
- how to get it up and running
  - just ln -s it to /etc/nixos and nixos-rebuild --flake /etc/nixos#hostname
- Suggested reference
  - [1](https://zimbatm.com/notes/nixflakes)
  - [2](https://xeiaso.net/blog/nix-flakes-look-up-package)
