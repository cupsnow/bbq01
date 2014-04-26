#!/bin/bash

EPOCHDAY=$(( `date +%s` / 86400))
INLOGIN=
INPASS=
INUID=
INGID=
INHOME=

echo -n "" > passwd
echo -n "" > shadow
echo "input <login> <pass> <uid> <gid> <home>, ctrl-c to terminate"
while true; do
  read -p "  : " INLOGIN INPASS INUID INGID INHOME
  echo "$INLOGIN:x:$INUID:$INGID:$INLOGIN:$INHOME:/bin/sh" >> passwd
  echo "$INLOGIN:`openssl passwd -1 -salt xxxxxxxx $INPASS`:$EPOCHDAY:0:99999::::" >> shadow  
done
