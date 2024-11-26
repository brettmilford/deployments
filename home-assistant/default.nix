{

  networking.firewall.allowedUDPPorts = [5353];
  networking.firewall.allowedTCPPorts = [1400 1443 21063 21064 21065];
  services.nginx = {
    enable =  true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  services.nginx.virtualHosts."ha"= {
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
