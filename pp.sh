#!/usr/bin/env bash

# ====== CLONE + CD (ANTES DE TODO) ======
REPO_URL="https://github.com/zelaya420/bspwm"
REPO_DIR="$HOME/bspwm"

if ! command -v git >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm git
fi

if [[ ! -d "$REPO_DIR/.git" ]]; then
  rm -rf "$REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR" || exit 1
fi

cd "$REPO_DIR" || exit 1
# =======================================

set -euo pipefail

backup_folder="$HOME/.RiceBackup"
date="$(date +%Y%m%d-%H%M%S)"

# Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Global variables
dir="$REPO_DIR"
fdir="$HOME/.local/share/fonts"
user="$(whoami)"

trap ctrl_c INT
ctrl_c(){ echo -e "\n\n${redColour}[!] Exiting...\n${endColour}"; exit 1; }

banner(){
  echo -e "\n${turquoiseColour}              _____            ______"
  sleep 0.05
  echo -e "______ ____  ___  /______      ___  /___________________      ________ ___"
  sleep 0.05
  echo -e "_  __ \`/  / / /  __/  __ \     __  __ \_  ___/__  __ \_ | /| / /_  __ \`__ \\\\"
  sleep 0.05
  echo -e "/ /_/ // /_/ // /_ / /_/ /     _  /_/ /(__  )__  /_/ /_ |/ |/ /_  / / / / /"
  sleep 0.05
  echo -e "\__,_/ \__,_/ \__/ \____/      /_.___//____/ _  .___/____/|__/ /_/ /_/ /_/    ${endColour}${yellowColour}(${endColour}${grayColour}Byzelaya420${endColour}${purpleColour}@zelaya420${endColour}${yellowColour})${endColour}${turquoiseColour}"
  sleep 0.05
  echo -e "                                             /_/${endColour}"
}

need_cmd(){ command -v "$1" >/dev/null 2>&1 || { echo -e "${redColour}[-] Falta comando: $1${endColour}"; exit 1; }; }

pac_install(){ sudo pacman -S --needed --noconfirm "$@"; }

ensure_paru(){
  if command -v paru >/dev/null 2>&1; then return 0; fi
  echo -e "\n${blueColour}[*] Instalando paru...${endColour}"
  pac_install base-devel git
  cd /tmp
  rm -rf paru
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm
}

# no prompts / no review / limpia deps de build
paru_install(){
  ensure_paru
  paru -S --needed --noconfirm --skipreview --removemake --noupgrademenu --noprovides "$@"
}

if [[ "$user" == "root" ]]; then
  banner
  echo -e "\n\n${redColour}[!] No ejecutes como root. Usa un usuario con sudo.${endColour}"
  exit 1
fi

banner
need_cmd pacman
need_cmd sudo

echo -e "\n${blueColour}[*] Update...${endColour}"
sudo pacman -Syu --noconfirm

echo -e "\n${blueColour}[*] Instalando paquetes (mayoria via paru)...${endColour}"

# >>> zscroll SIN git (zscroll), así evitas el build roto de zscroll-git
paru_install \
  kitty rofi feh xclip ranger brightnessctl fastfetch scrot jq wmname imagemagick cmatrix htop \
  python-pip procps-ng fzf lsd bat pamixer flameshot playerctl bluez dunst gawk blueman zenity \
  bspwm sxhkd polybar picom \
  xorg-xsetroot xorg-xrandr xorg-xprop xorg-xwininfo \
  python-pywal \
  betterlockscreen tty-clock scrub \
  zscroll

echo -e "\n${greenColour}[+] Paquetes OK${endColour}"

echo -e "\n${purpleColour}[*] Installing EWW (build from upstream)...${endColour}"
paru_install rust cargo
mkdir -p "$HOME/tools"
cd "$HOME/tools"
rm -rf eww
git clone https://github.com/elkowar/eww.git
cd eww
cargo build --release --no-default-features --features x11
sudo install -m 0755 target/release/eww /usr/local/bin/eww
cd "$HOME/tools"

echo -e "\n${purpleColour}[*] Installing Oh My Zsh + Powerlevel10k...${endColour}"
paru_install zsh curl

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" || true

sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  /root/.oh-my-zsh/custom/themes/powerlevel10k || true

echo -e "\n${blueColour}[*] Configurando...${endColour}"

mkdir -p "$fdir"
[[ -d "$dir/fonts" ]] && cp -rv "$dir/fonts/." "$fdir/" || true

wall_dir="$HOME/Wallpapers"
mkdir -p "$wall_dir"
[[ -d "$dir/wallpapers" ]] && cp -rv "$dir/wallpapers/." "$wall_dir/" || true
[[ -f "$wall_dir/archkali.png" ]] && wal -nqi "$wall_dir/archkali.png" || true

mkdir -p "$HOME/.config"
[[ -d "$dir/config" ]] && cp -rv "$dir/config/." "$HOME/.config/" || true

[[ -f "$dir/.zshrc" ]] && cp -v "$dir/.zshrc" "$HOME/.zshrc" && sudo ln -sfv "$HOME/.zshrc" /root/.zshrc || true
[[ -f "$dir/.p10k.zsh" ]] && cp -v "$dir/.p10k.zsh" "$HOME/.p10k.zsh" && sudo ln -sfv "$HOME/.p10k.zsh" /root/.p10k.zsh || true

echo -e "\n${blueColour}[*] Backup...${endColour}"
mkdir -p "$backup_folder/$date"
for p in bspwm sxhkd polybar eww kitty bin rofi; do
  [[ -d "$HOME/.config/$p" ]] && cp -r "$HOME/.config/$p" "$backup_folder/$date/" || true
done

echo -e "\n${purpleColour}[*] Scripts...${endColour}"
if [[ -d "$dir/scripts" ]]; then
  [[ -f "$dir/scripts/whichSystem.py" ]] && sudo install -m 0755 "$dir/scripts/whichSystem.py" /usr/local/bin/whichSystem.py || true
  mkdir -p "$HOME/.config/polybar/shapes/scripts"
  cp -rv "$dir/scripts/"*.sh "$HOME/.config/polybar/shapes/scripts/" 2>/dev/null || true
  touch "$HOME/.config/polybar/shapes/scripts/target"
fi

echo -e "\n${purpleColour}[*] Permisos...${endColour}"
chmod -R +x "$HOME/.config/bspwm/" 2>/dev/null || true
chmod +x "$HOME/.config/polybar/launch.sh" 2>/dev/null || true
chmod +x "$HOME/.config/polybar/scripts/"* 2>/dev/null || true
chmod +x "$HOME/.config/polybar/pywal.sh" 2>/dev/null || true
chmod +x "$HOME/.config/bin/"* 2>/dev/null || true

rm -rf "$HOME/tools" || true

echo -e "\n${greenColour}[+] Listo${endColour}"

while true; do
  echo -en "\n${yellowColour}[?] Reiniciar ahora? ([y]/n) ${endColour}"
  read -r REPLY
  REPLY=${REPLY:-"y"}
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo reboot
  elif [[ $REPLY =~ ^[Nn]$ ]]; then
    exit 0
  fi
done
