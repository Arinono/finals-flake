{
  description = "Finals.id Companion App (AppImage) packaged for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # ---- Update these two values when a new release comes out ----------
    version = "2.5.0";
    hash = "sha256-hWLcr5BuOJYDxIxWWDTr9saKEr74LjM5VTodd4nKPIk=";
    # ---------------------------------------------------------------------

    pname = "finals-id-companion";

    src = pkgs.fetchurl {
      url = "https://finalstrackercdn.tyr.gg/${version}/Finals.id%20Companion%20App_${version}_amd64.AppImage";
      inherit hash;
    };

    appimageContents = pkgs.appimageTools.extract {inherit pname version src;};

    finals-id = pkgs.appimageTools.wrapType2 {
      inherit pname version src;

      extraPkgs = pkgs: with pkgs; [webkitgtk_4_1 libsoup_3 gtk3];

      extraInstallCommands = ''
        # Desktop entry (name inside the AppImage may vary, so glob it)
        for f in ${appimageContents}/*.desktop; do
          install -Dm444 "$f" $out/share/applications/${pname}.desktop
          sed -i -E 's|^Exec=[^ ]*|Exec=${pname}|; s|^Icon=.*|Icon=${pname}|' \
            $out/share/applications/${pname}.desktop
          break
        done

        # Icons
        if [ -d ${appimageContents}/usr/share/icons ]; then
          for icon in ${appimageContents}/usr/share/icons/hicolor/*/apps/*.png; do
            size=$(basename "$(dirname "$(dirname "$icon")")")
            install -Dm444 "$icon" $out/share/icons/hicolor/$size/apps/${pname}.png
          done
        elif [ -e ${appimageContents}/.DirIcon ]; then
          install -Dm444 ${appimageContents}/.DirIcon $out/share/pixmaps/${pname}.png
        fi
      '';

      meta = with pkgs.lib; {
        description = "Companion app for THE FINALS by finals.id";
        homepage = "https://finals.id";
        license = licenses.unfree;
        platforms = ["x86_64-linux"];
        sourceProvenance = [sourceTypes.binaryNativeCode];
        mainProgram = pname;
      };
    };
  in {
    packages.${system} = {
      default = finals-id;
      finals-id = finals-id;
    };

    apps.${system}.default = {
      type = "app";
      program = "${finals-id}/bin/${pname}";
    };
  };
}
