{ config, pkgs, lib, ... }:
let
  stackName = "elasticsearch";
in
{
  networking.firewall.allowedTCPPorts = [9200];

  systemd.services."podman-${stackName}" = {
    description = "Podman Compose Stack Service for ${stackName}";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.podman}/bin/podman-compose -f ${stackPath} up";
      ExecStop = "${pkgs.podman}/bin/podman-compose -f /etc/nixos/deployments/${stackName}/compose.yaml down";
      Restart = "always";
      User = "root";
      WorkingDirectory = "/etc/nixos/deployments/${stackName}";
    };

    wantedBy = [ "multi-user.target" ];
  };
  services.nginx = {
    enable =  true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  services.nginx.virtualHosts."${stackName}.internal"= {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:5601/";
    };
  };
}
