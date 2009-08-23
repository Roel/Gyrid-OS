#!/bin/sh

dpkg -l > /voyage.dpkg-l
dpkg-query -W --showformat='${Package} ${Version}\n' > /voyage.dpkg.list
	
rm -f /voyage.depends.list
#for DPKG in $( find /var/cache/apt/archives/ -name "*.deb");	 

for DPKG in `find /var/lib/dpkg/info/ -name "*.list" -exec basename '{}' ';' | cut -f 1 -d "."` ; 
do 
	apt-cache show $DPKG 2>/dev/null | egrep "^Package|^Depends"  | sed "s/^Package : //g" >> /voyage.depends.list 
done
