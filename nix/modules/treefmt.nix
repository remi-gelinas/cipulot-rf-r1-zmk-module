{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      treefmt = {
        programs = {
          nixfmt.enable = true;
          clang-format.enable = true;
          cmake-format.enable = true;
        };

        settings.formatter."dts-linter" = {
          command = "${pkgs.bash}/bin/bash";
          options = [
            "-euc"
            ''
              args=()
              for f in "$@"; do args+=(--file "$f"); done
              exec ${self'.packages.dts-linter}/bin/dts-linter \
                --format --formatFixAll "''${args[@]}"
            ''
            "--"
          ];

          includes = [
            "*.dts"
            "*.dtsi"
            ".keymap"
            ".overlay"
          ];

          # dts-linter hugely corrupts this one, might be worth an issue
          excludes = [
            "boards/cipulot/rf_r1/rf_r1-layouts.dtsi"
          ];
        };
      };
    };
}
