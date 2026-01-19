#!/usr/bin/env bash
set -euo pipefail

# =======================
#        PRE-CHECKS
# =======================

if [[ ${EUID:-1000} -eq 0 ]]; then
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

# =======================
#  UTILS: DEDUP LIST
# =======================

dedup_words() {
  # Imprime palabras únicas preservando el orden (una por espacio/linea).
  awk '
    {
      for (i=1; i<=NF; i++) {
        if (!seen[$i]++) out[++n]=$i
      }
    }
    END {
      for (i=1; i<=n; i++) printf "%s%s", out[i], (i<n ? " " : "")
    }
  '
}

dedup_array() {
  # Uso: dedup_array "${arr[@]}"
  # Imprime tokens únicos (uno por espacio), preservando orden.
  printf "%s " "$@" | dedup_words
}

# =======================
#  PARU ONLY INSTALL
# =======================

ensure_paru(){
  if command -v paru >/dev/null 2>&1; then
    return 0
  fi

  echo -e "\n${blueColour}[*] Instalando paru (AUR helper)...${endColour}"
  need_cmd git || true

  # Instala deps mínimas con pacman SOLO para poder construir paru (bootstrap)
  sudo pacman -S --needed --noconfirm base-devel git

  cd /tmp
  rm -rf paru
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm --needed
}

paru_install(){
  ensure_paru
  local pkgs
  pkgs="$(dedup_array "$@")"
  [[ -n "${pkgs// /}" ]] || return 0
  # shellcheck disable=SC2086
  paru -S --needed --noconfirm --skipreview --removemake --noupgrademenu --noprovides $pkgs
}

# =======================
#  CLONE + CD (opcional, para tu rice)
# =======================

REPO_URL="https://github.com/zelaya420/bspwm"
REPO_DIR="$HOME/bspwm"

ensure_paru
paru_install git

if [[ ! -d "$REPO_DIR/.git" ]]; then
  rm -rf "$REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"

# =======================
#         START
# =======================

banner
need_cmd sudo
need_cmd pacman

# =======================
# [1] SISTEMA (UPDATE)
# =======================

echo -e "\n${blueColour}[*] Actualizando sistema...${endColour}"
sudo pacman -Syu --noconfirm

# =======================
# [2] BASE (PARU)
# =======================

PARU_BASE_PKGS=(
  base-devel net-tools vim nano curl wget htop man-db man-pages bash-completion which tree
  unzip zip p7zip lsof strace
)

echo -e "\n${blueColour}[*] Instalando base...${endColour}"
paru_install "${PARU_BASE_PKGS[@]}"

# =======================
# [3] FUENTES (PARU)
# =======================

PARU_FONTS_PKGS=(
  ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji ttf-jetbrains-mono
)

echo -e "\n${blueColour}[*] Instalando fuentes...${endColour}"
paru_install "${PARU_FONTS_PKGS[@]}"

# =======================
# [4] VIRTUALBOX (PARU)
# =======================

echo -e "\n${blueColour}[*] Instalando VirtualBox Guest Utils...${endColour}"
if pacman -Q linux &>/dev/null; then
  paru_install virtualbox-guest-utils
else
  paru_install virtualbox-guest-utils virtualbox-guest-dkms linux-headers
fi
sudo systemctl enable vboxservice --now || true

# =======================
# [5] RED / BT / AUDIO (PARU)
# =======================

PARU_NET_AUDIO_PKGS=(
  networkmanager network-manager-applet wpa_supplicant
  bluez bluez-utils blueman
  pulseaudio pulseaudio-alsa pulseaudio-bluetooth pavucontrol
)

echo -e "\n${blueColour}[*] Instalando red / bluetooth / audio...${endColour}"
paru_install "${PARU_NET_AUDIO_PKGS[@]}"
sudo systemctl enable NetworkManager bluetooth --now || true

# =======================
# [6] RICE (PARU)
# =======================

PARU_RICE_PKGS=(
  kitty rofi feh thunar xclip ranger brightnessctl fastfetch scrot jq wmname imagemagick cmatrix
  procps-ng fzf lsd bat pamixer flameshot playerctl dunst bspwm sxhkd geany nvim polybar picom
  python-pywal betterlockscreen zsh zsh-syntax-highlighting zsh-autosuggestions firefox rust cargo python-pipx
)

echo -e "\n${blueColour}[*] Instalando rice...${endColour}"
paru_install "${PARU_RICE_PKGS[@]}"

# =======================
# [7] EWW (BUILD)
# =======================

echo -e "\n${blueColour}[*] Instalando EWW (build desde source)...${endColour}"
{
  mkdir -p ~/tools
  cd ~/tools
  rm -rf eww
  git clone https://github.com/elkowar/eww.git
  cd eww
  cargo build --release --no-default-features --features x11
  sudo install -m 0755 target/release/eww /usr/local/bin/eww
} || {
  echo -e "${yellowColour}[!] EWW no se pudo compilar/instalar. Puedes revisarlo manualmente.${endColour}"
}
cd ~
rm -rf ~/tools

# =======================
# [8] PENTESTING – RECON & ENUM (PARU)
# =======================

