#!/bin/sh

echo -n "Setting Timezone to GMT ... "

TZ=GMT
echo $TZ > /etc/timezone
rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/$TZ /etc/localtime

echo "Done"
