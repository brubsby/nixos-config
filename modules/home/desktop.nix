{ pkgs, ... }:
{
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

  programs.konsole = {
    enable = true;
    defaultProfile = "tbusby";
    profiles.tbusby = {
      colorScheme = "Breeze";
      font = {
	name = "Termsyn";
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

  programs.nixcord = {
    enable = true;
    discord.enable = true;
    discord.vencord.enable = true;
    vesktop.enable = true;
  };

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

  programs.plasma = {
    enable = true;
    workspace = {
      wallpaper = "/home/tbusby/.cache/wallpapers/current.jpg";
    };
  };

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
        
        # APOD moved to science.nasa.gov/apod (the old apod.nasa.gov pages
        # redirect there) and api.nasa.gov/planetary/apod hangs, so scrape the
        # page. Today's media sits in the media-detail-hero block; an image's
        # src is a resized "dynamicimage" rendition, and the same path under
        # content/dam is the full-size original.
        # --retry helps if the network is still coming up.
        if ! HTML=$(${pkgs.curl}/bin/curl -sL --fail --max-time 60 --retry 5 --retry-delay 5 --retry-all-errors https://science.nasa.gov/apod/); then
          echo "Failed to fetch APOD page after retries. Skipping update."
          exit 0
        fi
        HERO=$(echo "$HTML" | ${pkgs.gnugrep}/bin/grep -A5 'media-detail-hero__media' | ${pkgs.coreutils}/bin/tr '\n' ' ')
        IMG_SRC=$(echo "$HERO" | ${pkgs.gnugrep}/bin/grep -oP '<img[^>]*\bsrc="\K[^"]+' | ${pkgs.coreutils}/bin/head -1)
        if [ -n "$IMG_SRC" ]; then
          IMG_URL=$(echo "$IMG_SRC" | ${pkgs.gnused}/bin/sed -e 's/?.*//' -e 's#/dynamicimage/assets/#/content/dam/#')
          MEDIA_TYPE="image"
        elif echo "$HERO" | ${pkgs.gnugrep}/bin/grep -qiE '<(iframe|video)'; then
          MEDIA_TYPE="video"
        fi

        if [ "$MEDIA_TYPE" = "image" ]; then
          # Download
          if ${pkgs.curl}/bin/curl -sSL --fail --retry 3 "$IMG_URL" -o /tmp/nasa_raw.jpg; then
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
        elif [ -z "$MEDIA_TYPE" ]; then
             echo "Failed to find today's media on the APOD page. Skipping update."
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
}
