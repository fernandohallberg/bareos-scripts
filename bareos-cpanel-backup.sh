#!/bin/bash
#
# Backup do CPANEL utilizando BAREOS
#
# o CPANEL vai gerar os arquivos das contas / bancos de dados sem o homedir
# e o BAREOS vai pegar o rsync do /home
#
# Requisitos:
#    bareos-client
#    criar pasta /backup com espaco suficiente
#
#   Autor: Fernando Hallberg <fernando@webgenium.com.br>
###

BKPDIR=/backup
WHMAPI1=/usr/sbin/whmapi1
PKGACCT=/scripts/pkgacct

[ -d $BKPDIR/accounts ] || mkdir -p $BKPDIR/accounts

# verificar espaco em disco

free=$(df -P $BKPDIR | awk 'NR==2 { print $4}')
mysqlspace=$(du -s /var/lib/mysql | awk '{ print $1; }' )
need=$(($mysqlspace))

if [ $free -lt $need ];
then
        echo "Espaco insuficiente para realizacao do backup. verifique"
        exit 1
fi

rm -rf $BKPDIR/accounts/*

$WHMAPI1 listaccts | grep "user: " | tr -d " " | cut -d: -f2 | while read usr;
do
        echo -n "[$usr]: "
        $PKGACCT --skiphomedir $usr $BKPDIR/accounts 2>&1 > $BKPDIR/accounts/backup-$usr.log
        retval=$?
        if [ $retval == 0 ];
        then
                echo "OK"
        else
                echo "ERRO: $retval"
                exit $retval
        fi
done
