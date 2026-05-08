{
  perSystem =
    { pkgs, self', ... }:
    {
      packages = {
        bootloader-src =
          let
            tinyuf2 = pkgs.fetchFromGitHub {
              owner = "adafruit";
              repo = "tinyuf2";
              rev = "0.35.0";
              hash = "sha256-K9TPcS+efeZO9ybRvoBLJKVxAvSL6BWfllVQJ9+/DnM=";
              fetchSubmodules = true;
              leaveDotGit = true;
            };

            cmsis-device-f4 = pkgs.fetchFromGitHub {
              owner = "STMicroelectronics";
              repo = "cmsis_device_f4";
              rev = "2615e866fa48fe1ff1af9e31c348813f2b19e7ec";
              hash = "sha256-KkKZmJ6tWEW70jDVE4S5VkEMYmixniTinkThFOOuzKE=";
            };

            stm32f4xx-hal-driver = pkgs.fetchFromGitHub {
              owner = "STMicroelectronics";
              repo = "stm32f4xx_hal_driver";
              rev = "04e99fbdabd00ab8f370f377c66b0a4570365b58";
              hash = "sha256-b+Z+szmbOts3WmCIARNH7uxWm6crC1IJIomHvU7s3Ro=";
            };
          in
          pkgs.runCommand "bootloader-src" { } ''
            cp -R --no-preserve=mode ${tinyuf2}                 $out
            mkdir -p                                            $out/lib/mcu/st
            cp -R --no-preserve=mode ${cmsis-device-f4}         $out/lib/mcu/st/cmsis_device_f4
            cp -R --no-preserve=mode ${stm32f4xx-hal-driver}    $out/lib/mcu/st/stm32f4xx_hal_driver
            cp -R --no-preserve=mode ${./boards/cipulot_rf_r1}  $out/ports/stm32f4/boards/cipulot_rf_r1
          '';

        bootloader = pkgs.stdenvNoCC.mkDerivation {
          name = "bootloader";

          src = self'.packages.bootloader-src;

          nativeBuildInputs = with pkgs; [
            gcc-arm-embedded-13
            python3
            cmake
            ninja
            gitMinimal
            dfu-util
          ];

          # Patch the linker so &bootmap works correctly
          # Linker is CRLF endings, patch is LF :(
          prePatch = "sed -i 's/\r$//' ports/stm32f4/linker/stm32f4_boot.ld";
          patches = [ ./patches/128k-sram.patch ];
          patchFlags = [ "-p0" ];

          cmakeDir = "../ports/stm32f4";
          cmakeFlags = [
            "-DBOARD=cipulot_rf_r1"
            "-GNinja"
            "-DCMAKE_C_COMPILER=arm-none-eabi-gcc"
            "-DCMAKE_CXX_COMPILER=arm-none-eabi-g++"
            "-DCMAKE_ASM_COMPILER=arm-none-eabi-gcc"
            "-DCMAKE_AR=arm-none-eabi-ar"
            "-DCMAKE_RANLIB=arm-none-eabi-ranlib"
            "-DCMAKE_STRIP=arm-none-eabi-strip"
            "-DCMAKE_BUILD_TYPE=MinSizeRel"
            "-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=TRUE"
          ];

          installPhase = ''
            runHook preInstall
            dfu-suffix --vid 0483 --pid df11 --add tinyuf2.bin
            install -Dm644 -t $out tinyuf2.{elf,bin,hex}
            runHook postInstall
          '';
        };
      };

      apps.flash-bootloader = {
        type = "app";
        program = pkgs.lib.getExe (
          pkgs.writeShellApplication {
            name = "flash-bootloader";
            runtimeInputs = [ pkgs.dfu-util ];
            text = ''
              dfu-util -d 0483:df11 -a 0 -s 0x08000000:leave -D "${self'.packages.bootloader}/tinyuf2.bin"
            '';
          }
        );
      };

      apps.flash-app = {
        type = "app";
        program = pkgs.lib.getExe (
          pkgs.writeShellApplication {
            name = "flash-app";

            runtimeInputs = [
              pkgs.dfu-util
              pkgs.python3
              pkgs.unzip
            ];

            text = ''
              if [ $# -lt 1 ]; then
                echo "Usage: nix run .#flash-app -- <path-to-uf2-or-zip>" >&2
                exit 1
              fi

              src="$1"
              work=$(mktemp -d)
              trap 'rm -rf "$work"' EXIT

              # Unwrap if it's a zip (act stores artifacts as <name>.zip).
              if [[ "$src" == *.zip ]]; then
                unzip -j "$src" '*.uf2' -d "$work" >/dev/null
                src=$(find "$work" -name '*.uf2' | head -n 1)
                if [ -z "$src" ]; then
                  echo "no .uf2 inside $1" >&2
                  exit 1
                fi
              fi

              bin="$work/firmware.bin"
              load_addr=$(python3 - "$src" "$bin" <<'PY'
              import sys, struct
              src, dst = sys.argv[1], sys.argv[2]
              with open(src, 'rb') as f:
                  data = f.read()
              BLOCK = 512
              PAYLOAD = 256
              base = None
              out = bytearray()
              for i in range(0, len(data), BLOCK):
                  b = data[i:i+BLOCK]
                  magic0, magic1 = struct.unpack_from('<II', b, 0)
                  assert magic0 == 0x0A324655 and magic1 == 0x9E5D5157, "bad UF2 magic"
                  addr = struct.unpack_from('<I', b, 12)[0]
                  size = struct.unpack_from('<I', b, 16)[0]
                  if base is None:
                      base = addr
                  off = addr - base
                  if len(out) < off + size:
                      out.extend(b'\xff' * (off + size - len(out)))
                  out[off:off+size] = b[32:32+size]
              with open(dst, 'wb') as f:
                  f.write(out)
              print(f"0x{base:08x}")
              PY
              )

              echo "Flashing $bin to $load_addr (chip must be in ROM DFU)..."
              dfu-util -d 0483:df11 -a 0 -s "$load_addr:leave" -D "$bin"
            '';
          }
        );
      };
    };
}
