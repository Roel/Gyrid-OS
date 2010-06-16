#!/bin/sh

echo -n "Setting Timezone to Europe/Brussels ... "

TZ=Europe/Brussels
echo $TZ > /etc/timezone
rm -f /etc/localtime
cp -a /usr/share/zoneinfo/$TZ /etc/localtime

echo "Done"
