#!/bin/bash

# Directorio donde se van a almacenar los backups
backupfolder=/ruta/que/prefieras

# Notificación Telegram 
API_KEY="API_DEL_BOT"
CHAT_ID="ID_DEL_CANAL"

# MySQL/MariaDB config
user=<USUARIO>
password=<CONTRASEÑA>

# Días de rotación de los backups
keep_days="NÚMERO_DE_DÍAS_QUE_GUARDARÁ_LOS_BACKUPS" #Se indica con el formato: "+n" para guardar las copias de n días.

sqlfile=<NOMBRE_BASE_DE_DATOS>-$(date +%d-%m-%Y_%H-%M-%S).sql
zipfile=<NOMBRE_BASE_DE_DATOS>-$(date +%d-%m-%Y_%H-%M-%S).zip 

# Lanzamos la creación del backup
cd $backupfolder
docker exec mariadb mysqldump -u $user -p$password <NOMBRE_BASE_DE_DATOS> > $sqlfile 

if [ $? == 0 ]; then
  echo 'Backup SQL creado' 
else
  curl -s "https://api.telegram.org/bot$API_KEY/sendMessage?chat_id=$CHAT_ID&text=❌ERROR_AL_HACER_BACKUP"
  exit 
fi 

# Comprimimos el backup
zip $zipfile $sqlfile 
if [ $? == 0 ]; then
  echo 'Backup comprimido correctamente' 
else
  echo 'ERROR al comprimir el backup'
  curl -s "https://api.telegram.org/bot$API_KEY/sendMessage?chat_id=$CHAT_ID&text=❌ERROR_AL_COMPRIMIR"
  exit 
fi 
rm $sqlfile 
echo $zipfile
curl -s "https://api.telegram.org/bot$API_KEY/sendMessage?chat_id=$CHAT_ID&text=✅DB_BACKUP_OK!"

# Rotamos backups 
find $backupfolder -mtime +$keep_days -delete