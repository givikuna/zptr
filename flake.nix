{
  description = "zptr: directory pointer for fast jumps";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      perSystem = flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          zptr = pkgs.stdenv.mkDerivation {
            pname = "zptr";
            version = "0.0.1";
            src = ./src;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            installPhase = ''
              mkdir -p $out/bin
              cp zptr.rb $out/bin/zptr
              chmod +x $out/bin/zptr
              patchShebangs $out/bin/zptr
            '';
            meta = with pkgs.lib; {
              description = "A quick way to jump around your shell";
              license = licenses.mit;
              maintainers = [ ];
              platforms = platforms.unix;
              mainProgram = "zptr";
            };
          };
        in
        {
          packages.default = zptr;
          packages.zptr = zptr;
        }
      );
    in
    perSystem
    // {
      homeManagerModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.zptr;
        in
        {
          options.programs.zptr = {
            enable = lib.mkEnableOption "zptr directory pointer";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              description = "The zptr package to use.";
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];

            programs.bash.initExtra = ''
              zptr() {
                local out
                out="$(${cfg.package}/bin/zptr "$@")" || return
                [ -n "$out" ] && eval "$out"
              }
            '';

            programs.zsh.initExtra = ''
              zptr() {
                local out
                out="$(${cfg.package}/bin/zptr "$@")" || return
                [ -n "$out" ] && eval "$out"
              }
            '';

            programs.fish.functions.zptr = ''
              set -l out (${cfg.package}/bin/zptr $argv)
              or return
              test -n "$out"; and eval $out
            '';
          };
        };
    };
}
