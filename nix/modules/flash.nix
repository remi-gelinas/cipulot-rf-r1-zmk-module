{
  perSystem =
    { pkgs, ... }:
    {
      apps.flash-app = {
        type = "app";
        program = pkgs.lib.getExe (
          pkgs.writeShellApplication {
            name = "flash-app";

            runtimeInputs = [
              pkgs.dfu-util
              pkgs.unzip
            ];

            text = ''
              if [ $# -lt 1 ]; then
                echo "Usage: nix run .#flash-app -- <path-to-bin-or-zip>" >&2
                echo "Chip must be in ROM DFU (BOOT0 + reset, or &bootloader keypress)." >&2
                exit 1
              fi

              src="$1"
              work=$(mktemp -d)
              trap 'rm -rf "$work"' EXIT

              # Unwrap if it's a zip (act stores artifacts as <name>.zip).
              if [[ "$src" == *.zip ]]; then
                unzip -j "$src" '*.bin' -d "$work" >/dev/null
                src=$(find "$work" -name '*.bin' | head -n 1)
                if [ -z "$src" ]; then
                  echo "no .bin inside $1" >&2
                  exit 1
                fi
              fi

              echo "Flashing $src to 0x08000000 via ROM DFU..."
              dfu-util -d 0483:df11 -a 0 -s 0x08000000:leave -D "$src"
            '';
          }
        );
      };

      apps.flash-erase-storage = {
        type = "app";
        program = pkgs.lib.getExe (
          pkgs.writeShellApplication {
            name = "flash-erase-storage";

            runtimeInputs = [
              pkgs.dfu-util
              pkgs.python3
            ];

            text = ''
              # Wipe the 256 K storage partition (sectors 6-7, 0x08040000-0x0807FFFF).
              # Use once when migrating from QMK / other firmware that left non-NVS
              # bytes in this region — Zephyr's nvs_mount() refuses to format
              # non-blank, non-NVS sectors, causing silent settings_save failures.
              # Normal firmware flashing preserves this region; this utility is
              # for the first-flash / migration case only.

              echo "Chip must be in ROM DFU (BOOT0 + reset, or &bootloader keypress)."
              echo "Wiping storage partition (0x08040000, 256 K)..."

              work=$(mktemp -d)
              trap 'rm -rf "$work"' EXIT

              python3 -c 'open("'"$work"'/blank.bin","wb").write(b"\xff"*0x40000)'
              dfu-util -d 0483:df11 -a 0 -s 0x08040000:leave -D "$work/blank.bin"

              echo "Done. NVS will format on next firmware boot."
            '';
          }
        );
      };
    };
}
