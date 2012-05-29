SIL robot
=========

# Legacy cron script (Java robot)


    #!/bin/sh
    
    # FIXME: this should be after the update of the old bills
    java -jar sil.jar
    
    for boletin in `mysql -BNq -usil -psil -e "SELECT nro_boletin FROM ProyectoLey WHERE etapa NOT LIKE 'Archivado' AND etapa NOT LIKE 'Tramitaci%n terminada' AND ley IS NULL AND decreto IS NULL" votainteligente_proyectos`; do
            java -jar sil.jar $boletin
            if [ $? != 0 ]; then
                    echo Error procesando boletín $boletin
                    exit
            fi
    done

# About

Fundación Ciudadano Inteligente

http://www.ciudadanointeligente.org/
