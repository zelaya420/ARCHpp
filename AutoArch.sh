 (cd "$(git rev-parse --show-toplevel)" && git apply --3way <<'EOF' 
diff --git a/AutoArch.sh b/AutoArch.sh
index 96db62373010036b7cbca2efab7099f7c1897b7e..a8c93af1fa5f3cc4a128da1218202430e463bdc1 100644
--- a/AutoArch.sh
+++ b/AutoArch.sh
@@ -4,123 +4,143 @@ set -euo pipefail
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
+backup_target="$backup_folder/$date_now"
 
 greenColour="\e[0;32m\033[1m"
 endColour="\033[0m\e[0m"
 redColour="\e[0;31m\033[1m"
 blueColour="\e[0;34m\033[1m"
 yellowColour="\e[0;33m\033[1m"
 purpleColour="\e[0;35m\033[1m"
 turquoiseColour="\e[0;36m\033[1m"
 grayColour="\e[0;37m\033[1m"
 
-user="$(whoami)"
-
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
 
+safe_chmod(){
+  local target="$1"
+  if [[ -e "$target" ]]; then
+    chmod +x "$target"
+  fi
+}
+
+safe_chmod_glob(){
+  shopt -s nullglob
+  local files=("$@")
+  if ((${#files[@]} > 0)); then
+    chmod +x "${files[@]}"
+  fi
+  shopt -u nullglob
+}
+
 ensure_paru(){
   if command -v paru >/dev/null 2>&1; then
     return 0
   fi
 
   echo -e "\n${blueColour}[*] Instalando paru (AUR helper)...${endColour}"
   pac_install base-devel git
 
-  cd /tmp
-  rm -rf paru
-  git clone https://aur.archlinux.org/paru.git
-  cd paru
-  makepkg -si --noconfirm --needed
+  local tmp_dir
+  tmp_dir="$(mktemp -d)"
+  git clone https://aur.archlinux.org/paru.git "$tmp_dir/paru"
+  (
+    cd "$tmp_dir/paru"
+    makepkg -si --noconfirm --needed
+  )
+  rm -rf "$tmp_dir"
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
+else
+  git -C "$REPO_DIR" pull --ff-only || true
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
@@ -201,50 +221,60 @@ fi
 # =======================
 
 echo -e "\n${blueColour}[*] Instalando/asegurando paru...${endColour}"
 ensure_paru
 
 # =======================
 #   [7] PAQUETES DEL RICE
 # =======================
 
 echo -e "\n${blueColour}[*] Instalando paquetes del rice (mayoría con paru)...${endColour}"
 
 # Nota: zscroll NO va por AUR roto -> se instala con pipx más abajo.
 paru_install \
   kitty rofi feh thunar xclip ranger brightnessctl fastfetch scrot jq wmname imagemagick cmatrix \
   procps-ng fzf lsd bat pamixer flameshot playerctl dunst gawk zenity \
   bspwm sxhkd geany nvim polybar picom \
   xorg-xsetroot xorg-xrandr xorg-xprop xorg-xwininfo \
   python-pywal python-setuptools \
   betterlockscreen tty-clock alacritty  scrub \
   zsh zsh-syntax-highlighting zsh-autosuggestions firefox \
   rust cargo \
   python-pipx
 
 echo -e "\n${greenColour}[+] Paquetes OK${endColour}"
 
+# =======================
+# BACKUP CONFIGS
+# =======================
+
+echo -e "\n${blueColour}[*] Backup configs...${endColour}"
+mkdir -p "$backup_target"
+for p in bspwm sxhkd polybar eww kitty bin rofi; do
+  [[ -d "$HOME/.config/$p" ]] && cp -r "$HOME/.config/$p" "$backup_target/" || true
+done
+
 
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
@@ -260,76 +290,67 @@ echo -e "${greenColour}[+] zsh listo${endColour}"
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
 
-# =======================
-# BACKUP CONFIGS
-# =======================
-
-echo -e "\n${blueColour}[*] Backup configs...${endColour}"
-mkdir -p "$backup_folder/$date_now"
-for p in bspwm sxhkd polybar eww kitty bin rofi; do
-  [[ -d "$HOME/.config/$p" ]] && cp -r "$HOME/.config/$p" "$backup_folder/$date_now/" || true
-done
-
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
-chmod +x "$HOME/.config/polybar/launch.sh" 2>/dev/null || true
-chmod +x "$HOME/.config/polybar/scripts/"* 2>/dev/null || true
-chmod +x "$HOME/.config/polybar/pywal.sh" 2>/dev/null || true
-chmod +x "$HOME/.config/bin/"* 2>/dev/null || true
-chmod +x "$HOME/.config/rofi/launcher.sh" "$HOME/.config/rofi/powermenu.sh" 2>/dev/null || true
-chmod +x "$HOME/.config/asciiart/"* 2>/dev/null || true
-chmod +x "$HOME/.config/colorscript" 2>/dev/null || true
-chmod +x "$HOME/.config/eww/profilecard/scripts/"* 2>/dev/null || true
+safe_chmod "$HOME/.config/polybar/launch.sh"
+safe_chmod_glob "$HOME/.config/polybar/scripts/"*
+safe_chmod "$HOME/.config/polybar/pywal.sh"
+safe_chmod_glob "$HOME/.config/bin/"*
+safe_chmod "$HOME/.config/rofi/launcher.sh"
+safe_chmod "$HOME/.config/rofi/powermenu.sh"
+safe_chmod_glob "$HOME/.config/asciiart/"*
+safe_chmod "$HOME/.config/colorscript"
+safe_chmod_glob "$HOME/.config/eww/profilecard/scripts/"*
 
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
 
EOF
)
