#!/bin/bash

exit_on_fail() {
    #Exit if previous command was unsuccessful.
    if [ $? != 0 ]; then

        #Disable swap
        if [ -f $MOUNTPOINT/swap ]; then
            swapoff $MOUNTPOINT/swap
        fi

        umount -l /dev/usbstick
        exit 1
    fi
}

privileged_usb() {
    if [ -e $MOUNTPOINT/cmd.txt -a -e $MOUNTPOINT/cmd.sig -a "$1" != "cron" ]; then
        #Do not handle privileged USB drive through cron.

        gpg --verify $MOUNTPOINT/cmd.sig $MOUNTPOINT/cmd.txt
        if [ "$?" == "0" ]; then
            #Privileged USB drive found.

            #Copy instructions to /tmp and make executable.
            cp $MOUNTPOINT/cmd.txt /tmp
            exit_on_fail
            chmod +x /tmp/cmd.txt

            #Check for options.
            quiet=false
            readout=false
            for opt in `sed -n '/^##/ { s/##//p }' /tmp/cmd.txt`; do
                case "$opt" in
                    "quiet")
                        quiet=true
                        ;;
                    "readout")
                        readout=true
                        ;;
                esac
            done

            #Execute instructions.
            if [ $readout == true ]; then
                temporary_usb
            fi

            if [ $quiet == true ]; then
                /tmp/cmd.txt &> /dev/null
            else
                /tmp/cmd.txt &> $MOUNTPOINT/`hostname`-`date +%Y%m%d-%H%M-%Z`-output.txt
            fi

            #Remove instructions.
            rm /tmp/cmd.txt

            #Unmount USB drive.
            umount -l /dev/usbstick

            exit 0
        fi
    fi
}

permanent_usb() {
    if [ "$1" == "cron" ]; then
        #Only interact with permanent USB drive through cron.
        cd $MOUNTPOINT

        #Build directory variables.
        DATAPATH="`hostname`-`date +%Y%m%d-%H%M-%Z`"
        LASTEXDIR="`ls -d1 $(hostname)-* | tail -n 1`"

        #Copy last existing directory to new directory using
        #hard links.
        if [ "$LASTEXDIR" != "" ]; then
            cp -al $LASTEXDIR $DATAPATH
            RSYNCLINKS="--link-dest=$MOUNTPOINT/$LASTEXDIR"
        else
            mkdir $DATAPATH
            RSYNCLINKS=""
        fi

        #Rsync the log directory on the device with the new
        #directory.
        rsync -a $RSYNCLINKS --delete "/var/log/gyrid/" $DATAPATH
    fi
}

temporary_usb() {
    #Do not interact with temporary USB drive through cron.
    if [ "$1" != "cron" ]; then
        #Start LED flashing
        touch /tmp/gyrid-led-disabled
        echo heartbeat > /sys/class/leds/alix\:1/trigger
        echo heartbeat > /sys/class/leds/alix\:2/trigger
        echo heartbeat > /sys/class/leds/alix\:3/trigger

        #Create log directory on USB device.
        DATADIR="`hostname`-`date +%Y%m%d-%H%M-%Z`"
        export DATAPATH=$MOUNTPOINT/$DATADIR
        mkdir $DATAPATH

        #Copy over the logs.
        mkdir -p $DATAPATH/original_logs
        mkdir -p $DATAPATH/original_logs/gyrid
        mkdir -p $DATAPATH/merged_logs
        tar --dereference --hard-dereference --exclude=gyrid -cj -f $DATAPATH/original_logs/var_log.tar.bz2 /var/log/
        tar --dereference --hard-dereference -cj -f $DATAPATH/original_logs/etc.tar.bz2 /etc/
        rsync -a --copy-links /var/log/gyrid/* $DATAPATH/original_logs/gyrid

        #Merge the logs.
        for i in `ls -1 $DATAPATH/original_logs/gyrid | grep -E "([0-9A-F]){12}"`; do
            mkdir -p $DATAPATH/merged_logs/$i
            cd $DATAPATH/original_logs/gyrid/$i

                /usr/sbin/gyrid-unzip.py $DATAPATH/merged_logs/$i

                cd $DATAPATH/merged_logs/$i
                
                    for l in "bt-scan" "bt-rssi" "bt-inquiry" "wifi-acp" "wifi-dev" "wifi-drw" "wifi-raw" "wifi-freq"; do
                        if [ -f "${l}.log" ]; then
                            echo "Sorting ${l}.log"
                            sort -T $MOUNTPOINT ${l}.log -o ${l}.log
                            mv ${l}.log ../`hostname`-$i-${l}.log
                        fi
                    done

            rm -r $DATAPATH/merged_logs/$i
        done

        #Write package versions to packages.txt
        dpkg-query -W -f='${Package}: ${Version}\n ${Status}\n\n' | grep -E ': [^ ]+$' > $DATAPATH/original_logs/packages.txt

        #Stop LED flashing
        echo none > /sys/class/leds/alix\:2/trigger
        echo none > /sys/class/leds/alix\:3/trigger
        rm /tmp/gyrid-led-disabled

    fi
}

#Continue only if there is a USB drive attached.
if [ -e /dev/usbstick ]; then

    #Continue only if no USB drive has been mounted yet.
    if [ `grep usbstick /proc/mounts | wc -l` -eq 0 ]; then

        #Set variables
        export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        export MOUNTPOINT="/mnt/usbstick"

        #Try to mount the USB drive as ext3.
        mount -t ext3 /dev/usbstick $MOUNTPOINT

        if [ $? == 0 ]; then
            #Mount successful

            #Enable swap
            if [ -f $MOUNTPOINT/swap ]; then
                mkswap $MOUNTPOINT/swap
                swapon $MOUNTPOINT/swap
            fi

            privileged_usb $1
            permanent_usb $1

        else
            #Mount unsuccessful, try mounting with different filesystem.
            mount -t auto /dev/usbstick $MOUNTPOINT

            if [ $? == 0 ]; then
                #Mount successful

                #Enable swap
                if [ -f $MOUNTPOINT/swap ]; then
                    mkswap $MOUNTPOINT/swap
                    swapon $MOUNTPOINT/swap
                fi

                privileged_usb $1
                temporary_usb $1

            fi
        fi

        #Disable swap
        if [ -f $MOUNTPOINT/swap ]; then
            swapoff $MOUNTPOINT/swap
        fi

        #Unmount the USB drive.
        umount -l /dev/usbstick
    fi
fi
