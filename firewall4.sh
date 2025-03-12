#!/bin/sh
## SCRIPT de IPTABLES − ejemplo del manual de iptables
## Ejemplo de script para firewall entre red−local e internet
## con filtro para que solo se pueda navegar.
## Pello Xabier Altadill Izura
## www.pello.info − pello@pello.info

echo "Aplicando Reglas de Firewall..."

. ./iptables_config.sh

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
## Nota: $IFACE_EXTERNA es el interfaz conectado al router y $IFACE_INTERNA a la LAN

# El localhost se deja (por ejemplo conexiones locales a mysql)
/sbin/iptables -A INPUT -i lo -j ACCEPT

# Al firewall tenemos acceso desde la red local
iptables -A INPUT -s "$RED_LOCAL" -i "$IFACE_INTERNA" -j ACCEPT

## Ahora con regla FORWARD filtramos el acceso de la red local
## al exterior. Como se explica antes, a los paquetes que no van dirigidos al
## propio firewall se les aplican reglas de FORWARD

# Aceptamos que vayan a puertos 80
iptables -A FORWARD -s "$RED_LOCAL" -i "$IFACE_INTERNA" -p tcp --dport 80 -j ACCEPT

# Aceptamos que vayan a puertos https
iptables -A FORWARD -s "$RED_LOCAL" -i "$IFACE_INTERNA" -p tcp --dport 443 -j ACCEPT

# Aceptamos que consulten los DNS
iptables -A FORWARD -s "$RED_LOCAL" -i "$IFACE_INTERNA" -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -s "$RED_LOCAL" -i "$IFACE_INTERNA" -p udp --dport 53 -j ACCEPT

# Y denegamos el resto. Si se necesita alguno, ya avisarán
iptables -A FORWARD -s "$RED_LOCAL" -i "$IFACE_INTERNA" -j DROP

# Ahora hacemos enmascaramiento de la red local
# y activamos el BIT DE FORWARDING (imprescindible!!!!!)
iptables -t nat -A POSTROUTING -s "$RED_LOCAL" -o "$IFACE_EXTERNA" -j MASQUERADE

# Con esto permitimos hacer forward de paquetes en el firewall, o sea
# que otras máquinas puedan salir a través del firewall.
echo 1 > /proc/sys/net/ipv4/ip_forward

## Y ahora cerramos los accesos indeseados del exterior:
# Nota: 0.0.0.0/0 significa: cualquier red

# Cerramos el rango de puerto bien conocido
iptables -A INPUT -s 0.0.0.0/0 -p tcp --dport 1:1024 -j DROP
iptables -A INPUT -s 0.0.0.0/0 -p udp --dport 1:1024 -j DROP

# Cerramos un puerto de gestión: webmin
iptables -A INPUT -s 0.0.0.0/0 -p tcp --dport 10000 -j DROP

echo " OK . Verifique que lo que se aplica con: iptables -L -n"
# Fin del script