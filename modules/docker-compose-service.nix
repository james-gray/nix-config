{ pkgs, lib }:

# Helper function to create a systemd service for docker-compose
# This eliminates boilerplate for the 30+ docker-compose services

{
  # Create a standard docker-compose service
  # Usage: mkDockerComposeService "myservice" ./myservice/docker-compose.yml
  mkDockerComposeService = name: composeFile:
    {
      enable = true;
      serviceConfig = {
        ExecStart = ''
          ${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} up
        '';
        ExecStop = ''
          ${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} stop
        '';
      };
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "default.target" ];
    };

  # Create a docker-compose service that runs in detached mode
  # Usage: mkDockerComposeServiceDetached "myservice" ./myservice/docker-compose.yml
  mkDockerComposeServiceDetached = name: composeFile:
    {
      enable = true;
      serviceConfig = {
        ExecStart = ''
          ${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} up -d
        '';
        ExecStop = ''
          ${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} stop
        '';
        RemainAfterExit = true;
      };
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "default.target" ];
    };

  # Create a docker-compose oneshot service
  # Usage: mkDockerComposeServiceOneshot "myservice" ./myservice/docker-compose.yml
  mkDockerComposeServiceOneshot = name: composeFile:
    {
      enable = true;
      serviceConfig = {
        ExecStart = ''
          ${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} up -d
        '';
        ExecStop = ''
          ${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} stop
        '';
        RemainAfterExit = true;
        Type = "oneshot";
      };
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "default.target" ];
    };
}
