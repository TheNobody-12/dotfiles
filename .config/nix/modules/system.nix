{ config, pkgs, lib, self, ... }:

let
  username = "gravity";

  dnscryptConfig = pkgs.writeText "dnscrypt-proxy2.toml" ''
    listen_addresses = ['127.0.0.1:5353']
    max_clients = 250
    ipv4_servers = true
    ipv6_servers = true
    dnscrypt_servers = true
    doh_servers = true
    require_dnssec = true
    require_nolog = true

    [sources.public-resolvers]
    urls = ['https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md', 'https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md']
    cache_file = 'public-resolvers.md'
    minisign_key = 'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3'
    refresh_delay = 72
  '';
in
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.settings = {
    experimental-features = "nix-command flakes";
    max-jobs = "auto";
    cores = 0;
    builders-use-substitutes = true;
    keep-outputs = true;
    keep-derivations = true;
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  nix.optimise.automatic = true;

  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 3; Minute = 0; };
    options = "--delete-older-than 14d";
  };

  nix.enable = true;

  system.stateVersion = 6;
  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.primaryUser = username;
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  fonts.packages = [ ];

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    ripgrep
    fd
    fzf
    zoxide
    stow
    ncdu
    mkalias
    dnscrypt-proxy
  ];

  # dnscrypt-proxy2 on port 5353 for apps that support custom DNS
  launchd.user.agents.dnscrypt-proxy = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.dnscrypt-proxy}/bin/dnscrypt-proxy"
        "-config"
        "${dnscryptConfig}"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardErrorPath = "/tmp/dnscrypt-proxy2.log";
      StandardOutPath = "/tmp/dnscrypt-proxy2.log";
    };
  };

  system.activationScripts.applications.text =
    let
      env = pkgs.buildEnv {
        name = "system-applications";
        paths = config.environment.systemPackages;
        pathsToLink = [ "/Applications" ];
      };
    in
    lib.mkForce ''
      echo "Setting up /Applications/Nix Apps..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
        app_name=$(basename "$src")
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
    '';

  system.activationScripts.dns.text = ''
    echo "Setting Mullvad DNS on all network services..." >&2
    for service in $(/usr/sbin/networksetup -listallnetworkservices | /usr/bin/tail -n +2); do
      /usr/sbin/networksetup -setdnsservers "$service" 194.242.2.2 2a07:e340::2 2>/dev/null || true
      /usr/sbin/networksetup -setsearchdomains "$service" empty 2>/dev/null || true
    done
  '';
}
