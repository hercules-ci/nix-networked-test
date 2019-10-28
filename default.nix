{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs) lib writeScript stdenv;

  /*
    This produces a fixed output but only if
    succeeds if the contained test succeeds.

    The contained test has network access
    and MUST NOT produce any lasting effects.

    WARNING: This allows side effects through
             network access, but this function
             CAN NOT make any guarantees about
             the execution.

       - Your test may or may not run many times.
       - Your test may run after a newer version was run.
       - Your test may run concurrently with itself or other tests.
       - Your test may run incompletely.
       - Your test may be hard to re-run after it has succeeded.
       - Your test may run at unexpected places and times

    For these reasons
       - Only create unique resources and do not assume that the test script
         can tear them down again.
       - The meaning of a test success is that at some time and place, the
         test has worked.
       - In particular, it can not be used for the purpose of "monitoring".
         
    Because this derivation is unable to leak
    information from the network, it is
    referentially transparent on the Nix side of things.

    You can use the setup logic in stdenv, but
    not the phases.
   */
  networkedDerivation = args:
    let
      textWithAllDependencies = ''
        The test that succeeded was similar to ${context}
      '';
      # This only serves to make the output unique, to avoid
      # accidentally conflating distinct tests.
      context =
        builtins.unsafeDiscardStringContext
          ((stdenv.mkDerivation drvArgs).drvPath);
      drvArgs = args // {
        phases = args.phases ++ ["outputPhase"];
      };
    in stdenv.mkDerivation (drvArgs // {
      outputPhase = ''
        echo -n ${lib.escapeShellArg textWithAllDependencies} >$out
      '';
      outputHashMode = "flat";
      outputHashAlgo = "sha256";
      outputHash = builtins.hashString "sha256" textWithAllDependencies;
    });

  networkedTest = name: args: script:
    networkedDerivation (args // {
      inherit name;
      phases = ["testPhase"];
      testPhase = script;
    });
in

{
  inherit networkedDerivation networkedTest;
}
