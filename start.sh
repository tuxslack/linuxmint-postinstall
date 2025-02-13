#!/usr/bin/env bash

##########################################
# Script de Pós-instalação do Linux Mint #
# Autor: Thiago de S. Ferreira           #
# E-mail: sousathiago@protonmail.com     #
##########################################


# yad oferece uma interface gráfica que pode ser mais amigável para os usuários em comparação com o dialog.


#------------------------- INSTALAR O PACOTE "yad" -------------------------#

# Instalar o pacote yad, se não for encontrado no sistema

if ! command -v yad &> /dev/null; then

    yad --center --title "Erro" --text "Este script precisa do yad." --button=OK:0 --width="400" --height="100"

    sudo apt -y install yad

    # exit

fi

#--------------------------------- ROOT ----------------------------------#

# Verificar se o usuário é o Root

if [[ $EUID -ne 0 ]]; then

   yad --center --title "Erro" --text "Este script precisa ser executado como Root." --button=OK:0 --width="400" --height="100"

   exit 1
fi



#--------------------------------- VARIÁVEIS ----------------------------------#
SCR_DIRECTORY=`pwd`

#------------------- ATUALIZAR BASE DE DADOS DO REPOSITÓRIO -------------------#
apt update -y

#--------------------------- ALTERAR SENHA DO ROOT ----------------------------#

bash "${SCR_DIRECTORY}"/senha_root.sh

#--------------------------- DEFINIR NOVO HOSTNAME ----------------------------#
OLD_HOSTNAME=`hostname`


NEW_HOSTNAME=$(\
yad --center --no-buttons --title "Definir hostname" \
--entry --text "Insira o nome do computador:" --width="300" --height="100"
)


echo ""
sed -i "s/${OLD_HOSTNAME}/${NEW_HOSTNAME}/g" /etc/hosts
hostnamectl set-hostname ${NEW_HOSTNAME}
echo "Novo HOSTNAME definido como ${NEW_HOSTNAME}"

#---------------------------- OCS-INVENTORY AGENT -----------------------------#

INSTALL_OCS=$(\
yad --center --title "Instalar OCS Inventory Agent" \
--question --text "Deseja instalar o OCS Inventory Agent?" --button=Sim:0 --button=Não:1 --width="400" --height="100"
)

INSTALL_OCS=$?
case $INSTALL_OCS in
    0) apt install -y ocsinventory-agent ; dpkg-reconfigure ocsinventory-agent ; ocsinventory-agent;;
    1) echo "Você escolheu não instalar o OCS Inventory Agent.";;
    255) echo "[ESC] key pressed.";;
esac

#------------------------------ ACTIVE DIRECTORY ------------------------------#

JOIN_AD=$(\
yad --center --title "Ingressar no Active Directory" \
--question --text "Deseja ingressar este computador em um domínio Active Directory?" --button=Sim:0 --button=Não:1 --width="400" --height="100"
)

JOIN_AD=$?
##### Copiar arquivo de config. Network Manager para corrigir erro do DNS
\cp -rf "${SCR_DIRECTORY}"/system-files/etc/NetworkManager/ /etc/
rm /etc/resolv.conf
systemctl restart NetworkManager.service
case $JOIN_AD in
    0) bash "${SCR_DIRECTORY}"/active_directory.sh;;
    1) echo "Você escolheu não ingressar no Active Directory";;
    255) echo "[ESC] key pressed.";;
esac

#--------------------- INSTALAR PACOTE DE FONTES MICROSOFT --------------------#
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections
apt install -y ttf-mscorefonts-installer

#---------------------------- APLICAR ATUALIZAÇÕES ----------------------------#
echo ""
echo "INICIANDO ATUALIZAÇÃO COMPLETA DO SISTEMA..."
echo ""
mintupdate-cli upgrade -r -y
mintupdate-cli upgrade -r -y
apt upgrade -y

#---------------------- INSTALAR PACOTES DO REPOSITÓRIO -----------------------#
echo ""
echo "INSTALANDO PACOTES DO REPOSITÓRIO..."
echo ""
apt install $(cat "${SCR_DIRECTORY}"/pacotes_sem_recommends.txt) --no-install-recommends -y
apt install $(cat "${SCR_DIRECTORY}"/pacotes.txt) -y

#---------------- DESINSTALAR PACOTES DESNECESSÁRIOS - PARTE 1 ----------------#
apt purge $(cat "${SCR_DIRECTORY}"/pacotes_remover.txt) -y
apt autoremove --purge -y

