{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # Include Home Manager configuration
    <home-manager/nixos>
    # Secrets management
    <agenix/modules/age.nix>
  ];

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = false;
      extraPools = [ "tank9000" "backup9000" ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      (pkgs.callPackage <agenix/pkgs/agenix.nix> { }) # Agenix CLI
      beep
      docker
      docker-compose
      ethtool
      exiftool
      fastfetch
      git
      htop
      lm_sensors
      neovim
      netdata
      nixfmt
      sanoid
      smartmontools
      vim
      wget
      unzip
    ];
    variables = {
      EDITOR = "vim";
      GIT_EDITOR = "vim";
    };
  };

  programs = {
    ssh = { startAgent = true; };
    zsh = {
      enable = true;
      interactiveShellInit = ''
        fastfetch
        export GIT_EDITOR="`which vim`"
        export EDITOR="`which vim`"
      '';
    };
  };

  # Service configuration
  services = {
    avahi = {
      extraServiceFiles = {
        smb = ''
          <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
           <name replace-wildcards="yes">%h</name>
           <service>
            <type>_adisk._tcp</type>
            <txt-record>sys=waMa=0,adVF=0x100</txt-record>
            <txt-record>dk0=adVN=Time Capsule,adVF=0x82</txt-record>
           </service>
           <service>
            <type>_smb._tcp</type>
            <port>445</port>
           </service>
          </service-group>
        '';
      };
    };
    hardware = { openrgb.enable = true; };

    netdata = {
      enable = true;

      config = {
        global = {
          # update interval
          "update every" = 15;
        };
        ml = {
          "enabled" = "no";
        };
      };
    };

    # Note that to enable macos mounts of ZFS datasets over NFS within a Tailscale tailnet, must set as follows (e.g. for dataset tank9000/example):
    # $ sudo zfs set sharenfs="rw=100.0.0.0/8,all_squash,anonuid=1000,anongid=100,insecure" tank9000/example
    # This enables hosts on the tailnet to mount the share r/w, and files created will be owned by jamesgray:users.
    # TODO: See about reassigning client ips to tighten up the tailnet subnet mask
    nfs.server = { enable = true; };

    openssh = {
      enable = true;
      settings = { UseDns = false; };
    };

    samba = {
      enable = true;
      securityType = "user";
      extraConfig = ''
        workgroup = WORKGROUP
        server string = smbnix
        netbios name = smbnix
        server role = standalone server
        dns proxy = no
        ea support = yes

        pam password change = yes
        map to guest = bad user
        usershare allow guests = yes
        create mask = 0664
        force create mode = 0664
        directory mask = 0775
        force directory mode = 0775
        follow symlinks = yes
        load printers = no
        printing = bsd
        printcap name = /dev/null
        disable spoolss = yes
        strict locking = no
        aio read size = 0
        aio write size = 0
        vfs objects = acl_xattr catia fruit streams_xattr
        inherit permissions = yes

        # Security
        client ipc max protocol = SMB3
        client ipc min protocol = SMB2
        client max protocol = SMB3
        client min protocol = SMB2
        server max protocol = SMB3
        server min protocol = SMB2

        # Time Machine
        fruit:aapl = yes
        fruit:delete_empty_adfiles = yes
        fruit:metadata = stream
        fruit:model = MacSamba
        fruit:nfs_aces = no
        fruit:posix_rename = yes
        fruit:time machine = yes
        fruit:veto_appledouble = no
        fruit:wipe_intentionally_left_blank_rfork = yes
        spotlight = no
      '';
      shares = {
        "Time Capsule" = {
          path = "/tank9000/timemachine";
          browseable = "yes";
          "read only" = "no";
          "inherit acls" = "yes";

          "fruit:time machine" = "yes";
          "fruit:time machine max size" = "512G";
          "write list" = "timemachine";
          "create mask" = "0600";
          "directory mask" = "0700";
          "case sensitive" = "true";
          "default case" = "lower";
          "preserve case" = "yes";
          "short preserve case" = "yes";

          "force user" = "timemachine";
          "valid users" = "timemachine";
        };
      };
    };

    # Sanoid ZFS dataset snapshotting
    sanoid = {
      enable = true;
      datasets.tank9000 = {
        autoprune = true;
        autosnap = true;
        recursive = true;
        hourly = 24;
        daily = 30;
        monthly = 3;
      };
    };

    # Syncoid ZFS dataset replication
    syncoid = {
      enable = true;
      user = "syncoid";
      localSourceAllow = [
        "compression"
        "create"
        "mount"
        "mountpoint"
        "receive"
        "rollback"
        "bookmark"
        "hold"
        "send"
        "snapshot"
        "destroy"
      ];
      localTargetAllow = [
        "compression"
        "create"
        "mount"
        "mountpoint"
        "receive"
        "rollback"
        "bookmark"
        "hold"
        "send"
        "snapshot"
        "destroy"
      ];
      commonArgs = [ "--no-privilege-elevation" "--recursive" ];
      commands."tank9000" = {
        source = "tank9000/ds1";
        target = "backup9000/ds1";
      };
      commands."timemachine" = {
        source = "tank9000/timemachine";
        target = "backup9000/timemachine";
      };
    };

    # Tailscale mesh network
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };

    zfs = { autoScrub.enable = true; };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  networking = {
    hostName = "hal9000";
    hostId = "16cff501";
    firewall = {
      enable = true;
      allowPing = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedTCPPorts = [ 22 2049 137 138 139 445 ];
      allowedUDPPorts =
        [ 22 2049 137 138 139 445 config.services.tailscale.port ];
    };
    interfaces = {
      wlo1 = { wakeOnLan = { enable = true; }; };
      eno2 = { wakeOnLan = { enable = true; }; };
    };
    networkmanager = {
      enable = true;
      extraConfig = ''
        [connection]
        wifi.wake-on-wlan = magic
        ethernet.wake-on-lan = magic
      '';
    };
  };

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs = { config = { allowUnfree = true; }; };

  systemd = {
    services = {
      "NetworkManager-wait-online" = { enable = false; };
      dashy = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${./dashy/docker-compose.yml} up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${./dashy/docker-compose.yml} stop
          '';
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      jellyfin = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${./jellyfin/docker-compose.yml} up
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${./jellyfin/docker-compose.yml} stop
          '';
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
      nextcloud = {
        enable = true;
        serviceConfig = {
          ExecStart = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${./nextcloud/docker-compose.yml} up -d
          '';
          ExecStop = ''
            ${pkgs.docker-compose}/bin/docker-compose -f ${./nextcloud/docker-compose.yml} stop
          '';
          RemainAfterExit = true;
          Type = "oneshot";
        };
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        wantedBy = [ "default.target" ];
      };
    };
    # Disable sleep! Servers can sleep when they're dead!
    sleep = {
      extraConfig = ''
        AllowSuspend=no
        AllowHibernation=no
        AllowHybridSleep=no
        AllowSuspendThenHibernate=no
      '';
    };
  };

  time = { timeZone = "America/Vancouver"; };

  users = {
    motd = "I'm sorry, Dave, I'm afraid I can't do that.";
    users = {
      jamesgray = with pkgs; {
        description = "James Gray";
        extraGroups = [ "docker" "networkmanager" "wheel" ];
        isNormalUser = true;
        shell = zsh;
      };
      "james.gray" = with pkgs; {
        description = "James Gray (macos)";
        extraGroups = [ "macos" ];
        isNormalUser = true;
        group = "james.gray";
        shell = bash;
      };
      syncoid = with pkgs; {
        description = "Syncoid User";
        extraGroups = [ "wheel" ];
        group = "syncoid";
        shell = bash;
      };
      timemachine = with pkgs; {
        description = "Time Machine user";
        group = "timemachine";
        isNormalUser = true;
        shell = bash;
      };
      www-data = with pkgs; {
        description = "www-data";
        group = "www-data";
        isSystemUser = true;
        uid = 33;
      };
    };
    groups = {
      syncoid = { };
      timemachine = { };
      "james.gray" = { };
      macos = { gid = 1005; };
      www-data = { gid = 33; };
    };
  };

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "btrfs";
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
    oci-containers = {
      backend = "docker";
      containers = { };
    };
  };

  # Setup home-manager user config
  home-manager = {
    users = {
      jamesgray = { pkgs, ... }: {
        home = {
          stateVersion = "23.11";
          packages = with pkgs; [ powertop ];
        };
        programs = {
          vim = {
            enable = true;
            plugins = with pkgs.vimPlugins; [
              nerdtree
              vim-gitgutter
              vim-gitbranch
            ];
            settings = {
              background = "dark";
              expandtab = true;
              history = 1000;
              ignorecase = true;
              mouse = "a";
              mousehide = true;
              number = true;
              shiftwidth = 4;
              tabstop = 4;
            };
            # Warning: decades-old and dubiously-understood .vimrc contents below
            extraConfig = ''
              set nocompatible
              filetype plugin indent on
              set nowrap
              set cindent
              set autoindent
              set smartindent
              set softtabstop=4
              set nojoinspaces
              set splitright
              set splitbelow
              set pastetoggle=<F12>

              " NerdTree
              map <S-n> <plug>NERDTreeTabsToggle<CR>
              map <leader>e :NERDTreeFind<CR>
              nmap <leader>nt :NERDTreeFind<CR>

              let NERDTreeShowBookmarks=1
              let NERDTreeIgnore=['\.pyc', '\~$', '\.swo$', '\.swp$', '\.git', '\.hg', '\.svn', '\.bzr']
              let NERDTreeChDirMode=0
              let NERDTreeQuitOnOpen=1
              let NERDTreeMouseMode=2
              let NERDTreeShowHidden=1
              let NERDTreeKeepTreeInNewTab=1
              let g:nerdtree_tabs_open_on_gui_startup=0

              " Strip whitespace {
              function! StripTrailingWhitespace()
                  " Preparation: save last search, and cursor position.
                  let _s=@/
                  let l = line(".")
                  let c = col(".")
                  " do the business:
                  %s/\s\+$//e
                  " clean up: restore previous search history, and cursor position
                  let @/=_s
                  call cursor(l, c)
              endfunction

              let mapleader=","

              map tn :tabnext<cr>
              map tp :tabprev<cr>
              map <C-t> :tabnew<cr>
              map td :tabnew %:p:h<cr>

              " some mappings for split windows
              map wv :vsplit<cr>
              map wh :split<cr>
              map wn <C-w><C-w>
              map <Tab> :vsplit %:p:h<cr>
              map <S-Tab> :split %:p:h<cr>
              map ` <C-w>

              map <ScrollWheelUp> <C-Y>
              map <ScrollWheelDown> <C-E>


              " default text encoding (needed for the tab/trail chars)
              set encoding=utf-8

              " use incremental searching
              set incsearch

              " Split pane navigation
              nnoremap <C-J> <C-W><C-J>
              nnoremap <C-K> <C-W><C-K>
              nnoremap <C-L> <C-W><C-L>
              nnoremap <C-H> <C-W><C-H>


              " highlight all search items
              set hlsearch

              " tab/trail chars
              set list listchars=tab:»\ ,trail:·

              " enable line wrapping when using backspace/delete
              set backspace=indent,eol,start

              " always show the cursor position
              set ruler

              " Use unnamed clipboard
              set clipboard=unnamed

              " show what you are typing as a command
              set showcmd

              set colorcolumn=80
              highlight ColorColumn ctermbg=darkgrey guibg=darkgrey

              autocmd BufRead,BufNewFile *.nix set tabstop=2 softtabstop=2 shiftwidth=2

              set matchpairs=(:),{:},[:],<:>

              " Persistent undo
              set undofile                    " Save undo's after file closes
              set undodir=$HOME/.vim/undo " where to save undo histories
              set undolevels=1000             " How many undos
              set undoreload=10000            " number of lines to save for undo

              " Configure gitgutter
              let g:gitgutter_override_sign_column_highlight = 0
              highlight SignColumn ctermbg=235   " terminal Vim
              highlight GitGutterAdd ctermbg=235
              highlight GitGutterChange ctermbg=235
              highlight GitGutterDelete ctermbg=235
              highlight GitGutterChangeDelete ctermbg=235

              syntax on
            '';
          };
          zsh = {
            enable = true;
            enableCompletion = true;
            enableAutosuggestions = true;
            syntaxHighlighting.enable = true;

            shellAliases = {
              conf = "vim ~/code/nix-config/configuration.nix";
              ga = "git add";
              gap = "git add -p";
              gb = "git blame";
              gbr = "git branch";
              gc = "git commit";
              gcam = "git commit -am";
              gcl = "git clone";
              gcm = "git commit -m";
              gco = "git checkout";
              gcob = "git checkout -b";
              gd = "git diff";
              gdc = "git diff --cached";
              gdo = "git diff origin/master";
              gf = "git fetch";
              gg = "git grep -i";
              gl = "git log";
              gmf = "git merge --ff-only";
              gmg = "git merge";
              gp = "git push";
              gpop = "git reset HEAD^";
              gpu = "git pull";
              gra = "git remote add";
              grb = "git rebase";
              grr = "git remote rm";
              grst = "git reset";
              gs = "git status";
              gst = "git stash";
              gsta = "git stash apply";
              ls = "ls -lah";
              ncf = "cd ~/code/nix-config";
              rebuild = "sudo nixos-rebuild switch";
            };

            history = {
              size = 10000;
              path = "/home/jamesgray/.zsh_history";
            };

            plugins = [
              {
                name = "powerlevel10k";
                src = pkgs.zsh-powerlevel10k;
                file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
              }
              {
                name = "powerlevel10k-config";
                src = ./p10k-config;
                file = "p10k.zsh";
              }
            ];

            oh-my-zsh = {
              enable = true;
              plugins = [ "git" ];
            };
          };
        };
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