# Nota:
# - Quité httprobe para evitar paquetes faltantes (httpx cubre eso mejor).
# - Mantengo herramientas "core" y wordlists.
PARU_PENTEST_RECON_ENUM_PKGS=(
  nmap masscan arp-scan netdiscover tcpdump wireshark-qt bind whois traceroute mtr
  whatweb httpx ffuf gobuster feroxbuster nikto
  amass subfinder assetfinder dnsrecon
  samba enum4linux-ng impacket kerbrute ldap-utils
  seclists wordlists dirbuster-wordlists wfuzz
)

echo -e "\n${blueColour}[*] Instalando herramientas de reconocimiento y enumeración...${endColour}"
paru_install "${PARU_PENTEST_RECON_ENUM_PKGS[@]}"
echo -e "\n${greenColour}[+] Recon y enum base listo ✅${endColour}"

# =======================
# [9] RECON AVANZADO (EXTRA) (PARU)
# =======================

# Cambios:
# - crackmapexec -> netexec (nombre actual en Arch)
# - hping -> hping3 (más común); si tu repo tiene hping, cambia por hping.
PARU_RECON_AVANZADO_PKGS=(
  fping hping3 nping netcat-openbsd socat ipcalc ettercap curlie
  gau waybackurls hakrawler katana
  dnsenum dnscan massdns puredns shuffledns
  netexec nbtscan responder
  rustscan naabu
)

echo -e "\n${blueColour}[*] Instalando herramientas avanzadas de reconocimiento...${endColour}"
paru_install "${PARU_RECON_AVANZADO_PKGS[@]}"
echo -e "\n${greenColour}[+] Reconocimiento avanzado listo ✅${endColour}"

# =======================
# [10] CREDENCIALES & CRACKING (PARU)
# =======================

PARU_CREDS_CRACKING_PKGS=(
  hashcat john hydra crunch rarcrack cewl rsmangler hashid hash-identifier jwt-tool steghide exiftool binwalk
)

PARU_EXTRA_WORDLISTS_PKGS=(
  rockyou weakpass-wordlists
)

echo -e "\n${blueColour}[*] Instalando herramientas de credenciales y cracking...${endColour}"
paru_install "${PARU_CREDS_CRACKING_PKGS[@]}"

echo -e "\n${blueColour}[*] Instalando wordlists extra...${endColour}"
paru_install "${PARU_EXTRA_WORDLISTS_PKGS[@]}"

echo -e "\n${purpleColour}[*] Preparando RockYou (si existe comprimida)...${endColour}"
if [[ -f /usr/share/wordlists/rockyou.txt.gz && ! -f /usr/share/wordlists/rockyou.txt ]]; then
  sudo gzip -dk /usr/share/wordlists/rockyou.txt.gz || true
fi

echo -e "\n${greenColour}[+] Credenciales & cracking listo ✅${endColour}"

# =======================
# [11] WINDOWS / AD (MODERNO) (PARU)
# =======================

# Nota:
# - netexec ya está en [9], aquí solo dejamos lo restante (dedup lo cubre igual).
PARU_WINDOWS_AD_MODERNO_PKGS=(
  smbmap
  evil-winrm
  freerdp
)

echo -e "\n${blueColour}[*] Instalando herramientas modernas para Windows / AD...${endColour}"
paru_install "${PARU_WINDOWS_AD_MODERNO_PKGS[@]}"
echo -e "\n${greenColour}[+] Windows / AD moderno listo ✅${endColour}"

# =======================
# [12] POST: GRUPOS / NOTAS
# =======================

# Wireshark: permite capturas sin sudo (recomendado)
if getent group wireshark >/dev/null 2>&1; then
  sudo usermod -aG wireshark "$USER" || true
fi

echo -e "\n${yellowColour}[i] Nota:${endColour} si agregaste grupos (wireshark/docker/etc), cierra sesión y vuelve a entrar."

# =======================
# [13] DEDUP INFO (OPCIONAL)
# =======================

ALL_PKGS="$(printf "%s " \
  "${PARU_BASE_PKGS[@]}" \
  "${PARU_FONTS_PKGS[@]}" \
  "${PARU_NET_AUDIO_PKGS[@]}" \
  "${PARU_RICE_PKGS[@]}" \
  "${PARU_PENTEST_RECON_ENUM_PKGS[@]}" \
  "${PARU_RECON_AVANZADO_PKGS[@]}" \
  "${PARU_CREDS_CRACKING_PKGS[@]}" \
  "${PARU_EXTRA_WORDLISTS_PKGS[@]}" \
  "${PARU_WINDOWS_AD_MODERNO_PKGS[@]}" \
)"
UNIQ_PKGS="$(echo "$ALL_PKGS" | dedup_words)"

echo -e "\n${grayColour}[*] Paquetes únicos totales: $(wc -w <<<"$UNIQ_PKGS")${endColour}"

# =======================
# REBOOT
# =======================

echo -e "\n${greenColour}[+] Todo instalado correctamente ✅${endColour}"
read -rp "¿Reiniciar ahora? [Y/n]: " r
[[ "${r:-Y}" =~ ^[Yy]$ ]] && sudo reboot
