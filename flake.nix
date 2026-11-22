{
  description = "OpenTofu + Talos dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.htpasswd = pkgs.apacheHttpd;

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.curl
          pkgs.opentofu
          pkgs.talosctl
          pkgs.kubectl
          pkgs.kubernetes-helm
          pkgs.zstd
        ];
      };
    };
}
