#!/usr/bin/env bash

DOMINIO=$(\
    dialog --erase-on-exit --no-cancel --title "Configurar Active Directory"\
        --inputbox "Insira o domínio:" 8 40\
    3>&1 1>&2 2>&3 3>&- \
)

USUARIO=$(\
    dialog --erase-on-exit --no-cancel --title "Configurar Active Directory"\
        --inputbox "Insira o usuário:" 8 40\
    3>&1 1>&2 2>&3 3>&- \
)

dialog --erase-on-exit --yesno "Deseja adicionar um grupo do domínio ao arquivo sudoers?" 8 60
CONFIGURAR_SUDO=$?
case $CONFIGURAR_SUDO in
    0) GRUPO=$(dialog --erase-on-exit --no-cancel --title "Configurar Active Directory" --inputbox "Insira o grupo:" 8 40 3>&1 1>&2 2>&3 3>&-) ; sudo sed -i "/^%sudo.*ALL*/a %$GRUPO   ALL=(ALL:ALL) ALL" /etc/sudoers;;
    1) echo "Você escolheu não adicionar grupo algum ao arquivo sudoers";;
    255) echo "[ESC] key pressed.";;
esac

sudo apt -y update
sudo apt -y install realmd libnss-sss libpam-sss sssd sssd-tools adcli samba-common-bin oddjob oddjob-mkhomedir packagekit

### Comandos TESTE
echo "sudo realm join -U $USUARIO $DOMINIO"
echo "Senha para $USUARIO: "
read SENHA

### Comando original
sudo realm join -U $USUARIO $DOMINIO

sudo bash -c "cat > /usr/share/pam-configs/mkhomedir" <<EOF
Name: activate mkhomedir
Default: yes
Priority: 900
Session-Type: Additional
Session:
        required                        pam_mkhomedir.so umask=0022 skel=/etc/skel
EOF

sudo pam-auth-update

sudo systemctl restart sssd

echo "Adicionado ao domínio $DOMINIO com sucesso!"