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

user="$(whoami)"

trap 'echo -e "\n\n${redColour}[!] Exiting...${endColour}"; exit 1' INT

banner(){
  echo -e "\n${turquoiseColour}              _____            ______"
  sleep 0.03
  echo -e "______ ____  ___  /______      ___  /___________________      ________ ___"
  sleep 0.03
  echo -e "_  __ \`/  / / /  __/  __ \     __  __ \_  ___/__  __ \_ | /| / /_  __ \`__ \\\\"
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
#  CLONE + CD (ANTES DE TODO)
# =======================

REPO_URL="https://github.com/zelaya420/bspwm"
REPO_DIR="$HOME/bspwm"

if ! command -v git >/dev/null 2>&1; then
  pac_install git
fi

if [[ ! -d "$REPO_DIR/.git" ]]; then
  rm -rf "$REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

# =======================
#         START
# =======================

banner
echo "✔️ Pre-checks OK"
echo "Directorio de respaldo: $backup_folder"
echo "Fecha actual: $date_now"

need_cmd pacman
need_cmd sudo

# =======================
#      [1] SISTEMA
# =======================

echo -e "\n${blueColour}[*] Actualizando sistema...${endColour}"
sudo pacman -Syu --noconfirm

# =======================
#   [2] BASE + TOOLING
# =======================

echo -e "\n${blueColour}[*] Instalando base-devel + herramientas básicas...${endColour}"
pac_install \
  base-devel \
  net-tools \
  vim nano \
  curl wget \
  htop \
  man-db man-pages \
  bash-completion \
  which tree \
  unzip zip p7zip \
  lsof strace

# =======================
#        [3] FUENTES
# =======================

echo -e "\n${blueColour}[*] Instalando fuentes (base)...${endColour}"
pac_install \
  ttf-dejavu \
  ttf-liberation \
  noto-fonts \
  noto-fonts-emoji \
  ttf-jetbrains-mono

# =======================
#   [4] VIRTUALBOX GUEST
# =======================

echo -e "\n${blueColour}[*] Instalando VirtualBox Guest Utils...${endColour}"

# Si hay kernel linux instalado, instalamos lo básico; si no, DKMS + headers (por si usas otro kernel)
if pacman -Q linux &>/dev/null; then
  pac_install virtualbox-guest-utils
else
  pac_install virtualbox-guest-utils virtualbox-guest-dkms linux-headers
fi

if systemctl is-system-running &>/dev/null; then
  sudo systemctl enable vboxservice --now || true
else
  echo "⚠️ systemd no activo, vboxservice no habilitado."
fi

# =======================
#   [5] RED + BT + AUDIO
# =======================

echo -e "\n${blueColour}[*] Configurando red, Bluetooth y audio...${endColour}"

# Nota: tu 1er script usa pamixer/pavucontrol (pulseaudio). Aquí dejo pulseaudio como en tu 2º script.
pac_install \
  networkmanager \
  network-manager-applet \
  wpa_supplicant \
  bluez \
  bluez-utils \
  blueman \
  pulseaudio \
  pulseaudio-alsa \
  pulseaudio-bluetooth \
  pavucontrol

if systemctl is-system-running &>/dev/null; then
  sudo systemctl enable NetworkManager --now || true
  sudo systemctl enable bluetooth --now || true
else
  echo "⚠️ systemd no activo, servicios no habilitados."
fi

# =======================
#      [6] PARU
# =======================

echo -e "\n${blueColour}[*] Instalando/asegurando paru...${endColour}"
ensure_paru

# =======================
#   [7] PAQUETES DEL RICE
# =======================

echo -e "\n${blueColour}[*] Instalando paquetes del rice (mayoría con paru)...${endColour}"

# Nota: zscroll NO va por AUR roto -> se instala con pipx más abajo.
paru_install \
  kitty rofi feh xclip ranger brightnessctl fastfetch scrot jq wmname imagemagick cmatrix \
  procps-ng fzf lsd bat pamixer flameshot playerctl dunst gawk zenity \
  bspwm sxhkd polybar picom \
  xorg-xsetroot xorg-xrandr xorg-xprop xorg-xwininfo \
  python-pywal python-setuptools \
  betterlockscreen tty-clock scrub \
  zsh firefox \
  rust cargo \
  python-pipx

echo -e "\n${greenColour}[+] Paquetes OK${endColour}"

# =======================
#   zscroll (pipx, evita PEP668)
# =======================
echo -e "\n${blueColour}[*] Instalando zscroll y zsh plugins (mayoría con paru)...${endColour}"

# Nota: zscroll NO va por AUR roto -> se instala con pipx más abajo.
paru_install \
  zscroll \
  zsh-syntax-highlighting \
  zsh-autosuggestions
  
# =======================
#   EWW (build upstream)
# =======================

echo -e "\n${purpleColour}[*] Instalando EWW (build upstream)...${endColour}"
mkdir -p "$HOME/tools"
cd "$HOME/tools"
rm -rf eww
git clone https://github.com/elkowar/eww.git
cd eww
cargo build --release --no-default-features --features x11
sudo install -m 0755 target/release/eww /usr/local/bin/eww
cd "$REPO_DIR"
rm -rf "$HOME/tools"
echo -e "${greenColour}[+] eww listo${endColour}"

# =======================
# Oh My Zsh + Powerlevel10k
# =======================

echo -e "\n${purpleColour}[*] Instalando Oh My Zsh + Powerlevel10k...${endColour}"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" || true

# Si quieres esto para root, lo dejo como lo tenías (no es estrictamente necesario)
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  /root/.oh-my-zsh/custom/themes/powerlevel10k || true
echo -e "${greenColour}[+] zsh listo${endColour}"

# =======================
#   CONFIGS / FONTS / WALL
# =======================

echo -e "\n${blueColour}[*] Configurando fonts/wallpapers/configs...${endColour}"

dir="$REPO_DIR"
fdir="$HOME/.local/share/fonts"

# Fonts del repo
mkdir -p "$fdir"
[[ -d "$dir/fonts" ]] && cp -rv "$dir/fonts/." "$fdir/" || true

# Wallpapers + pywal
wall_dir="$HOME/Wallpapers"
mkdir -p "$wall_dir"
[[ -d "$dir/wallpapers" ]] && cp -rv "$dir/wallpapers/." "$wall_dir/" || true
[[ -f "$wall_dir/archkali.png" ]] && wal -nqi "$wall_dir/archkali.png" || true

# Configs del repo
mkdir -p "$HOME/.config"
[[ -d "$dir/config" ]] && cp -rv "$dir/config/." "$HOME/.config/" || true

# zshrc / p10k
[[ -f "$dir/.zshrc" ]] && cp -v "$dir/.zshrc" "$HOME/.zshrc" && sudo ln -sfv "$HOME/.zshrc" /root/.zshrc || true
[[ -f "$dir/.p10k.zsh" ]] && cp -v "$dir/.p10k.zsh" "$HOME/.p10k.zsh" && sudo ln -sfv "$HOME/.p10k.zsh" /root/.p10k.zsh || true

# =======================
# BACKUP CONFIGS
# =======================

echo -e "\n${blueColour}[*] Backup configs...${endColour}"
mkdir -p "$backup_folder/$date_now"
for p in bspwm sxhkd polybar eww kitty bin rofi; do
  [[ -d "$HOME/.config/$p" ]] && cp -r "$HOME/.config/$p" "$backup_folder/$date_now/" || true
done

# =======================
# SCRIPTS EXTRA
# =======================

echo -e "\n${purpleColour}[*] Scripts...${endColour}"
if [[ -d "$dir/scripts" ]]; then
  [[ -f "$dir/scripts/whichSystem.py" ]] && sudo install -m 0755 "$dir/scripts/whichSystem.py" /usr/local/bin/whichSystem.py || true
  mkdir -p "$HOME/.config/polybar/shapes/scripts"
  cp -rv "$dir/scripts/"*.sh "$HOME/.config/polybar/shapes/scripts/" 2>/dev/null || true
  touch "$HOME/.config/polybar/shapes/scripts/target"
fi

# =======================
# PERMISOS
# =======================

echo -e "\n${purpleColour}[*] Permisos...${endColour}"
chmod -R +x "$HOME/.config/bspwm/" 2>/dev/null || true
chmod +x "$HOME/.config/polybar/launch.sh" 2>/dev/null || true
chmod +x "$HOME/.config/polybar/scripts/"* 2>/dev/null || true
chmod +x "$HOME/.config/polybar/pywal.sh" 2>/dev/null || true
chmod +x "$HOME/.config/bin/"* 2>/dev/null || true
chmod +x "$HOME/.config/rofi/launcher.sh" "$HOME/.config/rofi/powermenu.sh" 2>/dev/null || true
chmod +x "$HOME/.config/asciiart/"* 2>/dev/null || true
chmod +x "$HOME/.config/colorscript" 2>/dev/null || true
chmod +x "$HOME/.config/eww/profilecard/scripts/"* 2>/dev/null || true

echo -e "\n${greenColour}[+] Listo ✅${endColour}"

while true; do
  echo -en "\n${yellowColour}[?] Necesitas reiniciar. ¿Reiniciar ahora? ([y]/n) ${endColour}"
  read -r REPLY
  REPLY=${REPLY:-"y"}
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo reboot
  elif [[ $REPLY =~ ^[Nn]$ ]]; then
    exit 0
  else
    echo -e "\n${redColour}[!] Respuesta inválida${endColour}"
  fi
done
