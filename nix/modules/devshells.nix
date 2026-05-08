{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      uploadArtifactV4 = pkgs.fetchFromGitHub {
        owner = "actions";
        repo = "upload-artifact";
        rev = "v4.6.2";
        hash = "sha256-pqsDYUtqL+kQmrAJoCzlFEPGfzqqmfUfskr83oQdWrI=";
      };

      patchedAct = pkgs.act.overrideAttrs (old: {
        patches = [
          (pkgs.fetchpatch {
            name = "act-pr-6039-discard-unknown-protobuf-fields.patch";
            url = "https://github.com/nektos/act/pull/6039.patch";
            hash = "sha256-eEBIJcm0r5DQ+Yco0Zj7ev1RsLQVp4gp/IUyYI9JEp0=";
          })
        ];

        nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.makeWrapper ];

        postFixup = ''
          wrapProgram $out/bin/act \
          --add-flags "--local-repository=actions/upload-artifact@v7=${uploadArtifactV4}"
        '';
      });
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          patchedAct
          dfu-util
          git
          gh
          tio
          self'.packages.dts-linter
        ];
      };
    };
}
