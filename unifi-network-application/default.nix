{
  config,
  lib,
  pkgs,
  ...
}: {

  networking.firewall.allowedTCPPorts = [8080 9200];
  networking.firewall.allowedUDPPorts = [3478 10001 1900];

  services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
	unifi = { enableACME = true;
	forceSSL = true;
	serverName = "unifi";
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
