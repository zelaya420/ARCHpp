#!/usr/bin/env bash
set -euo pipefail

# =======================
#        PRE-CHECKS
# =======================

if [[ $EUID -eq 0 ]]; then
  echo "❌ No ejecutes este script como root. Usa un usuario con sudo."
  exit 1
fi

if ! command -v sudo &>/dev/null; then
  echo "❌ sudo no está instalado."
  exit 1
fi

if ! command -v pacman &>/dev/null; then
  echo "❌ Este script es solo para Arch Linux."
  exit 1
fi

# =======================
#     VARIABLES + UI
# =======================

backup_folder="$HOME/.RiceBackup"
date_now="$(date +%Y%m%d-%H%M%S)"

greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

trap 'echo -e "\n\n${redColour}[!] Exiting...${endColour}"; exit 1' INT

banner(){
  echo -e "\n${turquoiseColour}              _____            ______"
  sleep 0.03
  echo -e "______ ____  ___  /______      ___  /___________________      ________ ___"
  sleep 0.03
  echo -e "_  __ \`/  / / /  __/  __ \     __  __ \_  ___/__  __ \_ | /| / /_  __ \`__ \\"
  sleep 0.03
  echo -e "/ /_/ // /_/ // /_ / /_/ /     _  /_/ /(__  )__  /_/ /_ |/ |/ /_  / / / / /"
  sleep 0.03
  echo -e "\__,_/ \__,_/ \__/ \____/      /_.___//____/ _  .___/____/|__/ /_/ /_/ /_/    ${endColour}${yellowColour}(${endColour}${grayColour}Byzelaya420${endColour}${purpleColour}@zelaya420${endColour}${yellowColour})${endColour}"
  sleep 0.03
  echo -e "${turquoiseColour}                                             /_/${endColour}"
}

need_cmd(){
  command -v "$1" >/dev/null 2>&1 || {
    echo -e "${redColour}[-] Falta comando requerido: $1${endColour}"
    exit 1
  }
}

pac_install(){
  sudo pacman -S --needed --noconfirm "$@"
}

ensure_paru(){
  if command -v paru >/dev/null 2>&1; then
    return 0
  fi

  echo -e "\n${blueColour}[*] Instalando paru (AUR helper)...${endColour}"
  pac_install base-devel git

  cd /tmp
  rm -rf paru
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm --needed
}

paru_install(){
  ensure_paru
  paru -S --needed --noconfirm --skipreview --removemake --noupgrademenu --noprovides "$@"
}

# =======================
#  CLONE + CD
# =======================

REPO_URL="https://github.com/zelaya420/bspwm"
REPO_DIR="$HOME/bspwm"

command -v git >/dev/null 2>&1 || pac_install git

[[ ! -d "$REPO_DIR/.git" ]] && rm -rf "$REPO_DIR" && git clone "$REPO_URL" "$REPO_DIR"
cd "$REPO_DIR"

# =======================
#         START
# =======================

banner
need_cmd pacman
need_cmd sudo

# =======================
# [1] SISTEMA
# =======================

sudo pacman -Syu --noconfirm

# =======================
# [2] BASE
# =======================

pac_install base-devel net-tools vim nano curl wget htop man-db man-pages bash-completion which tree unzip zip p7zip lsof strace

# =======================
# [3] FUENTES
# =======================

pac_install ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji ttf-jetbrains-mono

# =======================
# [4] VIRTUALBOX
# =======================

pacman -Q linux &>/dev/null \
  && pac_install virtualbox-guest-utils \
  || pac_install virtualbox-guest-utils virtualbox-guest-dkms linux-headers

sudo systemctl enable vboxservice --now || true

# =======================
# [5] RED / BT / AUDIO
# =======================

pac_install networkmanager network-manager-applet wpa_supplicant bluez bluez-utils blueman pulseaudio pulseaudio-alsa pulseaudio-bluetooth pavucontrol
sudo systemctl enable NetworkManager bluetooth --now || true

# =======================
# [6] RICE
# =======================

paru_install kitty rofi feh thunar xclip ranger brightnessctl fastfetch scrot jq wmname imagemagick cmatrix \
  procps-ng fzf lsd bat pamixer flameshot playerctl dunst bspwm sxhkd geany nvim polybar picom \
  python-pywal betterlockscreen zsh zsh-syntax-highlighting zsh-autosuggestions firefox rust cargo python-pipx

# =======================
# [7] EWW
# =======================

mkdir -p ~/tools && cd ~/tools
git clone https://github.com/elkowar/eww.git
cd eww
cargo build --release --no-default-features --features x11
sudo install -m 0755 target/release/eww /usr/local/bin/eww
cd ~ && rm -rf ~/tools

# =======================
# [8] PENTESTING – RECON & ENUM
# =======================

echo -e "\n${blueColour}[*] Instalando herramientas de reconocimiento y enumeración...${endColour}"

paru_install \
  nmap masscan arp-scan netdiscover tcpdump wireshark-qt bind whois traceroute mtr \
  whatweb httpx ffuf gobuster feroxbuster nikto samba enum4linux-ng impacket \
  kerbrute ldap-utils

echo -e "\n${greenColour}[+] Todo instalado correctamente ✅${endColour}"

# =======================
# REBOOT
# =======================

read -rp "¿Reiniciar ahora? [Y/n]: " r
[[ "${r:-Y}" =~ ^[Yy]$ ]] && sudo reboot
