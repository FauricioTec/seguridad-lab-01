#!/bin/sh
## SCRIPT de IPTABLES − ejemplo del manual de iptables
## Ejemplo de script para proteger la propia máquina
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
# El localhost se deja (por ejemplo conexiones locales a mysql)
iptables -A INPUT -i lo -j ACCEPT

# Permitimos todo el tráfico desde nuestra propia IP
iptables -A INPUT -s "$IP_MAQUINA_LOCAL" -j ACCEPT

# A un colega le dejamos entrar al mysql para que mantenga la BBDD
iptables -A INPUT -s "$IP_SEGUNDA_MAQUINA" -p tcp --dport 3306 -j ACCEPT

# A un diseñador le dejamos usar el FTP
iptables -A INPUT -s "$IP_SEGUNDA_MAQUINA" -p tcp --dport 20:21 -j ACCEPT

# Permitimos acceso HTTP (servidor web)
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Bloqueamos otros accesos sensibles
iptables -A INPUT -p tcp --dport 20:21 -j DROP  # FTP
iptables -A INPUT -p tcp --dport 3306 -j DROP  # MySQL
iptables -A INPUT -p tcp --dport 22 -j DROP  # SSH
iptables -A INPUT -p tcp --dport 10000 -j DROP  # Webmin u otros servicios

echo "Reglas aplicadas correctamente. Verifique con: iptables -L -n"