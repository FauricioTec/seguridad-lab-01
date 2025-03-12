#!/bin/sh
## SCRIPT de IPTABLES − ejemplo del manual de iptables
## Ejemplo de firewall entre red−local e internet con redirección de puertos (DNAT).
##
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
## Nota: $IFACE_EXTERNA es la interfaz conectada al router y $IFACE_INTERNA a la LAN

# El localhost se deja (por ejemplo, conexiones locales a MySQL)
/sbin/iptables -A INPUT -i lo -j ACCEPT

# Al firewall tenemos acceso desde la red local
iptables -A INPUT -s "$RED_LOCAL" -i "$IFACE_INTERNA" -j ACCEPT

## Redirección de puertos (DNAT)
# Redirigimos tráfico entrante en el puerto 80 hacia una máquina interna
iptables -t nat -A PREROUTING -i "$IFACE_EXTERNA" -p tcp --dport 80 -j DNAT --to-destination "$IP_MAQUINA_LOCAL":80

# Permitimos el tráfico redirigido
iptables -A FORWARD -p tcp -d "$IP_MAQUINA_LOCAL" --dport 80 -j ACCEPT

# Permitimos administración remota en SSH (puerto 22)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Ahora hacemos enmascaramiento de la red local y activamos el BIT DE FORWARDING
iptables -t nat -A POSTROUTING -s "$RED_LOCAL" -o "$IFACE_EXTERNA" -j MASQUERADE

# Permitimos forward de paquetes en el firewall
echo 1 > /proc/sys/net/ipv4/ip_forward

## Cerramos accesos no deseados desde el exterior
iptables -A INPUT -s 0.0.0.0/0 -p tcp --dport 1:1024 -j DROP
iptables -A INPUT -s 0.0.0.0/0 -p udp --dport 1:1024 -j DROP

# Cerramos un puerto de gestión: webmin
iptables -A INPUT -s 0.0.0.0/0 -p tcp --dport 10000 -j DROP

echo " OK . Verifique que lo que se aplica con: iptables -L -n"
# Fin del script