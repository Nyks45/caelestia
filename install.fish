#!/usr/bin/env fish

argparse -n 'install.fish' -X 0 \
    'h/help' \
    'noconfirm' \
    'vscode=?!contains -- "$_flag_value" codium code' \
    'discord' \
    'zen' \
    'aur-helper=!contains -- "$_flag_value" yay paru' \
    -- $argv
or exit

# Print help
if set -q _flag_h
    echo 'usage: ./install.sh [-h] [--noconfirm] [--vscode] [--discord] [--aur-helper]'
    echo
    echo 'options:'
    echo '  -h, --help                  show this help message and exit'
    echo '  --noconfirm                 do not confirm package installation'
    echo '  --vscode=[codium|code]      install VSCodium (or VSCode)'
    echo '  --discord                   install Discord (OpenAsar + Equicord)'
    echo '  --zen                       install Zen browser'
    echo '  --aur-helper=[yay|paru]     the AUR helper to use'

    exit
end


# Helper funcs
function _out -a colour text
    set_color $colour
    # Pass arguments other than text to echo
    echo $argv[3..] -- ":: $text"
    set_color normal
end

function log -a text
    _out cyan $text $argv[2..]
end

function input -a text
    _out blue $text $argv[2..]
end

function sh-read
    sh -c 'read a && echo -n "$a"' || exit 1
end

function confirm-overwrite -a path
    if test -e $path -o -L $path
        # No prompt if noconfirm
        if set -q noconfirm
            input "$path already exists. Overwrite? [Y/n]"
            log 'Removing...'
            rm -rf $path
        else
            # Prompt user
            input "$path already exists. Overwrite? [Y/n] " -n
            set -l confirm (sh-read)

            if test "$confirm" = 'n' -o "$confirm" = 'N'
                log 'Skipping...'
                return 1
            else
                log 'Removing...'
                rm -rf $path
            end
        end
    end

    return 0
end


# Variables
set -q _flag_noconfirm && set noconfirm '--noconfirm'
set -q _flag_aur_helper && set -l aur_helper $_flag_aur_helper || set -l aur_helper paru
set -q XDG_CONFIG_HOME && set -l config $XDG_CONFIG_HOME || set -l config $HOME/.config
set -q XDG_STATE_HOME && set -l state $XDG_STATE_HOME || set -l state $HOME/.local/state
set -l install_dir (path dirname (path resolve (status filename)))

# Startup prompt
set_color magenta
echo '╭─────────────────────────────────────────────────╮'
echo '│      ______           __          __  _         │'
echo '│     / ____/___ ____  / /__  _____/ /_(_)___ _   │'
echo '│    / /   / __ `/ _ \/ / _ \/ ___/ __/ / __ `/   │'
echo '│   / /___/ /_/ /  __/ /  __(__  ) /_/ / /_/ /    │'
echo '│   \____/\__,_/\___/_/\___/____/\__/_/\__,_/     │'
echo '│                                                 │'
echo '╰─────────────────────────────────────────────────╯'
set_color normal
log 'Welcome to the Caelestia dotfiles installer!'
log 'Before continuing, please ensure you have made a backup of your config directory.'

# Prompt for backup
if ! set -q _flag_noconfirm
    log '[1] Two steps ahead of you!  [2] Make one for me please!'
    input '=> ' -n
    set -l choice (sh-read)

    if contains -- "$choice" 1 2
        if test $choice = 2
            log "Backing up $config..."

            if test -e $config.bak -o -L $config.bak
                input 'Backup already exists. Overwrite? [Y/n] ' -n
                set -l overwrite (sh-read)

                if test "$overwrite" = 'n' -o "$overwrite" = 'N'
                    log 'Skipping...'
                else
                    rm -rf $config.bak
                    cp -r $config $config.bak
                end
            else
                cp -r $config $config.bak
            end
        end
    else
        log 'No choice selected. Exiting...'
        exit 1
    end
end


# Install AUR helper if not already installed
if ! pacman -Q $aur_helper &> /dev/null
    log "$aur_helper not installed. Installing..."

    # Install
    sudo pacman -S --needed git base-devel $noconfirm
    cd /tmp
    git clone https://aur.archlinux.org/$aur_helper.git
    cd $aur_helper
    makepkg -si
    cd ..
    rm -rf $aur_helper

    # Setup
    if test $aur_helper = yay
        $aur_helper -Y --gendb
        $aur_helper -Y --devel --save
    else
        $aur_helper --gendb
    end