#------------------------- INSTALAR PACOTES DO LOCAIS -------------------------#
echo ""
echo "INSTALANDO PACOTES DO LOCAIS..."
cd "${SCR_DIRECTORY}"
grep -v '^#' pacotes_baixar.txt | wget -i - -P pacotes
apt install "${SCR_DIRECTORY}"/pacotes/*.deb --no-install-recommends -y

# Remover impressoras adicionadas automaticamente
lpadmin -x DCPL5652DN
lpadmin -x HLL6202DW
lpadmin -x HLL6402DW

#---------------- DESINSTALAR PACOTES DESNECESSÁRIOS - PARTE 2 ----------------#
apt purge $(cat "${SCR_DIRECTORY}"/pacotes_remover.txt) -y
apt autoremove --purge -y

#-------------------- AJUSTES EM CONFIGURAÇÕES DO SISTEMA ---------------------#
# Copia de arquivos de configuração diversos para o sistema

cd $HOME
chown -R root:root "${SCR_DIRECTORY}"/system-files/
cd "${SCR_DIRECTORY}"/

# Configuração para exibir todos os aplicativos de inicialização
sed -i "s/NoDisplay=true/NoDisplay=false/g" /etc/xdg/autostart/*.desktop

# Configuração do gerenciador de telas LightDM (tela de login)
\cp -rf "${SCR_DIRECTORY}"/system-files/etc/lightdm/ /etc/

# Configuração de políticas de navegadores Firefox e Google Chrome
\cp -rf "${SCR_DIRECTORY}"/system-files/etc/firefox/ /etc/
\cp -rf "${SCR_DIRECTORY}"/system-files/etc/opt/ /etc/
chmod -R 755 /etc/firefox/
chmod 644 /etc/firefox/policies/policies.json
chmod -R 755 /etc/opt/
chmod 644 /etc/opt/chrome/policies/*/*.json

# Configurações padrão dos usuários
\cp -rf "${SCR_DIRECTORY}"/system-files/etc/skel/ /etc/
\cp -rf "${SCR_DIRECTORY}"/system-files/etc/dconf/ /etc/
chmod 755 /etc/dconf/profile/
chmod 755 /etc/dconf/db/local.d/
dconf update

# Instalação de certificados CA local
rm -f "${SCR_DIRECTORY}"/system-files/usr/local/share/ca-certificates/empty
\cp -rf "${SCR_DIRECTORY}"/system-files/usr/local/share/ca-certificates/* /usr/local/share/ca-certificates/
update-ca-certificates

# Configurar navegadores para utilizar repositório de certificados CA do sistema
\cp -rf "${SCR_DIRECTORY}"/system-files/usr/local/bin/fix-browsers-ca-trust.sh /usr/local/bin
chmod +x /usr/local/bin/fix-browsers-ca-trust.sh
/usr/local/bin/fix-browsers-ca-trust.sh

# Ativar ZSWAP e configurar parâmetros de swap e cache
\cp "${SCR_DIRECTORY}"/system-files/etc/default/grub /etc/default/grub
echo "vm.swappiness=25" | tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | tee -a /etc/sysctl.conf
echo "vm.dirty_background_ratio=5" | tee -a /etc/sysctl.conf
echo "vm.dirty_ratio=10" | tee -a /etc/sysctl.conf
echo lz4hc | tee -a /etc/initramfs-tools/modules
echo lz4hc_compress | tee -a /etc/initramfs-tools/modules
echo z3fold | tee -a /etc/initramfs-tools/modules
update-initramfs -u
update-grub

# Habilitar firewall
systemctl enable ufw
ufw enable

# Ativar atualizações automáticas
mintupdate-automation upgrade enable
mintupdate-automation autoremove enable

# Desativar serviço de detecção/instalação automática de impressora
systemctl disable cups-browsed.service

# Desativar driver problemático do CUPS
mkdir -p /usr/lib/cups/driver/disabled
mv /usr/lib/cups/driver/driverless /usr/lib/cups/driver/disabled/

# Antivirus
\cp -rf "${SCR_DIRECTORY}"/system-files/etc/clamav/ /etc/
\cp -rf "${SCR_DIRECTORY}"/system-files/etc/systemd/ /etc/
chmod +x /etc/clamav/virus-event.bash
systemctl daemon-reload
systemctl stop clamav-freshclam
freshclam
systemctl enable --now clamav-freshclam
systemctl enable clamav-daemon
systemctl restart clamav-daemon
systemctl enable clamav-clamonacc.service
systemctl restart clamav-clamonacc.service
chown -R 1000:1000 "${SCR_DIRECTORY}"/
chmod -R 777 "${SCR_DIRECTORY}"/

#------------------------------------ FIM -------------------------------------#

REBOOT=$(\
yad --center --title "Reiniciar o sistema" \
--question --text "Chegamos ao fim. É necessário reiniciar o computador para aplicar as alterações. Deseja reiniciar agora?" --button=Sim:0 --button=Não:1 --width="400" --height="100"
)


REBOOT=$?
case $REBOOT in
    0) systemctl reboot;;
    1) echo "Por favor reinicie o sistema assim que possível.";;
    255) echo "[ESC] key pressed.";;
esac

exit 0

