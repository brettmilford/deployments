{ config, pkgs, lib, ... }:
let
  stackName = "home-assistant";
in
{
  networking.firewall.allowedTCPPorts = [1400 1443 21063 21064 21065];
  networking.firewall.allowedUDPPorts = [5353 1900];

  systemd.services."podman-${stackName}" = {
    description = "Podman Compose Stack Service for ${stackName}";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Environment = "PATH=${pkgs.podman}/bin:${pkgs.podman-compose}/bin:/run/wrappers/bin:/usr/bin:/bin";
      Type = "simple";
      ExecStart = "${pkgs.podman-compose}/bin/podman-compose -f /etc/nixos/deployments/${stackName}/compose.yaml up";
      ExecStop = "${pkgs.podman-compose}/bin/podman-compose -f /etc/nixos/deployments/${stackName}/compose.yaml down";
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
      proxyPass = "http://127.0.0.1:8123/";
      extraConfig = ''
        proxy_set_header    Upgrade     $http_upgrade;
        proxy_set_header    Connection  "upgrade";
      '';
    };
  };

}
