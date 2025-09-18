{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        image =
          let
            hashes = {
              "x86_64-linux" = "sha256-NIg59VsYDql6RSAdfqm94+3HDucexGdipFwWYxDhsWU=";
              "x86_64-darwin" = hashes."x86_64-linux";
              "aarch64-linux" = "sha256-tAj7Eax/B46NKn0uUR/KMyna4tJhYvs/8YgYuiTtK5Q=";
              "aarch64-darwin" = hashes."aarch64-linux";
             };
          in
          pkgs.dockerTools.pullImage {
            imageName = "nixos/nix";
            imageDigest = "sha256:24196c350d146529a4101edea9c82129308640b500ebbc01d225ad36b6322cb6";
            hash = hashes.${system};
            finalImageName = "nixos/nix";
            finalImageTag = "2.31.1";
          };

        imageGz = image.overrideAttrs (final: prev: {
          buildCommand = prev.buildCommand + ''
            ${pkgs.gzip}/bin/gzip $out
            mv $out.gz $out
          '';
        });

        buildNixImage = args:
          let
            newArgs = args // {
              fromImage = imageGz;
              extraCommands = ''
                mkdir -p ./root/.config/nix
                echo "experimental-features = nix-command flakes" >> ./root/.config/nix/nix.conf
              '' + (args.extraCommands or "");
            };
          in
          pkgs.dockerTools.buildLayeredImage newArgs;

        hello = buildNixImage {
          name = "hello";
          tag = "latest";
          contents = with pkgs; [
            coreutils
            pkgs.hello
          ];
          config.Cmd = [ "nix" "config" "show" "experimental-features" ];
        };
      in
      {
        packages.default = hello;
        lib = {
          inherit buildNixImage;
        };
      }
    );
}
