{ config, pkgs, lib, ... }:
let
  stackName = "unifi";
in
{
  networking.firewall.allowedTCPPorts = [8080];
  networking.firewall.allowedUDPPorts = [3478 10001];

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
      proxyPass = "https://127.0.0.1:8443/";
      proxyWebsockets = true;
      extraConfig = ''
    	proxy_set_header  X-Real-IP $remote_addr;
    	proxy_set_header  X-Forwarded-For $remote_addr;
    	proxy_set_header  X-Forwarded-Host $remote_addr;
    	real_ip_header X-Real-IP;
    	real_ip_recursive on;
      '';
    };
  };
}
