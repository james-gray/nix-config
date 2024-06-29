{ config, pkgs, ... }:

{
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
              conf = "vim /etc/nixos/configuration.nix";
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
}
