{ pkgs, lib, config, inputs, ... }:
let
  repos = [
    "brubsby/nixpkgs"
    "oeis/oeisdata"
  ];

  cheatsheet = pkgs.writeShellScriptBin "cheatsheet" ''
    SHEET_FILE="$HOME/.cheatsheet.txt"
    if [ ! -f "$SHEET_FILE" ]; then
      touch "$SHEET_FILE"
    fi

    if [ "$1" = "edit" ]; then
      exec ''${EDITOR:-vim} "$SHEET_FILE"
    elif [ "$1" = "add" ]; then
      shift
      echo "$*" >> "$SHEET_FILE"
    else
      if [ -s "$SHEET_FILE" ]; then
        cat "$SHEET_FILE"
      else
        echo "Cheatsheet is empty. Use 'cheatsheet add <text>' or 'cheatsheet edit' to add content."
      fi
    fi
  '';
in
{
  home.username = "tbusby";
  home.homeDirectory = "/home/tbusby";
  home.packages = [
    pkgs.todo-txt-cli
    pkgs.snapshot
    cheatsheet
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      todo = "todo.sh";
      clip = "xclip -sel clipboard";
      cliplast = "_c(){ fc -ln -\${1:-1} -\${1:-1} | head -c -1 | clip; unset -f _c; }; _c";
      nixos-switch = "sudo nixos-rebuild switch --flake /etc/nixos#puter";
      nixos-update = "sudo nix flake update --flake /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#puter";
      nixos-update-local = "sudo nix flake update brubsby-nixpkgs-local --flake /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#puter";
      nixos-rollback = "sudo nixos-rebuild switch --rollback";
      home-switch = "home-manager switch --flake /etc/nixos#tbusby";
      nixos-config = "$EDITOR /home/tbusby/Repos/nixos-config/configuration.nix";
      home-config = "$EDITOR /home/tbusby/Repos/nixos-config/home.nix";
      flake-config = "$EDITOR /home/tbusby/Repos/nixos-config/flake.nix";
      beancount = "cd ~/Dropbox/Finances/Beancount && ./beancount_reference.sh";
      gs = "git status";
      gsv = "git status -v";
      gsvv = "git status -v -v";
      gl = "git log";
      gd = "git diff";
      ga = "git add";
      gc = "git commit";
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    initContent = ''
      # Powerlevel10k config
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      
      export GITHUB_TOKEN="$(cat /run/secrets/github_token)"
      export UV_PUBLISH_TOKEN="$(cat /run/secrets/pypi_token)"
      export DISCORDO_TOKEN="$(cat /run/secrets/discord_token)"
      export HUCKLEBERRY_EMAIL="$(cat /run/secrets/huckleberry_email)"
      export HUCKLEBERRY_PASSWORD="$(cat /run/secrets/huckleberry_password)"
      export LEETCODE_CSRF="$(cat /run/secrets/leetcode_credentials/csrf_token)"
      export LEETCODE_SESSION="$(cat /run/secrets/leetcode_credentials/session_key)"
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:$LD_LIBRARY_PATH"
      export PATH="$HOME/.cargo/bin:$PATH"

      # FZF Configuration
      export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

      # Rebind fzf file widget to Ctrl+f (overrides forward-char)
      # and unbind Ctrl+t (Zellij conflict)
      bindkey '^f' fzf-file-widget
      bindkey -r '^t'

      ${builtins.readFile ./sink.zsh}
    '';
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip
      rustaceanvim
      typescript-tools-nvim
      nvim-treesitter.withAllGrammars
      plenary-nvim
      telescope-nvim
    ];
    extraLuaConfig = ''
      vim.opt.timeoutlen = 300
      vim.opt.ttimeoutlen = 100
      vim.opt.lazyredraw = true
      vim.opt.termguicolors = true
      vim.opt.scrolloff = 8

      local cmp = require('cmp')
      local luasnip = require('luasnip')

      -- Capabilities for cmp-nvim-lsp
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Telescope keybinds
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
      vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Telescope keymaps' })

      -- Diagnostic keybinds
      vim.keymap.set('n', 'gl', vim.diagnostic.open_float, { desc = 'Open diagnostic float' })
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic' })
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic' })

      -- Show diagnostics on hover automatically
      vim.api.nvim_create_autocmd("CursorHold", {
        callback = function()
          vim.diagnostic.open_float(nil, { focusable = false })
        end
      })
      vim.opt.updatetime = 300 -- Faster hover (default is 4000ms)

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
          { name = 'path' },
        })
      })

      -- rustaceanvim
      vim.g.rustaceanvim = {
        server = {
          on_attach = function(client, bufnr)
            local opts = { buffer = bufnr }
            vim.keymap.set('n', 'K', function() vim.cmd.RustLsp { 'hover', 'actions' } end, opts)
            vim.keymap.set('n', 'gp', function() vim.cmd.RustLsp('expandMacro') end, opts)
            vim.keymap.set('n', '<leader>a', function() vim.cmd.RustLsp('codeAction') end, opts)
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          end,
          default_settings = {
            ['rust-analyzer'] = {
              procMacro = {
                enable = true,
              },
              cargo = {
                buildScripts = {
                  enable = true,
                },
              },
              checkOnSave = true,
              check = {
                command = "clippy", -- More thorough than "check"
              },
              diagnostics = {
                debounceInterval = 200, -- Wait 200ms after typing stops before re-checking
              },
            },
          },
        },
      }

      -- Treesitter
      require('nvim-treesitter.config').setup({
        highlight = {
          enable = true,
        },
      })

      -- TypeScript/JavaScript LSP
      require("typescript-tools").setup({
        on_attach = function(client, bufnr)
          local opts = { buffer = bufnr }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', '<leader>a', vim.lsp.buf.code_action, opts)
        end,
      })

      -- LSP keybinds
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local opts = { buffer = args.buf }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        end,
      })

      -- ty LSP (Neovim 0.11+)
      vim.lsp.config('ty', {
        cmd = { "ty", "server" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", ".git", "requirements.txt" },
      })
      vim.lsp.enable('ty')

      -- Filetype associations
      vim.filetype.add({
        extension = {
          bean = 'beancount',
        },
      })

      -- Beancount LSP (Neovim 0.11+)
      vim.lsp.config('beancount', {
        cmd = { "beancount-language-server" },
        filetypes = { "beancount", "bean" },
        root_markers = { "main.beancount", "main.bean", ".git" },
        init_options = {
          journal_file = "/home/tbusby/Dropbox/Finances/Beancount/main.bean",
          python3_path = "/run/current-system/sw/bin/python3",
        },
        capabilities = capabilities,
      })
      vim.lsp.enable('beancount')
    '';
  };

  home.file.".p10k.zsh".source = ./p10k.zsh;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "basement" = {
        hostname = "bub-ucs240m5";
        user = "tbusby";
      };
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "brubsby";
        email = "brubsbybrubsby@gmail.com";
      };
      init = {
        defaultBranch = "main";
      };
      push = {
        autoSetupRemote = true;
      };
      url = {
        "git@github.com:" = {
          insteadOf = "https://github.com/";
        };
      };
    };
  };

  programs.nixcord = {
    enable = true;
    discord.enable = true;
    vesktop.enable = true;
  };

  home.file.".todo/config".text =
    builtins.replaceStrings
      [
        "export TODO_DIR=\${HOME:-$USERPROFILE}"
        "# export TODOTXT_FINAL_FILTER='cat'"
        "#export TODO_ACTIONS_DIR=\"$HOME/.todo.actions.d\""
      ]
      [
        "export TODO_DIR=$HOME/Dropbox/todo"
        "export TODOTXT_FINAL_FILTER=\" $TODO_DIR/futureTask\""
        "export TODO_ACTIONS_DIR=\"$TODO_DIR/.todo.actions.d\""
      ]
      (builtins.readFile "${pkgs.todo-txt-cli}/etc/todo/config");

  home.activation.setupSpotifyCredentials = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f $HOME/.cache/spotify-player/credentials.json ]; then
      mkdir -p $HOME/.cache/spotify-player
      echo "{\"username\":\"$(cat /run/secrets/spotify_credentials/username)\",\"auth_type\":$(cat /run/secrets/spotify_credentials/auth_data),\"auth_data\":\"$(cat /run/secrets/spotify_credentials/auth_data)\"}" > $HOME/.cache/spotify-player/credentials.json
      chmod 600 $HOME/.cache/spotify-player/credentials.json
    fi
  '';

  home.activation.setupLeetcodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/.leetcode
    cat <<EOF > $HOME/.leetcode/leetcode.toml