end

# Cd into dir
cd $install_dir || exit 1

# Install metapackage for deps
log 'Installing metapackage...'

if test $aur_helper = yay
    $aur_helper -Bi . $noconfirm
else
    $aur_helper -Ui $noconfirm
end
fish -c 'rm -f caelestia-meta-*.pkg.tar.zst' 2> /dev/null

# Install hypr* configs
if confirm-overwrite $config/hypr
    log 'Installing hypr* configs...'
    ln -s (realpath hypr) $config/hypr
    chmod u+x $config/hypr/scripts/wsaction.fish
    hyprctl reload
end

# Starship
if confirm-overwrite $config/starship.toml
    log 'Installing starship config...'
    ln -s (realpath starship.toml) $config/starship.toml
end

# Foot
if confirm-overwrite $config/foot
    log 'Installing foot config...'
    ln -s (realpath foot) $config/foot
end

# Fish
if confirm-overwrite $config/fish
    log 'Installing fish config...'
    ln -s (realpath fish) $config/fish
end

# Fastfetch
if confirm-overwrite $config/fastfetch
    log 'Installing fastfetch config...'
    ln -s (realpath fastfetch) $config/fastfetch
end

# Uwsm
if confirm-overwrite $config/uwsm
    log 'Installing uwsm config...'
    ln -s (realpath uwsm) $config/uwsm
end

# Btop
if confirm-overwrite $config/btop
    log 'Installing btop config...'
    ln -s (realpath btop) $config/btop
end

# Install spicetify
log 'Installing spotify (spicetify)...'

set -l has_spicetify (pacman -Q spicetify-cli 2> /dev/null)
$aur_helper -S --needed spotify spicetify-cli spicetify-marketplace-bin $noconfirm

    # Set permissions and init if new install
    if test -z "$has_spicetify"
        sudo chmod a+wr /opt/spotify
        sudo chmod a+wr /opt/spotify/Apps -R
        spicetify backup apply
    end

    # Install configs
    if confirm-overwrite $config/spicetify
        log 'Installing spicetify config...'
        ln -s (realpath spicetify) $config/spicetify

        # Set spicetify configs
        spicetify config current_theme caelestia color_scheme caelestia custom_apps marketplace 2> /dev/null
        spicetify apply
    end

# Install vscode
if set -q _flag_vscode
    test "$_flag_vscode" = 'code' && set -l prog 'code' || set -l prog 'codium'
    test "$_flag_vscode" = 'code' && set -l packages 'code' || set -l packages 'vscodium-bin' 'vscodium-bin-marketplace'
    test "$_flag_vscode" = 'code' && set -l folder 'Code' || set -l folder 'VSCodium'
    set -l folder $config/$folder/User

    log "Installing vs$prog..."
    $aur_helper -S --needed $packages $noconfirm

    # Install configs
    if confirm-overwrite $folder/settings.json && confirm-overwrite $folder/keybindings.json && confirm-overwrite $config/$prog-flags.conf
        log "Installing vs$prog config..."
        ln -s (realpath vscode/settings.json) $folder/settings.json
        ln -s (realpath vscode/keybindings.json) $folder/keybindings.json
        ln -s (realpath vscode/flags.conf) $config/$prog-flags.conf

        # Install extension
        $prog --install-extension vscode/caelestia-vscode-integration/caelestia-vscode-integration-*.vsix
    end
end

# Install discord
if set -q _flag_discord
    log 'Installing discord...'
    $aur_helper -S --needed discord equicord-installer-bin $noconfirm

    # Install OpenAsar and Equicord
    sudo Equilotl -install -location /opt/discord
    sudo Equilotl -install-openasar -location /opt/discord

    # Remove installer
    $aur_helper -Rns equicord-installer-bin $noconfirm
end

