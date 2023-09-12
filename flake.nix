{
description = "A flake for building Godot_4 with Android templates";

# Instructions: normally do nix develop.  Or change version, set sha256s to "" and run to find them, nix flake update

# This is trying to run from the dev branches of 4.2.  Look in the readme to get the rev for the source code
# https://downloads.tuxfamily.org/godotengine/4.2/dev4/

nixConfig = {
    extra-substituters = ["https://tunnelvr.cachix.org"];
    extra-trusted-public-keys = ["tunnelvr.cachix.org-1:IZUIF+ytsd6o+5F0wi45s83mHI+aQaFSoHJ3zHrc2G0="];
};

inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
inputs.android.url = "github:tadfisher/android-nixpkgs";

outputs = { self, nixpkgs, android }: rec {
    system = "x86_64-linux";
    version = "4.2.dev.4";
    pkgs = import nixpkgs { inherit system; config = { allowUnfree = true; android_sdk.accept_license = true; }; };

    androidenv = android.sdk.x86_64-linux (sdkPkgs: with sdkPkgs; [
        build-tools-33-0-2
        cmdline-tools-latest
        platform-tools
        platforms-android-33
    ]);

    
    packages.x86_64-linux.godot_4_hacked =
        with pkgs;
        godot_4.overrideAttrs (old: {
            src = fetchFromGitHub {
                name = "godot_${version}"; 
                owner = "godotengine";
                repo = "godot";
                rev = "549fcce5f8f7beace3e5c90e9bbe4335d4fd1476";
                hash = "sha256-sOJJebhGpAxLEhR7wEhCwCHFQ9kGdWpj/qVzaGeBNao=";
            };
            

            preBuild = ''
                substituteInPlace editor/editor_node.cpp \
                    --replace 'About Godot' 'NNing! Godot[v${version}]'

                substituteInPlace platform/android/export/export_plugin.cpp \
                    --replace 'String sdk_path = EDITOR_GET("export/android/android_sdk_path")' 'String sdk_path = std::getenv("tunnelvr_ANDROID_SDK")'

                substituteInPlace platform/android/export/export_plugin.cpp \
                    --replace 'EDITOR_GET("export/android/debug_keystore")' 'std::getenv("tunnelvr_DEBUG_KEY")'

                substituteInPlace editor/editor_paths.cpp \
                    --replace 'return get_data_dir().path_join(export_templates_folder)' 'printf("HITHEREE\n"); return std::getenv("tunnelvr_EXPORT_TEMPLATES")'
            '';
        }); 


    packages.x86_64-linux.godot_4_android = 
        with pkgs;
        symlinkJoin { 
            name = "godot_4-with-android-sdk";
            nativeBuildInputs = [ makeWrapper ];
            paths = [ packages.x86_64-linux.godot_4_hacked ];
            
            postBuild = let
                debugKey = runCommand "debugKey" {} ''
                    ${jre_minimal}/bin/keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
                    mv debug.keystore $out
                '';
            
                export-templates = fetchurl {
                    name = "godot_${version}";
                    url = "https://downloads.tuxfamily.org/godotengine/4.2/dev4/Godot_v4.2-dev4_export_templates.tpz";
                    #url = "https://downloads.tuxfamily.org/godotengine/${version}/Godot_v${version}-stable_export_templates.tpz";
                    sha256 = "sha256-xi8TKlEFuOdNz/Vl/Qm6roige7bSYeYLI6N5mrsbDFY=";
                    recursiveHash = true;
                    downloadToTemp = true;
                    postFetch = ''
                       ${unzip}/bin/unzip $downloadedFile -d ./
                        mkdir -p $out/templates/${version}.stable
                        mv ./templates/* $out/templates/${version}.stable
                    '';
                };
                in
                    ''
                        wrapProgram $out/bin/godot4 \
                            --set tunnelvr_ANDROID_SDK "${androidenv}/share/android-sdk"\
                            --set tunnelvr_EXPORT_TEMPLATES "${export-templates}/templates" \
                            --set tunnelvr_DEBUG_KEY "${debugKey}" \
                            --set GRADLE_OPTS "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidenv}/share/android-sdk/build-tools/33.0.2/aapt2"
                    '';
    };

    #packages.x86_64-linux.default = packages.x86_64-linux.godot_4_hacked;
    packages.x86_64-linux.default = packages.x86_64-linux.godot_4_android;

    devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
            packages.x86_64-linux.default
            jdk11
            gradle
        ];
    };
};
}
