{
  perSystem =
    { pkgs, ... }:
    {
      packages.dts-linter = pkgs.buildNpmPackage {
        pname = "dts-linter";
        version = "0-unstable-9126648";

        src = pkgs.fetchFromGitHub {
          owner = "kylebonnici";
          repo = "dts-linter";
          rev = "9126648";
          hash = "sha256-RkcNhtotRfYZ7y7amSSubww/sxHnERJJ18Qg11nGRWI=";
        };

        npmDepsHash = "sha256-BXyUrj3Wgd14VjKkBLn/7cPeYfXq5qKDG3bAWvJkS84=";
        npmBuildScript = "compile:prod";
      };
    };
}
