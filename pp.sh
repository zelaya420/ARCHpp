#!/usr/bin/env bash
set -u

# =========================================================
# Instalador de herramientas para Arch Linux con paru
# =========================================================
# Uso:
#   chmod +x install-pentest-tools.sh
#   ./install-pentest-tools.sh
#
# Requisitos:
#   - Arch Linux
#   - paru instalado y funcional
#
# Nota:
#   Algunos nombres "conocidos" no coinciden exactamente con el
#   nombre real del paquete en Arch/AUR. Este script prueba
#   alternativas y usa la primera que exista.
# =========================================================

if ! command -v paru >/dev/null 2>&1; then
  echo "[!] paru no está instalado o no está en PATH."
  echo "    Instálalo primero y vuelve a ejecutar este script."
  exit 1
fi

# -----------------------------
# Colores
# -----------------------------
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
NC="\033[0m"

ok()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
err()   { echo -e "${RED}[-]${NC} $*"; }
info()  { echo -e "${BLUE}[*]${NC} $*"; }

# -----------------------------
# Actualizar bases primero
# -----------------------------
info "Actualizando bases de paquetes..."
paru -Sy --noconfirm || {
  err "No se pudo actualizar la base de paquetes."
  exit 1
}

# -----------------------------
# Resolver nombres alternativos
# -----------------------------
resolve_pkg() {
  local desired="$1"
  shift
  local candidates=("$@")

  for pkg in "${candidates[@]}"; do
    if paru -Si "$pkg" >/dev/null 2>&1; then
      echo "$pkg"
      return 0
    fi
  done

  return 1
}

install_group() {
  local group_name="$1"
  shift

  info "========================================"
  info "Instalando: $group_name"
  info "========================================"

  local desired pkg resolved
  local to_install=()
  local skipped=()

  for desired in "$@"; do
    case "$desired" in
      # Reconocimiento / enumeración
      nmap)                 resolved=$(resolve_pkg "$desired" nmap) ;;
      zenmap)               resolved=$(resolve_pkg "$desired" zenmap zenmap-git) ;;
      cutycapt)             resolved=$(resolve_pkg "$desired" cutycapt cutycapt-qt5-git) ;;
      legion)               resolved=$(resolve_pkg "$desired" legion legion+ ) ;;

      # Ataque / explotación
      burpsuite)            resolved=$(resolve_pkg "$desired" burpsuite) ;;
      sqlmap)               resolved=$(resolve_pkg "$desired" sqlmap sqlmap-git) ;;
      metasploit-framework) resolved=$(resolve_pkg "$desired" metasploit-framework metasploit metasploit-git) ;;
      hydra)                resolved=$(resolve_pkg "$desired" hydra) ;;
      netexec)              resolved=$(resolve_pkg "$desired" netexec netexec-git) ;;
      responder)            resolved=$(resolve_pkg "$desired" responder) ;;
      aircrack-ng)          resolved=$(resolve_pkg "$desired" aircrack-ng) ;;
      fern-wifi-cracker)    resolved=$(resolve_pkg "$desired" fern-wifi-cracker fern-wifi-cracker-git) ;;
      gophish)              resolved=$(resolve_pkg "$desired" gophish) ;;

      # Post-explotación / credenciales
      john)                 resolved=$(resolve_pkg "$desired" john) ;;
      ophcrack)             resolved=$(resolve_pkg "$desired" ophcrack) ;;
      ophcrack-cli)         resolved=$(resolve_pkg "$desired" ophcrack-cli ophcrack) ;;

      # Forense / análisis
      autopsy)              resolved=$(resolve_pkg "$desired" autopsy) ;;
      guymager)             resolved=$(resolve_pkg "$desired" guymager) ;;
      sqlitebrowser)        resolved=$(resolve_pkg "$desired" sqlitebrowser) ;;

      # Red / soporte
      tcpdump)              resolved=$(resolve_pkg "$desired" tcpdump) ;;
      netcat-traditional)   resolved=$(resolve_pkg "$desired" netcat-traditional openbsd-netcat gnu-netcat) ;;
      wireshark)            resolved=$(resolve_pkg "$desired" wireshark-qt wireshark wireshark-cli) ;;

      # Utilidades gráficas / sistema
      cherrytree)           resolved=$(resolve_pkg "$desired" cherrytree) ;;
      gparted)              resolved=$(resolve_pkg "$desired" gparted) ;;
      rdesktop)             resolved=$(resolve_pkg "$desired" rdesktop) ;;
      recordmydesktop)      resolved=$(resolve_pkg "$desired" recordmydesktop) ;;
      tightvncserver)       resolved=$(resolve_pkg "$desired" tightvncserver tightvnc) ;;
      xtightvncviewer)      resolved=$(resolve_pkg "$desired" xtightvncviewer tightvnc tigervnc-viewer) ;;

      *)
        resolved=""
        ;;
    esac

    if [[ -n "${resolved:-}" ]]; then
      ok "  $desired  ->  $resolved"
      to_install+=("$resolved")
    else
      warn "  No encontrado: $desired"
      skipped+=("$desired")
    fi
  done

  # Quitar duplicados
  if ((${#to_install[@]} > 0)); then
    mapfile -t to_install < <(printf "%s\n" "${to_install[@]}" | awk '!seen[$0]++')
    info "Instalando paquetes del grupo: ${to_install[*]}"
    paru -S --needed --noconfirm "${to_install[@]}" || warn "Algunos paquetes de '$group_name' fallaron."
  else
    warn "No hay paquetes resolubles para el grupo '$group_name'."
  fi

  if ((${#skipped[@]} > 0)); then
    warn "Omitidos en '$group_name': ${skipped[*]}"
  fi

  echo
}

# =========================================================
# GRUPOS
# =========================================================

RECON=(
  nmap
  zenmap
  cutycapt
  legion
)

ATTACK=(
  burpsuite
  sqlmap
  metasploit-framework
  hydra
  netexec
  responder
  aircrack-ng
  fern-wifi-cracker
  gophish
)

POST=(
  john
  ophcrack
  ophcrack-cli
)

FORENSICS=(
  autopsy
  guymager
  sqlitebrowser
)

NETWORK=(
  tcpdump
  netcat-traditional
  wireshark
)

GUI_SYSTEM=(
  cherrytree
  gparted
  rdesktop
  recordmydesktop
  tightvncserver
  xtightvncviewer
)

# =========================================================
# INSTALACIÓN
# =========================================================
install_group "Reconocimiento / enumeración" "${RECON[@]}"
install_group "Ataque / explotación" "${ATTACK[@]}"
install_group "Post-explotación / credenciales" "${POST[@]}"
install_group "Forense / análisis" "${FORENSICS[@]}"
install_group "Red / soporte" "${NETWORK[@]}"
install_group "Utilidades gráficas / sistema" "${GUI_SYSTEM[@]}"

ok "Proceso terminado."
warn "Revisa la salida: algunos paquetes AUR pueden requerir intervención manual por dependencias antiguas o PKGBUILDs rotos."
