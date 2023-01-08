#!/usr/bin/env bash

set -e

sudo echo ""
while :; do sudo -v; sleep 59; done &
infiloop=$!

# ------------------------------- VARIÁVEIS -----------------------------------#
SCR_DIRECTORY=`pwd`

#------------------------- APLICAR ATUALIZAÇÕES -------------------------------#
sudo apt update
echo ""
echo "INICIANDO ATUALIZAÇÃO COMPLETA DO SISTEMA..."
echo ""
sudo mintupdate-cli upgrade -r -y
sudo mintupdate-cli upgrade -r -y
sudo apt upgrade -y

#--------------------- INSTALAR PACOTES DO REPOSITÓRIO ------------------------#
echo ""
echo "INSTALANDO PACOTES DO REPOSITÓRIO..."
echo ""
sudo apt install $(cat $SCR_DIRECTORY/pacotes-sem-recommends.txt) --no-install-recommends -y
sudo apt install $(cat $SCR_DIRECTORY/pacotes.txt) -y

#--------------- DESINSTALAR PACOTES DESNECESSÁRIOS - PARTE 1 -----------------#
sudo apt purge $(cat $SCR_DIRECTORY/lista-remocao.txt) -y
sudo apt autoremove --purge -y

#---------------------- INSTALAR PACOTES DO LOCAIS ----------------------------#
echo ""
echo "INSTALANDO PACOTES DO LOCAIS..."
mkdir -p $SCR_DIRECTORY/packages/
cd /tmp
### Google Chrome
wget -c https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
if [[ $? == 0 ]]; then
    mv google-chrome-stable_current_amd64.deb $SCR_DIRECTORY/packages/
fi
### RustDesk
wget -c https://github.com/rustdesk/rustdesk/releases/download/1.1.9/rustdesk-1.1.9.deb
if [[ $? == 0 ]]; then
    mv rustdesk-1.1.9.deb $SCR_DIRECTORY/packages/
fi
cd $SCR_DIRECTORY
ls $SCR_DIRECTORY/packages/*.deb > pacotes-locais.txt
sudo apt install $(cat $SCR_DIRECTORY/pacotes-locais.txt) --no-install-recommends -y

#--------------- DESINSTALAR PACOTES DESNECESSÁRIOS - PARTE 2 -----------------#
sudo apt purge $(cat $SCR_DIRECTORY/lista-remocao.txt) -y
sudo apt autoremove --purge -y

#------------------ AJUSTES EM CONFIGURAÇÕES DO SISTEMA -----------------------#
cd $HOME
sudo chown -R root:root $SCR_DIRECTORY/system-files/
cd $SCR_DIRECTORY/
sudo \cp -rf $SCR_DIRECTORY/system-files/etc/lightdm/ /etc/
sudo \cp $SCR_DIRECTORY/system-files/etc/default/grub /etc/default/grub
sudo \cp $SCR_DIRECTORY/system-files/etc/grub.d/10_linux /etc/grub.d/10_linux
echo "vm.swappiness=25" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_background_ratio=5" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_ratio=10" | sudo tee -a /etc/sysctl.conf
echo lz4hc | sudo tee -a /etc/initramfs-tools/modules
echo lz4hc_compress | sudo tee -a /etc/initramfs-tools/modules
echo z3fold | sudo tee -a /etc/initramfs-tools/modules
sudo update-initramfs -u
sudo update-grub
echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf
#### Configuração Firewall
sudo systemctl enable ufw
sudo ufw enable
#### Ativar atualizações automáticas
sudo mintupdate-automation upgrade enable
sudo mintupdate-automation autoremove enable

#------------------------------------ FIM -------------------------------------#
kill "$infiloop"
clear
echo "Chegamos ao fim."
echo "Você pode reiniciar agora com o comando '/sbin/reboot'."
