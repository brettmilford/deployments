{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  stackName = "home-assistant";
  cfg = config.services.deployments;
in
{
  config = mkIf cfg.homeAssistant.enable {
    networking.firewall.allowedTCPPorts = [
      1400
      1443
      21063
      21064
      21065
    ];
    networking.firewall.allowedUDPPorts = [
      5353
      1900
    ];

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

    environment.systemPackages = [ pkgs.cloudflared ];

    age.secrets.cfdCredentialsFile = {
      file = ../../secrets/cfd_tunnel_config.json.age;
    };

    services.cloudflared = {
      enable = true;
      tunnels = {
        "c152d57e-441c-4cea-a193-0d493116ccac" = {
          credentialsFile = config.age.secrets.cfdCredentialsFile.path;
          default = "http_status:404";
          ingress = {
            "${stackName}.cirriform.au" = {
              service = "https://${stackName}.internal";
              originRequest = {
                noTLSVerify = true;
              };
            };
          };
        };
      };
    };

    services.nginx.virtualHosts."${stackName}.internal" = {
      enableACME = false;
      serverAliases = [ "home-assistant.cirriform.au" ];
      sslCertificate = config.age.secrets."cf_origin_cert".path;
      sslCertificateKey = config.age.secrets."cf_origin_key".path;
      addSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8123/";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };

    services.nginx.virtualHosts."${stackName}-z2m.internal" = {
      enableACME = false;
      serverAliases = [ "home-assistant-z2m.cirriform.au" ];
      sslCertificate = config.age.secrets."cf_origin_cert".path;
      sslCertificateKey = config.age.secrets."cf_origin_key".path;
      addSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8081/";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };
  };
}
