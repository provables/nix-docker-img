# Nix Docker Image

A simple wrapper to build a Docker image based on a Nix image, with flakes enabled.

## Usage

Use `buildNixImage` instead of `buildLayeredImage`:

```nix
hello = buildNixImage {
  name = "hello";
  tag = "latest";
  contents = with pkgs; [
    pkgs.hello
  ];
  config.Cmd = [ "nix" "config" "show" "experimental-features" ];
};
```

# License

MIT