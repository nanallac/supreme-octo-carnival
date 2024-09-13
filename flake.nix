{
  description = "Testing out Timescale";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };

  outputs = inputs@{ flake-parts, process-compose-flake, services-flake, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.process-compose-flake.flakeModule
      ];
      systems = [ "x86_64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        process-compose."default" = { config, ... }:
          let
            dbName = "postgres";
          in
            {
              imports = [
                inputs.services-flake.processComposeModules.default
              ];

              services.postgres."pg1" = {
                enable = true;
                extensions = exts: [
                  exts.system_stats
                  exts.timescaledb
                  exts.timescaledb_toolkit
                ];
                settings = {
                  shared_preload_libraries = "timescaledb";
                };
                initialScript.before = ''
                  CREATE EXTENSION IF NOT EXISTS system_stats;
                  CREATE EXTENSION IF NOT EXISTS timescaledb;
                  CREATE EXTENSION IF NOT EXISTS timescaledb_toolkit;
                '';
                initialDatabases = [
                  {
                    name = "sensors";
                    schemas = [ ./sensors.sql ];
                  }
                ];
              };
              services.pgadmin."pgad1" = {
                enable = true;
                initialEmail = "admin@real-email.com";
                initialPassword = "secure-password";
              };
              postHook = ''
                rm -r ./data
              '';
            };
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.postgrest
            pkgs.postgresql
          ];
        };
      };
      flake = {};
    };
}
