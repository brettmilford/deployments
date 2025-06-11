{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.deployments;
in
{
  options.services.deployments = {
    enable = mkEnableOption "Enable container-based service deployments";

    dataDir = mkOption {
      type = types.str;
      default = "/etc/nixos/deployments";
      description = "Directory where deployment configurations are stored";
    };

    containerDataDir = mkOption {
      type = types.str;
      default = "/var/lib/containers";
      description = "Directory where container data is stored";
    };

    enableNginxProxy = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Nginx as a reverse proxy for services";
    };

    baseDomain = mkOption {
      type = types.str;
      default = "internal";
      description = "Base domain for service virtual hosts";
    };

    elasticsearch = {
      enable = mkEnableOption "Elasticsearch service";
    };

    homeAssistant = {
      enable = mkEnableOption "Home Assistant service";
    };

    llamaCpp = {
      enable = mkEnableOption "Llama.cpp service";
    };

    octoprint = {
      enable = mkEnableOption "OctoPrint service";
    };

    unifi = {
      enable = mkEnableOption "UniFi Controller service";
    };
  };

  config = mkIf cfg.enable {
    # Import individual deployment modules based on configuration
    imports = [
      (mkIf cfg.elasticsearch.enable ./elasticsearch)
      (mkIf cfg.homeAssistant.enable ./home-assistant)
      (mkIf cfg.llamaCpp.enable ./llama.cpp)
      (mkIf cfg.octoprint.enable ./octoprint)
      (mkIf cfg.unifi.enable ./unifi)
    ];

    # Common settings for all deployments
    environment.systemPackages = with pkgs; [
      podman
      podman-compose
    ];

    # Enable podman socket and service
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # Enable nginx if proxy is enabled
    services.nginx = mkIf cfg.enableNginxProxy {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };

    # Ensure container data persists across rebuilds
    system.activationScripts.createContainerPaths = ''
      mkdir -p ${cfg.containerDataDir}
      mkdir -p ${cfg.dataDir}
    '';
  };
}