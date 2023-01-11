{}:
let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {
    overlays = [ (_: _: { inherit sources; }) (import ./nix/overlay.nix { }) ];
  };
in
with pkgs;
let
in
mkShell {
  name = "helm-chart-shell";

  NODE_PATH = "${nodePackages."@commitlint/config-conventional"}/lib/node_modules";

  buildInputs = [
    commitlint
    git
    helm-docs
    kubernetes-helm-wrapped
    niv
    pre-commit
    semver-tool
    yq-go
  ];

  shellHook = ''
    pre-commit install
    pre-commit install --hook commit-msg
  '';
}
