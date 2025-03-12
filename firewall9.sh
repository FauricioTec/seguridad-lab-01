#!/bin/sh
## SCRIPT de IPTABLES − ejemplo del manual de iptables
## Ejemplo de script para firewall entre redes.
##
## Pello Xabier Altadill Izura
## www.pello.info − pello@pello.info

. ./iptables_config.sh

echo "Aplicando Reglas de Firewall..."

## FLUSH de reglas
iptables -F
iptables -X
iptables -Z
iptables -t nat -F

## Establecemos política por defecto
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

## Empezamos a filtrar
## Nota: $IFACE_EXTERNA es la interfaz conectada al router y $IFACE_INTERNA a la LAN

# A nuestro firewall tenemos acceso total desde nuestra IP
iptables -A INPUT -s "$IP_MAQUINA_LOCAL" -j ACCEPT

# Para el resto no hay acceso al firewall
iptables -A INPUT -s 0.0.0.0/0 -j DROP

## Ahora podemos ir metiendo las reglas para cada servidor
## Como serán paquetes con destino a otras máquinas se aplica FORWARD

## Servidor WEB 211.34.149.2
# Acceso a puerto 80
iptables -A FORWARD -d 211.34.149.2 -p tcp --dport 80 -j ACCEPT
# Acceso a nuestra IP para gestionarlo
iptables -A FORWARD -s "$IP_MAQUINA_LOCAL" -d 211.34.149.2 -p tcp --dport 22 -j ACCEPT
# El resto, cerrar
iptables -A FORWARD -d 211.34.149.2 -j DROP

## Servidor MAIL 211.34.149.3
# Acceso a puerto 25, 110 y 143
iptables -A FORWARD -d 211.34.149.3 -p tcp --dport 25 -j ACCEPT
iptables -A FORWARD -d 211.34.149.3 -p tcp --dport 110 -j ACCEPT
iptables -A FORWARD -d 211.34.149.3 -p tcp --dport 143 -j ACCEPT
# Acceso a gestión SNMP
iptables -A FORWARD -s "$IP_MAQUINA_LOCAL" -d 211.34.149.3 -p udp --dport 169 -j ACCEPT
# Acceso a nuestra IP para gestionarlo
iptables -A FORWARD -s "$IP_MAQUINA_LOCAL" -d 211.34.149.3 -p tcp --dport 22 -j ACCEPT
# El resto, cerrar
iptables -A FORWARD -d 211.34.149.3 -j DROP

## Servidor IRC 211.34.149.4
# Acceso a puertos IRC
iptables -A FORWARD -d 211.34.149.4 -p tcp --dport 6666:6668 -j ACCEPT
# Acceso a nuestra IP para gestionarlo
iptables -A FORWARD -s "$IP_MAQUINA_LOCAL" -d 211.34.149.4 -p tcp --dport 22 -j ACCEPT
# El resto, cerrar
iptables -A FORWARD -d 211.34.149.4 -j DROP

## Servidor NEWS 211.34.149.5
# Acceso a puerto news
iptables -A FORWARD -d 211.34.149.5 -p tcp --dport news -j ACCEPT
# Acceso a nuestra IP para gestionarlo
iptables -A FORWARD -s "$IP_MAQUINA_LOCAL" -d 211.34.149.5 -p tcp --dport 22 -j ACCEPT
# El resto, cerrar
iptables -A FORWARD -d 211.34.149.5 -j DROP

## Servidor B2B 211.34.149.6
# Acceso a puerto 443
iptables -A FORWARD -d 211.34.149.6 -p tcp --dport 443 -j ACCEPT
# Acceso a una IP para gestionarlo
iptables -A FORWARD -s 81.34.129.56 -d 211.34.149.6 -p tcp --dport 3389 -j ACCEPT
# El resto, cerrar
iptables -A FORWARD -d 211.34.149.6 -j DROP

## Servidor CITRIX 211.34.149.7
# Acceso a puerto 1494
iptables -A FORWARD -d 211.34.149.7 -p tcp --dport 1494 -j ACCEPT
# Acceso a una IP para gestionarlo
iptables -A FORWARD -s 195.55.234.2 -d 211.34.149.7 -p tcp --dport 3389 -j ACCEPT
# Acceso a otro puerto quizás de BBDD
iptables -A FORWARD -s 195.55.234.2 -d 211.34.149.7 -p tcp --dport 1434 -j ACCEPT
iptables -A FORWARD -s 195.55.234.2 -d 211.34.149.7 -p udp --dport 1433 -j ACCEPT
# El resto, cerrar
iptables -A FORWARD -d 211.34.149.7 -j DROP

echo " OK . Verifique que lo que se aplica con: iptables -L -n"
# Fin del script