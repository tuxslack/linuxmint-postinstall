#!/usr/bin/env bash

##################################################################
# Script para automatizar o processo de ingressar um computador  #
# rodando Linux (Debian, Ubuntu e derivados) no Active Directory #
# Autor: Thiago de S. Ferreira                                   #
# E-mail: sousathiago@protonmail.com                             #
##################################################################


# Verificar se o usuário é o Root

if [[ $EUID -ne 0 ]]; then

   yad --center --title "Erro" --text "Este script precisa ser executado como Root." --button=OK:0 --width 400 --height 100

   exit 1

fi



# Instalar o pacote yad, se não for encontrado no sistema

if ! command -v yad &> /dev/null; then
    sudo apt -y install yad
fi



# Instalar o pacote lsb-release, necessário para obter nome do SO
if ! command -v lsb_release &> /dev/null; then
    sudo apt -y install lsb-release
fi




altera_dns() {

DNS1=$(yad --center --no-buttons --title "DNS primário" \
--form --field="Insira o servidor DNS primário:":H --width 400 --height 150 )

    
DNS2=$(yad --center --no-buttons --title "DNS secundário" \
--form --field="Insira o servidor DNS secundário (opcional):":H --width 400 --height 150 )

    
    IFS=$'\n'
    
    for CONN_NAME in $(nmcli --fields NAME --terse connection show)
    do
        sudo nmcli connection modify  "$CONN_NAME" ipv4.ignore-auto-dns true
        sudo nmcli connection modify  "$CONN_NAME" ipv4.dns "${DNS1} ${DNS2}"
        sudo nmcli connection down "$CONN_NAME"
        sudo nmcli connection up "$CONN_NAME"
    done
}

dialog_info() {
    yad --center --title "Aviso" --text 'A seguir, insira o servidor DNS para resolver o domínio. Normalmente, o IP do servidor DNS é o mesmo do Controlador de Domínio, a menos que sejam servidores distintos.' --button=OK:0 --width 400 --height 100
}

dialog_info
altera_dns

OS_NAME=$(lsb_release -d -s)

DOMINIO=$(yad --center --no-buttons --title "Ingresso em domínio Active Directory"\
        --form --field="Insira o domínio:":H --width 500 --height 150)

USUARIO=$(yad --center --no-buttons --title "Ingresso em domínio Active Directory" \
        --form --field="Insira um nome de usuário com permissão para ingressar em ${DOMINIO}:":H --width 400 --height 150)

SENHA=$(yad --center --no-buttons --title "Ingresso em domínio Active Directory" \
        --form --field="Senha para $USUARIO:":H --width 500 --height 150 \
        --password)

apt -y update

apt -y install realmd libnss-sss libpam-sss sssd sssd-tools adcli samba-common-bin oddjob oddjob-mkhomedir packagekit


### Comando original

echo $SENHA | realm join --os-name $OS_NAME -U ${USUARIO} ${DOMINIO} 

STATUS=$?

# Habilitar criacao automatica de pastas de usuarios ao fazer logon
if ! grep -q "session.*required.*pam_mkhomedir.so.*umask.*" /etc/pam.d/common-session; then
    echo 'session required                        pam_mkhomedir.so umask=0027 skel=/etc/skel' >> /etc/pam.d/common-session
fi

# Permitir fazer login sem a necessidade de acrescentar o sufixo "@dominio" ao nome de usuário:
sed -i "s/use_fully_qualified_names = True/use_fully_qualified_names = False/g" /etc/sssd/sssd.conf

systemctl restart sssd

if [[ $STATUS == 0 ]]; then
    timeout 10 yad --center --title "Sucesso" --text "Bem-vindo ao domínio ${DOMINIO}!" --button=OK:0 --width 400 --height 100
fi