[code]
lang = "python3"
editor = "${config.home.sessionVariables.EDITOR}"
comment_problem_desc = true
comment_leading = "#"
test = true

[cookies]
csrf = "\$(cat /run/secrets/leetcode_credentials/csrf_token)"
session = "\$(cat /run/secrets/leetcode_credentials/session_key)"
site = "leetcode.com"

[storage]
cache = 'Problems'
code = 'code'
root = '$HOME/.leetcode'
scripts = 'scripts'
EOF
    chmod 600 $HOME/.leetcode/leetcode.toml
  '';

  home.activation.cloneRepos = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.openssh}/bin:${pkgs.git-lfs}/bin:$PATH"
    mkdir -p $HOME/Repos
    ${builtins.concatStringsSep "\n" (
      map (
        repo:
        let
          name = builtins.elemAt (lib.splitString "/" repo) 1;
        in
        ''
          if [ ! -d "$HOME/Repos/${name}" ]; then
            $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/${repo}.git $HOME/Repos/${name}
          fi
        ''
      ) repos
    )}
  '';

  programs.spotify-player = {
    enable = true;
    settings = {
      enable_notify = false;
    };
  };

  programs.tealdeer = {
    enable = true;
    settings = {
      updates = {
        auto_update = true;
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.lazygit.enable = true;

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    # aggressiveResize = true; -- Disabled to prevent potential issues with multiple clients
    baseIndex = 1;
    escapeTime = 0;
  };

  programs.zellij = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      theme = "dracula";
      stacked_resize = false;
      copy_on_select = true;
      mirror_session = false;
      pane_frames = true;
      keybinds = {
        "shared_except \"locked\"" = {
          "bind \"Alt PageUp\"" = { GoToPreviousTab = [ ]; };
          "bind \"Alt PageDown\"" = { GoToNextTab = [ ]; };
          "unbind \"Ctrl q\"" = [];
        };
      };
    };
  };

  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "Termsyn";
        };
        size = 9.75;
      };

      window = {
        opacity = 1;
        padding = {
          x = 0;
          y = 0;
        };
      };
      # Make sure it works well with Zellij
      env = {
        TERM = "xterm-256color";
      };
      colors = {
        primary = {
          background = "#232627";
          foreground = "#fcfcfc";
          dim_foreground = "#eff0f1";
          bright_foreground = "#ffffff";
        };
        normal = {
          black = "#232627";
          red = "#ed1515";
          green = "#11d116";
          yellow = "#f67400";
          blue = "#1d99f3";
          magenta = "#9b59b6";
          cyan = "#1abc9c";
          white = "#fcfcfc";
        };
        bright = {
          black = "#7f8c8d";
          red = "#c0392b";
          green = "#1cdc9a";
          yellow = "#fdbc4b";
          blue = "#3daee9";
          magenta = "#8e44ad";
          cyan = "#16a085";
          white = "#ffffff";
        };
        dim = {
          black = "#31363b";
          red = "#783228";
          green = "#17a262";
          yellow = "#9e5c00";
          blue = "#1464a5";
          magenta = "#78498f";
          cyan = "#107a64";
          white = "#9da2a6";
        };
      };
    };
  };

  xdg.configFile."zellij/config.kdl".force = true;

  xdg.configFile."discordo/config.toml".text = ''
    [notifications.sound]
    enabled = false
  '';

  fonts.fontconfig.enable = true;
  xdg.configFile."fontconfig/conf.d/99-alacritty-fallback.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <alias>
        <family>Termsyn</family>
        <prefer>
          <family>Termsyn</family>
          <family>Cozette</family>
        </prefer>
      </alias>
    </fontconfig>
  '';

  programs.konsole = {
    enable = true;
    defaultProfile = "tbusby";
    profiles.tbusby = {
      colorScheme = "Breeze";
      font = {
	size = 9.75;
      };
    };
    extraConfig = {
      MainWindow = {
        MenuBar = "Disabled";
        ShowMainToolBar = false;
        ShowSessionToolBar = false;
      };
    };
  };

  # Daily NASA APOD Wallpaper
  systemd.user.services.daily-wallpaper = {
    Unit = {
      Description = "Fetch daily NASA APOD wallpaper";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "update-wallpaper" ''
        # Create cache dir
        mkdir -p $HOME/.cache/wallpapers
        
        # Get NASA API Key from SOPS
        if [ -f /run/secrets/nasa_token ]; then
          NASA_KEY=$(cat /run/secrets/nasa_token)
        else
          echo "NASA token secret not found. Skipping."
          exit 1
        fi
        
        # Query APOD API
        # --retry 5 helps if the network is still coming up
        if API_RESPONSE=$(${pkgs.curl}/bin/curl -s --retry 5 --retry-delay 5 --retry-all-errors --fail "https://api.nasa.gov/planetary/apod?api_key=$NASA_KEY"); then
          MEDIA_TYPE=$(echo "$API_RESPONSE" | ${pkgs.jq}/bin/jq -r '.media_type')
          if [ "$MEDIA_TYPE" = "image" ]; then
            IMG_URL=$(echo "$API_RESPONSE" | ${pkgs.jq}/bin/jq -r '.hdurl // .url')
          fi
        else
          echo "Failed to query APOD API after retries. Falling back to scraping website."
          HTML=$(${pkgs.curl}/bin/curl -s https://apod.nasa.gov/apod/astropix.html)
          IMG_PATH=$(echo "$HTML" | ${pkgs.gnugrep}/bin/grep -oP 'href="image/[^"]+\.(jpg|png|gif)"' | ${pkgs.coreutils}/bin/head -1 | ${pkgs.coreutils}/bin/cut -d'"' -f2)
          if [ -n "$IMG_PATH" ]; then
            IMG_URL="https://apod.nasa.gov/apod/$IMG_PATH"
            MEDIA_TYPE="image"
          else
            if echo "$HTML" | ${pkgs.gnugrep}/bin/grep -q "youtube\.com/embed"; then
              MEDIA_TYPE="video"
            else
              echo "Failed to parse APOD website. Skipping update."
              exit 0
            fi
          fi
        fi
        
        if [ "$MEDIA_TYPE" = "image" ]; then
          # Download
          if ${pkgs.curl}/bin/curl -L --retry 3 "$IMG_URL" -o /tmp/nasa_raw.jpg; then
            # Filename with date to bust Plasma cache
            WP_FILE="$HOME/.cache/wallpapers/nasa-$(date +%Y-%m-%d).jpg"
            
            # Clean up old nasa wallpapers
            rm -f $HOME/.cache/wallpapers/nasa-*.jpg
            
            # Resize to fill 1920x1080 (cropping if necessary)
            ${pkgs.imagemagick}/bin/magick /tmp/nasa_raw.jpg \
              -resize "1920x1080^" \
              -gravity center \
              -extent 1920x1080 \
              "$WP_FILE"
              
            # Update symlink
            ln -sf "$WP_FILE" $HOME/.cache/wallpapers/current.jpg
              
            # Apply to Plasma
            ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-wallpaperimage "$HOME/.cache/wallpapers/current.jpg"

            # Apply to Lock Screen
            ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$HOME/.cache/wallpapers/current.jpg"
          else
             echo "Failed to download image from $IMG_URL. Skipping."
             exit 0
          fi
        elif [ "$MEDIA_TYPE" = "null" ] || [ -z "$MEDIA_TYPE" ]; then
             echo "Failed to parse API response or media_type missing. Skipping. Response was: $API_RESPONSE"
             exit 0
        else
          echo "Today's APOD is not an image ($MEDIA_TYPE). Skipping update."
        fi
      ''}";
    };
  };

  systemd.user.timers.daily-wallpaper = {
    Unit.Description = "Daily NASA wallpaper update timer";
    Timer = {
      OnCalendar = "*-*-* 00:05:00";
      RandomizedDelaySec = "5m";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  programs.plasma = {
    enable = true;
    workspace = {
      wallpaper = "/home/tbusby/.cache/wallpapers/current.jpg";
    };
  };

  home.stateVersion = "25.05";
  home.enableNixpkgsReleaseCheck = false;
}
