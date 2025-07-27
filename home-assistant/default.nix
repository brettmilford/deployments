{ config, pkgs, lib, ... }:

with lib;

let
  stackName = "home-assistant";
  cfg = config.services.deployments;
in
{
  config = mkIf cfg.homeAssistant.enable {
    networking.firewall.allowedTCPPorts = [1400 1443 21063 21064 21065];
    networking.firewall.allowedUDPPorts = [5353 1900];

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

    age.secrets."cf_origin_cert" = {
      file = ../../secrets/cf_origin_cert.pem.age;
      mode = "770";
      owner = "nginx";
      group = "nginx";
    };

    age.secrets."cf_origin_key" = {
      file = ../../secrets/cf_origin_key.pem.age;
      mode = "770";
      owner = "nginx";
      group = "nginx";
    };

    environment.systemPackages = [ pkgs.cloudflared ];

    age.secrets.cfdCredentialsFile = {
      file = ../../secrets/cfd_tunnel_config.json.age;
      owner = "cloudflared";
      group = "cloudflared";
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

    services.nginx.virtualHosts."${stackName}.internal"= {
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

    services.nginx.commonHttpConfig = let
      realIpsFromList = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
      fileToList = x: lib.strings.splitString "\n" (builtins.readFile x);
      cfipv4 = fileToList (pkgs.fetchurl {
        url = "https://www.cloudflare.com/ips-v4";
        sha256 = "0ywy9sg7spafi3gm9q5wb59lbiq0swvf0q3iazl0maq1pj1nsb7h";
      });
      cfipv6 = fileToList (pkgs.fetchurl {
        url = "https://www.cloudflare.com/ips-v6";
        sha256 = "1ad09hijignj6zlqvdjxv7rjj8567z357zfavv201b9vx3ikk7cy";
      });
    in ''
      ${realIpsFromList cfipv4}
      ${realIpsFromList cfipv6}
      real_ip_header CF-Connecting-IP;
    '';

    age.secrets."cfApiKey".file = ../../secrets/cfApiKey.age;
    services.fail2ban = let
      cfEmail = "brettmilford@gmail.com";
      cfApiKey = config.age.secrets."cfApiKey".path;
    in {
      enable = true;
      extraPackages = [pkgs.curl pkgs.ipset];
      banaction = "iptables-ipset-proto6-allports";
      ignoreIP = [
        "172.22.70.58/16"
      ];

      jails.nginx-noagent = ''
        enabled  = true
        port     = http,https
        filter   = nginx-noagent
        backend  = auto
        maxretry = 1
        logpath  = %(nginx_access_log)s
        action   = cloudflare[cfuser="${cfEmail}", cftoken="${cfApiKey}"]
                   iptables-multiport[port="http,https"]
      '';
    };

    environment.etc."fail2ban/filter.d/nginx-noagent.conf".text = ''
      [Definition]

      failregex = ^<HOST> -.*"-" "-"$

      ignoreregex =
    '';

    services.nginx.virtualHosts."${stackName}-z2m.internal"= {
      enableACME = true;
      forceSSL = true;
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
