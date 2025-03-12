#!/bin/sh
## SCRIPT de IPTABLES − ejemplo del manual de iptables
## Ejemplo de script para firewall entre red−local e internet con DMZ
## pero con IPs públicas.
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
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P POSTROUTING ACCEPT

## Empezamos a filtrar
## Nota: $IFACE_EXTERNA es la interfaz conectada al router y $IFACE_INTERNA a la LAN

# El localhost se deja (por ejemplo, conexiones locales a MySQL)
/sbin/iptables -A INPUT -i lo -j ACCEPT

# Al firewall tenemos acceso desde la red local
iptables -A INPUT -s "$RED_LOCAL" -i "$IFACE_INTERNA" -j ACCEPT

# Ahora hacemos enmascaramiento de la red local y de la DMZ
# para que puedan salir hacia afuera y activamos el BIT DE FORWARDING
iptables -t nat -A POSTROUTING -s "$RED_LOCAL" -o "$IFACE_EXTERNA" -j MASQUERADE
iptables -t nat -A POSTROUTING -s 212.194.89.152 -o "$IFACE_EXTERNA" -j MASQUERADE

# Con esto permitimos hacer forward de paquetes en el firewall, o sea
# que otras máquinas puedan salir a través del firewall.
echo 1 > /proc/sys/net/ipv4/ip_forward

## Permitimos el acceso desde el exterior a los puertos 80 y 443 de DMZ
iptables -A FORWARD -d 212.194.89.152 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -d 212.194.89.152 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -d 212.194.89.150/30 -j DROP

## Permitimos el paso de la DMZ a una BBDD de la LAN:
iptables -A FORWARD -s 212.194.89.152 -d 192.168.10.5 -p tcp --dport 5432 -j ACCEPT

# En el otro sentido lo mismo
iptables -A FORWARD -s 192.168.10.5 -d 212.194.89.152 -p tcp --sport 5432 -j ACCEPT

## Permitimos abrir el Terminal Server de la DMZ desde la LAN
iptables -A FORWARD -s "$RED_LOCAL" -d 212.194.89.152 -p tcp --sport 1024:65535 --dport 3389 -j ACCEPT

# ... hay que hacerlo en uno y otro sentido ...
iptables -A FORWARD -s 212.194.89.152 -d "$RED_LOCAL" -p tcp --sport 3389 --dport 1024:65535 -j ACCEPT

# ... por que luego:
# Cerramos el acceso de la DMZ a la LAN
iptables -A FORWARD -s 212.194.89.152 -d "$RED_LOCAL" -j DROP

## Cerramos el acceso de la DMZ al propio firewall
iptables -A INPUT -s 212.194.89.152 -i eth2 -j DROP

## Y ahora cerramos los accesos indeseados del exterior:
# Nota: 0.0.0.0/0 significa: cualquier red

# Cerramos el rango de puertos bien conocidos
iptables -A INPUT -s 0.0.0.0/0 -p tcp --dport 1:1024 -j DROP
iptables -A INPUT -s 0.0.0.0/0 -p udp --dport 1:1024 -j DROP

# Cerramos un puerto de gestión: webmin
iptables -A INPUT -s 0.0.0.0/0 -p tcp --dport 10000 -j DROP

echo " OK . Verifique que lo que se aplica con: iptables -L -n"
# Fin del script
