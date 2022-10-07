{ lib, stdenv, fetchgit, dhallPackages }:

dhallPackages.buildDhallDirectoryPackage {
  name = "dhall-sigil";
  src = fetchgit {
    url = "https://git.sr.ht/~ehmry/dhall-sigil";
    rev = "692f04344713b472e35a03eb80c7c37e2d812125";
    sha256 = "14hynnhidnj3fwfsiwri0pi9gqhb7lliq14avx4hzc13r2z96cx1";
  };
  dependencies = [ dhallPackages.Prelude ];
}
