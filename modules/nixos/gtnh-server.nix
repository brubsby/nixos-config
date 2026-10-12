{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.gtnh-server;

  # Stands in for the minecraft-server binary that services.minecraft-server
  # expects. The jars and java9args.txt live in the (stateful) data dir, which
  # is also the working directory, so this only has to supply java.
  launcher = pkgs.writeShellApplication {
    name = "minecraft-server";
    runtimeInputs = [ cfg.java ];
    text = ''
      exec java "$@" -Dfml.readTimeout=180 @java9args.txt -jar lwjgl3ify-forgePatches.jar nogui
    '';
  };
in
{
  options.services.gtnh-server = {
    enable = lib.mkEnableOption "a GT New Horizons server";

    pack = lib.mkOption {
      type = lib.types.package;
      # Client and server versions must match exactly. 2.8.x packs are named
      # GT_New_Horizons_<version>_Server_Java_17-25.zip.
      default = pkgs.fetchurl {
        url = "https://downloads.gtnewhorizons.com/ServerPacks/GT_New_Horizons_2.7.3_Server_Java_17-21.zip";
        hash = "sha256-8vQ+n2RqM3bBTlVfpo/1r7aDVxnPkNaCbwVyPV+/RsE=";
      };
      description = ''
        Server pack zip, unpacked into the data dir on first start only.
        Changing it does not upgrade an existing install: GTNH upgrades
        replace mods/, config/ and friends by hand, keeping the world.
      '';
    };

    java = lib.mkPackageOption pkgs "jdk21_headless" { };

    memory = lib.mkOption {
      type = lib.types.str;
      default = "6G";
      description = "Heap size, used for both -Xms and -Xmx.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/gtnh";
      description = "Server directory: jars, mods, config, and the World save.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Reuse the nixpkgs module for the user, the stdin FIFO (so `stop` and
    # console commands work), hardening, and the firewall. It stays
    # non-declarative: the pack ships its own server.properties (level-type=rwg
    # matters), and a restored server folder should keep its ops/whitelist.
    services.minecraft-server = {
      enable = true;
      eula = true;
      declarative = false;
      openFirewall = true;
      inherit (cfg) dataDir;
      package = launcher;
      jvmOpts = "-Xms${cfg.memory} -Xmx${cfg.memory}";
    };

    systemd.services.minecraft-server.preStart = lib.mkBefore ''
      if [ ! -e lwjgl3ify-forgePatches.jar ]; then
        echo "Unpacking ${cfg.pack.name} into ${cfg.dataDir}"
        ${lib.getExe pkgs.unzip} -q -o ${cfg.pack} -d .
      fi
    '';
  };
}
