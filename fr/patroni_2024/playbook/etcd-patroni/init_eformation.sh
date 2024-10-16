#! /bin/bash
# mise à jour de l'accès ssh par échange de clef

# pré-requis  : sshpass

# -------------
# paramètres : 

# $1 :  numéro de la première vm 
# $2 :  numéro de la dernière vm
# $3 : préfixe du port ssh  : par défaut 22${numero de vm}
# $4 : offset du préfix du port :  par défaut 0
#      si $4 = 10 alors le port ssh devient 22{numero de vm + offset}

# -------------

#set -x

index_from=$1
index_to=$2
prefix=${3:-22}
port_offset=${4:-0}
ip=''
pass=''
echo -n 'public_ip: '
read ip;
echo -n 'formateur plain_test_passwd: '
read pass;

echo 'replacing ip in /etc/hosts:'
sudo sed -i "/eformation/ s/.*/$ip\teformation/g" /etc/hosts

read

for i in $(seq $index_from $index_to)
do 
   let addport=${addport}+${port_offset}
   addport=$(echo -n "00${i}" | tail -c 2)
   ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[eformation]:${prefix}${addport}"
   sshpass -p "$pass" ssh-copy-id -o StrictHostKeyChecking=no -p ${prefix}${addport} formateur@vm$i 
done

# test
for i in $(seq $index_from $index_to)
do 
   addport=$(echo -n "00${i}" | tail -c 2)
	echo -n "vm$i : "
	ssh -p ${prefix}${addport} vm$i 'echo OK' || echo KO
done


