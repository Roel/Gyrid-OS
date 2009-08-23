#!/bin/sh

PRISM54_FIRMWARE_URL="http://jbnote.free.fr/prism54usb/data/firmwares/p54pci_1.0.4.3.arm"
#PRISM54_FIRMWARE_URL="http://prism54.org/~mcgrof/firmware/1.0.4.3.arm"
#PRISM54_FIRMWARE_URL="http://ruslug.rutgers.edu/~mcgrof/802.11g/firmware/1.0.4.3.arm"

echo -n "Downloading Firmware from Prism54.org ... "

wget "$PRISM54_FIRMWARE_URL" \
	-O /usr/lib/hotplug/firmware/isl3890
	
echo "Done"