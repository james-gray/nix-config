{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Include Home Manager configuration
      <home-manager/nixos>
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
      beep
      ethtool
      git
      htop
      lm_sensors
      neofetch
      neovim
      sanoid
      smartmontools
      vim
      wget
    ];
    variables = {
      EDITOR = "vim";
      GIT_EDITOR = "vim";
    };
  };

  programs = {
    ssh = {
      startAgent = true;
    };
    zsh = {
      enable = true;
      interactiveShellInit = ''
        neofetch
        export GIT_EDITOR="`which vim`"
        export EDITOR="`which vim`"
      '';
    };
  };

  # Service configuration
  services = {
    hardware = {
      openrgb.enable = true;
    };

    # Note that to enable macos mounts of ZFS datasets over NFS within a Tailscale tailnet, must set as follows (e.g. for dataset tank9000/example):
    # $ sudo zfs set sharenfs="rw=100.0.0.0/8,all_squash,anonuid=1000,anongid=100,insecure" tank9000/example
    # This enables hosts on the tailnet to mount the share r/w, and files created will be owned by jamesgray:users.
    # TODO: See about reassigning client ips to tighten up the tailnet subnet mask
    nfs.server = {
      enable = true;
    };

    openssh = {
      enable = true;
      settings = {
        UseDns = false;
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
      commonArgs = [
        "--no-privilege-elevation" "--recursive"
      ];
      commands."tank9000" = {
        source = "tank9000/ds1";
        target = "backup9000/ds1";
      };
    };

    # Tailscale mesh network
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };

    zfs = {
      autoScrub.enable = true;
    };
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
      trustedInterfaces = [ "tailscale0" ];
      allowedTCPPorts = [ 22 2049 ];
      allowedUDPPorts = [ 22 2049 config.services.tailscale.port ];
    };
    interfaces = {
      wlo1 = {
        wakeOnLan = {
          enable = true;
        };
      };
      eno2 = {
        wakeOnLan = {
          enable = true;
        };
      };
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

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  # Disable sleep! Servers can sleep when they're dead!
  systemd = {
    sleep = {
      extraConfig = ''
        AllowSuspend=no
        AllowHibernation=no
        AllowHybridSleep=no
        AllowSuspendThenHibernate=no
      '';
    };
  };

  time = {
    timeZone = "America/Vancouver";
  };

  users = {
    motd = "I'm sorry, Dave, I'm afraid I can't do that.";
    users = {
      jamesgray = with pkgs; {
        description = "James Gray";
        extraGroups = [ "networkmanager" "wheel" ];
        isNormalUser = true;
        shell = zsh;
      };
      syncoid = with pkgs; {
        description = "Syncoid User";
        extraGroups = [ "wheel" ];
        group = "syncoid";
        shell = bash;
      };
    };
    groups = {
      syncoid = {};
    };
  };

  # Setup home-manager user config
  home-manager.users.jamesgray = { pkgs, ... }: {
    home = {
      stateVersion = "23.11";
      packages = with pkgs; [
        powertop
      ];
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
          plugins = [
            "git"
          ];
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
