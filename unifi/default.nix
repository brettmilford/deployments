{ config, pkgs, lib, ... }:

with lib;

let
  stackName = "unifi";
  cfg = config.services.deployments;
in
{
  config = mkIf cfg.unifi.enable {
    networking.firewall.allowedTCPPorts = [8080];
    networking.firewall.allowedUDPPorts = [3478 10001];

    systemd.services."podman-${stackName}" = {
      description = "Podman Compose Stack Service for ${stackName}";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        Environment = "PATH=${pkgs.podman}/bin:${pkgs.podman-compose}/bin:/run/wrappers/bin:/usr/bin:/bin";
        Type = "simple";
        ExecStart = "${pkgs.podman-compose}/bin/podman-compose -f ${cfg.dataDir}/${stackName}/compose.yaml up";
        ExecStop = "${pkgs.podman-compose}/bin/podman-compose -f ${cfg.dataDir}/${stackName}/compose.yaml down";
        Restart = "always";
        User = "root";
        WorkingDirectory = "${cfg.dataDir}/${stackName}";
      };

      wantedBy = [ "multi-user.target" ];
    };
    
    # Only enable nginx if it's already enabled in the system
    services.nginx = mkIf config.services.nginx.enable {
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts."${stackName}.internal"= {
        enableACME = true;
        addSSL = true;
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
    };
  };
}
