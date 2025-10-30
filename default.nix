{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.deployments;
  anyServiceEnabled = lib.any (service: service.enable) [
    cfg.elasticsearch
    cfg.homeAssistant
    cfg.llamaCpp
    cfg.octoprint
    cfg.unifi
  ];
in
{
  # Import individual deployment modules based on configuration
  imports = [
    ./elasticsearch
    ./home-assistant
    ./llama.cpp
    ./octoprint
    ./unifi
  ];

  options.services.deployments = {
    dataDir = mkOption {
      type = types.str;
      default = "/etc/nixos/deployments";
      description = "Directory where deployment configurations are stored";
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

  config = mkIf anyServiceEnabled {
    environment.systemPackages = with pkgs; [
      podman
      podman-compose
    ];

    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    # BUG: nixos/nixpkgs#226365
    networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];
    virtualisation.oci-containers.backend = "podman";

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    age.secrets."cf_origin_cert" = {
      file = ../secrets/cf_origin_cert.pem.age;
      mode = "770";
      owner = "nginx";
      group = "nginx";
    };

    age.secrets."cf_origin_key" = {
      file = ../secrets/cf_origin_key.pem.age;
      mode = "770";
      owner = "nginx";
      group = "nginx";
    };
  };
}
