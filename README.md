# Backup-plan
## Descripción

Se trata de mi plan de respaldo para el homelab. Tratando de detallar lo máximo posible los procesos y la estructura de los backups, de forma que se reduzcan al máximo las posibilidades de pérdida de datos en caso de ocurrir algún desastre.

## ¿Cómo surge la idea?

Actualmente tengo un servidor unRaid con 12TB de capacidad, un disco de paridad de 4TB, lo que me permite soportar el fallo de 1 disco y cuento con un SSD de 480GB como caché donde corren los contenedores Docker, las bases de datos y el propio caché del array.

Además de esto, tengo un Levono Thinkcentre M910q con Proxmox instalado con la idea en un futuro de ampliar formando un clúster de varios equipos similares.

En mi servidor principal donde tengo unRaid es donde he estado almacenando todo mi contenido digital estos últimos años y, salvo algún disco que ha fallado y he reemplazado, no he tenido ningún susto mayor. Y gracias al disco de paridad no tuve que sufrir la pérdida de ningún archivo.

Sin embargo, al ver cómo crece con el tiempo el tamaño de las carpetas y siendo ya padre, te da pavor la idea de que un día puedas perder alguno de tus archivos importantes.

Y cuando hablamos de archivos importantes no hablamos de la configuración de un dispositivo o un servicio. Eso es algo que, con mayor o menor trabajo, puedes volver a poner en marcha. Hablamos de fotos de tus seres queridos, documentos bancarios, burocráticos o escolares, además de tu trabajo o hobbies que tanto tiempo te han llevado conseguirlos.

La verdad es que mentiría si no dijera que más de una noche me ha quitado el sueño la idea de que un día encienda el PC y vea que uno varios discos han fallado (cosa poco probable, pero no imposible) o que el disco que ha fallado es el de paridad y si algo ocurre mientras aún no lo he reemplazado perderé algo. Y me diréis, puedes añadir un segundo disco de paridad y tenéis toda la razón, pero ¿qué ocurriría si hablamos de algún otro desastre como una inundación o un incendio? No importa cuántos discos de paridad o copias de seguridad tengas en casa, **lo perderías todo**.

Por eso empecé a buscar información sobre qué sistema de backups llevaba a cabo el resto de gente que tiene servidores en casa con el fin de buscar unas guías o buenas prácticas que me dieran la confianza y seguridad suficientes como para saber que prácticamente las únicas causas de pérdida de información fueran una Guerra Mundial o una invasión alienígena...algo muy poco probable.

## El método del 3-2-1

Después de haber indagado bastante he visto que lo más recomendable es llevar a cabo el llamado método del 3-2-1.

Es un sistema muy simple, se trata de tener las copias de seguridad replicadas y distribuidas de la siguiente forma:

* Tener al menos **3 copias** de tus archivos (los originales no cuentan).
* **2 de estas copias** deben estar **en medios distintos** (un NAS y un HDD externo, por ejemplo).
* **1 copia en remoto** (cualquier servicio cloud u otro servidor lejos de las otras copias).

Este método minimiza en gran medida la posibilidad de perder información. Pues si falla tu copia principal, tienes la secundaria. Y si por algún motivo ambas han fallado sigues teniendo la copia remota.

En mi caso tengo *3 copias* en total, aunque difiere un poco del estándar.

* 1 copia está en casa, en un HDD externo en el servidor Proxmox.
* 1 copia está en casa de mis padres en un servidor Proxmox que yo administro. Es una copia híbrida porque es remota, pero con fácil acceso a la misma tanto en físico como en remoto y sin depender de servicios cloud de terceros.
* 1 copia está en Google Drive.

*Nota: las copias que no están en casa (la de casa de mis padres y la de Google Drive) están encriptadas para evitar que una tercera persona pueda acceder a la información.*

## Comprueba la fiabilidad de todas las copias

¡Cuidado! No digo que borres los datos originales, pero sí que debes comprobar que el proceso de recuperación de tus copias de seguridad es fiable y funcionará llegado el momento de necesitarlos.

Lo que yo hago es crear una VM simulando que es un PC o servidor nuevos y desde ella poner en marcha los servicios necesarios para la recuperación de las copias de seguridad y probar una por una que todas funcionan. No las hago por completo, pero sí que cojo varios archivos al azar de cada una de ellas a modo de pequeñas muestras.

## Software utilizado

Actualmente utilizo una mezcla de servicios y scripts.

- Para los archivos que viven permanentemente en el SSD de caché del servidor como son los **contenedores Docker** y las **bases de datos** uso dos opciones distintas que se llevan a cabo cada noche (***hablaremos de las bases de datos en otro punto más adelante***).

 En el caso de los contenedores Docker uso primero **Duplicati** que lleva una copia de las carpetas de configuración al array de discos principal del servidor, que está protegido por el disco de paridad.

- Para las bases de datos diferenciaremos entre las genéricas (archivos .db) y las SQL que gestiono con MariaDB.

    1) Las copias de las bases de datos genéricas (.db) se llevan a cabo de la misma forma que los contenedores Docker (punto anterior).

    2) Las copias de las bases de datos SQL se llevan a cabo mediante un script que hace lo siguiente:

    * Llama al servicio de MariaDB que se encarga de realizar la copia de seguridad.
      
    * Comprime la copia en un archivo ZIP.

    * Notifica por **Telegram** a través de un **Bot** y un **canal** si se han realizado correctamente o si ha ocurrido un error (***opcional***).
      
    * Borra las copias de seguridad que tengan más de los días indicados.
      
      Se ejecuta con un *cronjob*.
    
      Este script se encuentra en el archivo *db_backup.sh*.

  Una vez tengo el dump de las bases de datos (copia de seguridad realizada con el script) uso **Duplicati** de nuevo para llevar una al array princpal del servidor.

- Para los archivos que están en el array de discos principal del servidor uso **Duplicati** y **Syncthing**. *Aquí ya tengo cubierto todo lo importante, porque en el punto anterior ya han sido movidos los archivos de Docker al array principal*.

    1) **Duplicati:**
      Con él hago una copia encriptada en **Google Drive**. Con este punto cubro la **tercera copia en remoto**.

    2) **Syncthing:**
      Lo tengo configurado para que las carpetas de origen estén en modo ***"Sólo enviar*** y las carpetas de destino en modo ***"Sólo recibir*** y con esto me aseguro de que si por error se borra algún arhcivo en las carpetas de destino no se van a borrar en las de origen, pero sí que se borran cuando en las de origen se eliminan.

      Tengo configurados dos **equipos remotos** en Syncthing de forma que con éstos tengo cubiertas las **2 copias en medios distintos** y, sumado al punto anterior, he cubierto por completo el **método 3-2-1**.

    * Equipo remoto 1:
      Se trata de mi servidor Proxmox corriendo una VM de Ubuntu con Portainer y Syncthing a la que le tengo hecho passthrough de un HDD externo.

    * Equipo remoto 2:
      Se trata del servidor Proxmox de casa de mis padres, también con Portainer y Syncthing. Estas copias están **encriptadas**.