# Install zen
if set -q _flag_zen
    log 'Installing zen...'
    $aur_helper -S --needed zen-browser-bin $noconfirm

    # Install userChrome css
    set -l chrome $HOME/.zen/*/chrome
    if confirm-overwrite $chrome/userChrome.css
        log 'Installing zen userChrome...'
        ln -s (realpath zen/userChrome.css) $chrome/userChrome.css
    end

    # Install native app
    set -l hosts $HOME/.mozilla/native-messaging-hosts
    set -l lib $HOME/.local/lib/caelestia

    if confirm-overwrite $hosts/caelestiafox.json
        log 'Installing zen native app manifest...'
        mkdir -p $hosts
        cp zen/native_app/manifest.json $hosts/caelestiafox.json
        sed -i "s|{{ \$lib }}|$lib|g" $hosts/caelestiafox.json
    end

    if confirm-overwrite $lib/caelestiafox
        log 'Installing zen native app...'
        mkdir -p $lib
        ln -s (realpath zen/native_app/app.fish) $lib/caelestiafox
    end

    # Prompt user to install extension
    log 'Please install the CaelestiaFox extension from https://addons.mozilla.org/en-US/firefox/addon/caelestiafox if you have not already done so.'
end

# Quickshell
if confirm-overwrite $config/quickshell/caelestia
    log 'Installing quickshell config...'
    ln -s (realpath quickshell) $config/quickshell/caelestia

    # Patch system exclusion zones for unclickable edges
    sudo sed -i 's|exclusiveZone: contentItem.Config.border.thickness|exclusiveZone: 5|' /etc/xdg/quickshell/caelestia/modules/drawers/Exclusions.qml
end

# Hyprbars
log 'Installing hyprbars plugin...'
hyprpm update
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm enable hyprbars

# Editor, file manager, polkit
log 'Installing gnome-text-editor, nautilus, polkit-gnome...'
$aur_helper -S --needed gnome-text-editor nautilus polkit-gnome $noconfirm

# cachy-update terminal wrapper
if confirm-overwrite $HOME/.local/bin/cachy-update
    log 'Installing cachy-update wrapper...'
    cp (realpath local/bin/cachy-update) $HOME/.local/bin/cachy-update
    chmod +x $HOME/.local/bin/cachy-update
end

# cachy-update desktop override
if confirm-overwrite $HOME/.local/share/applications/arch-update.desktop
    log 'Installing cachy-update desktop override...'
    mkdir -p $HOME/.local/share/applications
    cp (realpath local/applications/arch-update.desktop) $HOME/.local/share/applications/arch-update.desktop
    update-desktop-database $HOME/.local/share/applications
end

# Rename foot to Terminal in launcher
if confirm-overwrite $HOME/.local/share/applications/foot.desktop
    log 'Installing foot → Terminal desktop override...'
    mkdir -p $HOME/.local/share/applications
    cp (realpath local/applications/foot.desktop) $HOME/.local/share/applications/foot.desktop
    update-desktop-database $HOME/.local/share/applications
end

# hypr-show-desktop script
mkdir -p $HOME/.local/bin
log 'Installing hypr-show-desktop script...'
cp (realpath hypr-show-desktop) $HOME/.local/bin/hypr-show-desktop
chmod +x $HOME/.local/bin/hypr-show-desktop

# Sync quickshell QML to system-installed location
log 'Syncing quickshell to system path...'
sudo rsync -a (realpath quickshell)/ /etc/xdg/quickshell/caelestia/

# SDDM astronaut theme (custom fork with Frieren themes)
log 'Installing sddm-astronaut-theme from custom fork...'
cd /tmp
rm -rf sddm-astronaut-theme
git clone https://github.com/Nyks45/sddm-astronaut-theme.git
sudo rm -rf /usr/share/sddm/themes/sddm-astronaut-theme
sudo cp -r sddm-astronaut-theme /usr/share/sddm/themes/sddm-astronaut-theme
sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/ 2>/dev/null; or true
cd $install_dir

log 'Configuring SDDM astronaut theme with Frieren Pixel Sorcery...'
sudo mkdir -p /etc/sddm.conf.d
sudo cp (realpath sddm/astronaut.conf) /etc/sddm.conf.d/astronaut.conf
sudo cp (realpath sddm/frieren_pixel_sorcery.conf) /usr/share/sddm/themes/sddm-astronaut-theme/Themes/frieren_pixel_sorcery.conf
sudo sed -i 's|ConfigFile=Themes/.*|ConfigFile=Themes/frieren_pixel_sorcery.conf|' /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop

# Live wallpaper
log 'Setting up live wallpaper...'
$aur_helper -S --needed mpvpaper $noconfirm

mkdir -p $HOME/Videos/wallpapers
set -l wallpaper_url 'https://motionbgs.com/dl/hd/9032/'
set -l wallpaper_path $HOME/Videos/wallpapers/frieren-quiet-tale.mp4

if ! test -f $wallpaper_path
    log 'Downloading Frieren Quiet Tale wallpaper...'
    curl -L -o $wallpaper_path $wallpaper_url
end

log 'Live wallpaper configured in execs.conf (mpvpaper with panscan)'

# GRUB theme (CelesteGRUB with Frieren wallpaper)
log 'Installing CelesteGRUB theme with Frieren wallpaper...'
cd /tmp
rm -rf CelesteGRUB
git clone --depth 1 https://github.com/suilven641/CelesteGRUB.git
mkdir -p CelesteGRUB_extracted
tar -xzf CelesteGRUB/CelesteGRUB1080p.tar.gz -C CelesteGRUB_extracted

sudo rm -rf /usr/share/grub/themes/CelesteGRUB-Frieren
sudo mkdir -p /usr/share/grub/themes/CelesteGRUB-Frieren
sudo cp -r CelesteGRUB_extracted/CelesteGRUB1080p/* /usr/share/grub/themes/CelesteGRUB-Frieren/
sudo cp (realpath $install_dir/grub/frieren.png) /usr/share/grub/themes/CelesteGRUB-Frieren/frieren.png
sudo cp (realpath $install_dir/grub/theme.txt) /usr/share/grub/themes/CelesteGRUB-Frieren/theme.txt
cd $install_dir

log 'Configuring GRUB for quiet boot...'
sudo cp -an /etc/default/grub /etc/default/grub.bak

# Set GRUB theme
if grep -q '^GRUB_THEME=' /etc/default/grub
    sudo sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/usr/share/grub/themes/CelesteGRUB-Frieren/theme.txt"|' /etc/default/grub
else
    echo 'GRUB_THEME="/usr/share/grub/themes/CelesteGRUB-Frieren/theme.txt"' | sudo tee -a /etc/default/grub
end

# Set quiet boot parameters
if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub
    sudo sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=0 rd.udev.log_level=0 rd.systemd.show_status=false vt.global_cursor_default=0 nowatchdog nvme_load=YES"|' /etc/default/grub
else
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=0 rd.udev.log_level=0 rd.systemd.show_status=false vt.global_cursor_default=0 nowatchdog nvme_load=YES"' | sudo tee -a /etc/default/grub
end

# Ensure gfxterm output
if grep -q '^GRUB_TERMINAL_OUTPUT=' /etc/default/grub
    sudo sed -i 's/^GRUB_TERMINAL_OUTPUT=.*/GRUB_TERMINAL_OUTPUT="gfxterm"/' /etc/default/grub
else
    echo 'GRUB_TERMINAL_OUTPUT="gfxterm"' | sudo tee -a /etc/default/grub
end

# Fix duplicate entries by removing execute permission from backup
if test -f /etc/grub.d/10_linux.bak
    sudo chmod -x /etc/grub.d/10_linux.bak
end

# Update GRUB
log 'Updating GRUB configuration...'
if command -v update-grub >/dev/null
    sudo update-grub
else if command -v grub-mkconfig >/dev/null
    sudo grub-mkconfig -o /boot/grub/grub.cfg
else if command -v grub2-mkconfig >/dev/null
    if test -d /sys/firmware/efi
        sudo grub2-mkconfig -o /boot/efi/EFI/*/grub.cfg 2>/dev/null; or sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    else
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    end
else
    log 'Warning: No GRUB update command found. Please update GRUB manually.'
end

# Generate scheme stuff if needed
if ! test -f $state/caelestia/scheme.json
    caelestia scheme set -n shadotheme
    sleep .5
    hyprctl reload
end

# Start the shell
caelestia shell -d > /dev/null

log 'Done!'
