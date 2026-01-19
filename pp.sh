#!/usr/bin/env bash
set -euo pipefail

command -v paru >/dev/null 2>&1 || { echo "[!] paru no esta instalado"; exit 1; }

log() { echo -e "[*] $*"; }
warn() { echo -e "[!] $*" >&2; }

# Instala una lista de paquetes; si alguno falla, lo registra y continua
install_pkgs() {
  local title="$1"; shift
  local -a pkgs=("$@")
  local -a failed=()

  log "Instalando: ${title}"
  for p in "${pkgs[@]}"; do
    if paru -S --needed --noconfirm "$p"; then
      : # ok
    else
      failed+=("$p")
      warn "No se pudo instalar: $p"
    fi
  done

  if ((${#failed[@]})); then
    warn "Fallaron (${#failed[@]}): ${failed[*]}"
    echo "${failed[*]}" >> /tmp/paru_failed_pkgs.txt || true
  fi
}

log "Actualizando sistema..."
paru -Syu --noconfirm

########################################
# 0) BASE / UTILIDADES
########################################
install_pkgs "BASE / UTILIDADES" \
  git curl wget unzip unrar \
  jq python python-pip go rust \
  openssh net-tools inetutils \
  neovim tmux

########################################
# 1) RECON / INFO GATHERING
########################################
install_pkgs "RECON" \
  nmap masscan rustscan \
  traceroute whois bind \
  tcpdump wireshark-cli \
  whatweb amass subfinder \
  httpx-bin nuclei-bin

########################################
# 2) ENUMERACION (Web + AD/SMB/LDAP)
########################################
install_pkgs "ENUMERACION (WEB)" \
  ffuf gobuster feroxbuster wfuzz nikto

# SMB/LDAP/AD
# Nota: enum4linux-ng puede no existir/romper; enum4linux + nxc/impacket suele ser mejor
install_pkgs "ENUMERACION (SMB/LDAP/AD)" \
  enum4linux smbclient samba \
  rpcbind openldap \
  responder impacket \
  netexec smbmap \
  bloodhound-python \
  seclists

########################################
# 3) ANALISIS / EXPLOTACION / MITM
########################################
install_pkgs "ANALISIS / EXPLOTACION" \
  metasploit sqlmap burpsuite \
  john hashcat hydra medusa \
  bettercap mitmproxy \
  chisel socat \
  evil-winrm

########################################
# 4) POST-EXPLOTACION / PRIVESC / PIVOT
########################################
install_pkgs "POST-EXPLOTACION" \
  linpeas pspy gtfobins \
  mimikatz rubeus kerbrute \
  certipy \
  ligolo-ng frp proxychains-ng \
  rsync rclone zip p7zip \
  yara volatility3

########################################
# 5) FORENSE (disco/artefactos/triage)
########################################
install_pkgs "FORENSE" \
  sleuthkit autopsy \
  exiftool binwalk \
  testdisk \
  ddrescue \
  foremost scalpel

########################################
# 6) CRIPTO / STEGO
########################################
install_pkgs "CRIPTO / STEGO" \
  openssl gnupg age \
  hashid \
  steghide stegseek zsteg

########################################
# 7) FUZZING / CRASHING (fuzz + triage)
########################################
install_pkgs "FUZZING / CRASHING" \
  aflplusplus honggfuzz radamsa boofuzz \
  gdb lldb valgrind \
  strace ltrace \
  checksec

# Opcional: plugins de GDB (AUR a veces cambia; por eso lo dejamos separado)
install_pkgs "GDB EXTRA (OPCIONAL)" \
  pwndbg gef

########################################
# 8) REVERSE ENGINEERING
########################################
install_pkgs "REVERSE ENGINEERING" \
  ghidra radare2 cutter \
  apktool jadx

########################################
# 9) WIRELESS / RF (WiFi + SDR)
########################################
install_pkgs "WIRELESS (WiFi)" \
  aircrack-ng reaver bully \
  wifite \
  hcxdumptool hcxtools \
  kismet \
  hostapd macchanger

install_pkgs "RF / SDR" \
  rtl-sdr gqrx \
  gnuradio \
  urh \
  inspectrum

########################################
# 10) BLUETOOTH (OPCIONAL)
########################################
install_pkgs "BLUETOOTH (OPCIONAL)" \
  bluez bluez-utils

echo
echo "[✓] Listo. Categorias instaladas:"
echo "    - Base/Utilidades"
echo "    - Recon"
echo "    - Enumeracion"
echo "    - Analisis/Explotacion"
echo "    - Post-explotacion/Pivot"
echo "    - Forense"
echo "    - Cripto/Stego"
echo "    - Fuzzing/Crashing"
echo "    - Reverse Engineering"
echo "    - Wireless/RF"
echo "    - Bluetooth (opcional)"
echo
echo "Si hubo fallos de paquetes: revisa /tmp/paru_failed_pkgs.txt"
echo

############################################################
# BLOODHOUND CE (RECOMENDADO) - INSTALACION OPCIONAL (NO PARU)
# - BloodHound Legacy esta deprecado; CE se despliega con Docker/CLI oficial.
# - Te lo dejo comentado para que no rompa tu regla de 'solo paru' en lo demas.
# Fuentes: Quickstart y docker-compose oficial. :contentReference[oaicite:2]{index=2}
############################################################
: '
# Requisitos:
# paru -S --needed --noconfirm docker docker-compose
# sudo systemctl enable --now docker
#
# Instalar BloodHound CLI y desplegar CE:
# wget https://github.com/SpecterOps/bloodhound-cli/releases/latest/download/bloodhound-cli-linux-amd64.tar.gz
# tar -xvzf bloodhound-cli-linux-amd64.tar.gz
# sudo install -m 0755 bloodhound-cli /usr/local/bin/bloodhound-cli
# bloodhound-cli install
'
