#RemoteFlake
- configuration.nix
	- what is defined here
		- nix for nar.xz archives
		- nixpkgs for commit-ids 
			- in let, in block,partial application, so it doesn't affect the whole build
		
- flake.nix
  - what is defined here
	- input url for pkgs branches, external repos, modules
	- system to be inherited for nixops, remote
	- overlay for derived build and calling the modules defined in input urls or locally.

- composing isolated builds
  - package {p, q..} depend on {{r.v,s.v_x..}, {r.v'..}} respectively and I may need both in future or atm.
  - instead of installing r.v_x in configuration, flake or even default.nix, I can just write a shell derivaions for  {p,{r.v,s.v_x...}}, which builds without conflict and then I can compose or call all such shells in shell.nix
  -this part is in progress.
