{ pkgs ? import <nixpkgs> {} }:

let
  inherit (import ./default.nix { inherit pkgs; }) networkedTest;
in

/*
   This tests *curl*, not google.
   Google is only a requirement for the test.
   Try not to cause lasting effects.
 */
networkedTest "test-curl-on-google" {
  buildInputs = [
     pkgs.cacert
    pkgs.curl
  ];
} ''
  curl https://google.com/
''
