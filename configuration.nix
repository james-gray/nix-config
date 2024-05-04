# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Include Home Manager configuration
      <home-manager/nixos>
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "hal9000"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.extraConfig = ''
    [connection]
    wifi.wake-on-wlan = magic
    ethernet.wake-on-lan = magic
  '';

  # Set your time zone.
  time.timeZone = "America/Vancouver";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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

  services.tailscale.enable = true;

  # Enable OpenRGB
  services.hardware.openrgb.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jamesgray = with pkgs; {
    isNormalUser = true;
    description = "James Gray";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = zsh;
  };
  users.motd = "I'm sorry, Dave, I'm afraid I can't do that.";
  programs.zsh.enable = true;
  programs.zsh.interactiveShellInit = ''
    neofetch
    export GIT_EDITOR="`which vim`"
    export EDITOR="`which vim`"
  '';

  # Setup home-manager user config
  home-manager.users.jamesgray = { pkgs, ... }: {
    home.stateVersion = "23.11";
    home.packages = with pkgs; [
      firefox
      neofetch
      konsole
      powertop
    ];
    programs.vim = {
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

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableAutosuggestions = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        ls = "ls -lah";
        update = "sudo nixos-rebuild switch";
        conf = "vim ~/code/nix-config/configuration.nix";
        ncf = "cd ~/code/nix-config";
        ga = "git add";
        gc = "git commit";
        gap = "git add -p";
        gp = "git push";
        gl = "git log";
        gs = "git status";
        gd = "git diff";
        gdo = "git diff origin/master";
        gdc = "git diff --cached";
        gcm = "git commit -m";
        gcam = "git commit -am";
        gbr = "git branch";
        gco = "git checkout";
        gcob = "git checkout -b";
        gra = "git remote add";
        grr = "git remote rm";
        gpu = "git pull";
        gcl = "git clone";
        gf = "git fetch";
        gg = "git grep -i";
        gmg = "git merge";
        grb = "git rebase";
        gpop = "git reset HEAD^";
        gmf = "git merge --ff-only";
        grst = "git reset";
        gb = "git blame";
        gst = "git stash";
        gsta = "git stash apply";
      };
      history.size = 10000;
      history.path = "/home/jamesgray/.zsh_history";

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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    neovim
    wget
    git
    lm_sensors
    beep
    htop
    ethtool
    smartmontools
  ];
  environment.variables.EDITOR = "vim";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings = {
    UseDns = false;
  };

  programs.ssh.startAgent = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.interfaces.wlo1.wakeOnLan = {
    enable = true;
  };
  networking.interfaces.eno2.wakeOnLan = {
    enable = true;
  };

  # Disable sleep! Servers can sleep when they're dead!
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
