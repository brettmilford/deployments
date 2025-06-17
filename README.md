# NixOS Container Deployments

This directory contains container-based service deployments that can be enabled in your NixOS configurations. 

## Available Services

- **Elasticsearch**: Elasticsearch service with Kibana
- **Home Assistant**: Smart home automation platform with MQTT broker and Zigbee2MQTT
- **Llama.cpp**: Local large language model inference server
- **OctoPrint**: 3D printer management interface
- **UniFi**: Ubiquiti UniFi Controller for network management

## How to Use

In your NixOS configuration, enable the deployment module and specify which services you want to run:

```nix
{ config, pkgs, ... }:

{
  imports = [
    # Import the deployments module
    /path/to/deployments
  ];

  # Enable the deployments module with selected services
  services.deployments = {
    enable = true;
    
    # Optional: Override defaults
    dataDir = "/path/to/deployments";  # Default: /etc/nixos/deployments
    enableNginxProxy = true;  # Whether to enable Nginx reverse proxy
    baseDomain = "internal";  # Base domain for service URLs
    
    # Enable specific services
    elasticsearch.enable = true;
    homeAssistant.enable = true;
    llamaCpp.enable = true;
    octoprint.enable = true;
    unifi.enable = true;
  };
}
```

## Flake Integration

For a flake-based NixOS configuration, include the module in your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # ... other inputs
  };
  
  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # ... other modules
        
        # Import deployments module
        ./deployments
        
        # Configuration
        {
          services.deployments = {
            enable = true;
            elasticsearch.enable = true;
            # ... other services
          };
        }
      ];
    };
  };
}
```

## Service Access

When the services are enabled with the default Nginx proxy configuration:

- Elasticsearch: https://elasticsearch.internal
- Home Assistant: https://home-assistant.internal
- Zigbee2MQTT: https://home-assistant-z2m.internal
- Llama.cpp: https://llama.cpp.internal
- OctoPrint: https://octoprint.internal
- UniFi Controller: https://unifi.internal

## Directory Structure

Each service has its own directory containing:

- `default.nix`: The NixOS module for the service
- `compose.yaml`: The Podman/Docker Compose configuration
- Service-specific config files and directories

## Adding New Services

To add a new service:

1. Create a new directory for your service
2. Add a `compose.yaml` file with the container configuration
3. Create a `default.nix` file following the pattern of existing services
4. Update the main `default.nix` to include your new service

## Customizing Services

Each service can be customized by editing its compose file. Remember to rebuild your system after making changes.
