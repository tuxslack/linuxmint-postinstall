#!/usr/bin/env bash

##################################################
# Script para alteração de senha do usuário root #
# Autor: Thiago de S. Ferreira                   #
# E-mail: sousathiago@protonmail.com             #
##################################################


# Verificar se o usuário é o Root

if [[ $EUID -ne 0 ]]; then

   yad --center --title "Erro" --text "Este script precisa ser executado como Root." --button=OK:0 --width 400 --height 100

   exit 1
fi

# Instalar o pacote yad, se não for encontrado no sistema

if ! command -v yad &> /dev/null; then

    sudo apt -y install yad

fi


ALT=1

while [ $ALT = 1 ]
do
    SENHA_ROOT=$(\
        yad --center --no-buttons --title "Definir senha do Root"\
            --form --field="Insira uma senha para o usuário Root":H  --width 400 --height 150\
            --password)

    CONFIRMA_SENHA_ROOT=$(\
        yad --center --no-buttons --title "Definir senha do Root"\
            --form --field="Confirme a senha, digitando-a mais uma vez":H --width 400 --height 150\
            --password)

    if [ "$SENHA_ROOT" = "$CONFIRMA_SENHA_ROOT" ]; then
        ALT=0
    else
        yad --center --title "Erro" --text "As senhas não são iguais. Tente novamente." --button=OK:0 --width 400 --height 100
    fi

done

echo "root:$SENHA_ROOT" | chpasswd

if [ $? = 0 ]; then
    yad --center --title "Sucesso" --text "Senha alterada com sucesso!" --button=OK:0 --width 400 --height 100
fi

