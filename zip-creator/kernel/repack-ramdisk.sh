#!/sbin/sh

# copy old kernel to sdcard
if [ ! -e /sdcard/pre_pink_boot ]; then
	cp /tmp/boot.img /sdcard/pre_pink_boot.img
fi

# decompress ramdisk
mkdir /tmp/ramdisk
cd /tmp/ramdisk
gunzip -c ../boot.img-ramdisk.gz | cpio -i

# add init.d support if not already supported
found=$(find init.rc -type f | xargs grep -oh "run-parts /system/etc/init.d");
if [ "$found" != 'run-parts /system/etc/init.d' ]; then
        #find busybox in /system
        bblocation=$(find /system/ -name 'busybox')
        if [ -n "$bblocation" ] && [ -e "$bblocation" ] ; then
                echo "BUSYBOX FOUND!";
                #strip possible leading '.'
                bblocation=${bblocation#.};
        else
                echo "NO BUSYBOX NOT FOUND! init.d support will not work without busybox!";
                echo "Setting busybox location to /system/xbin/busybox! (install it and init.d will work)";
                #set default location since we couldn't find busybox
                bblocation="/system/xbin/busybox";
        fi
		#append the new lines for this option at the bottom
        echo "" >> init.rc
        echo "service userinit $bblocation run-parts /system/etc/init.d" >> init.rc
        echo "    oneshot" >> init.rc
        echo "    class late_start" >> init.rc
        echo "    user root" >> init.rc
        echo "    group root" >> init.rc
fi

# make kernel open
cp -vr ../extras/default.prop .

cp -vr ../extras/init.pink.post_boot.sh .
cp -vr ../extras/thermal-engine-pink.conf .

# Copy STweaks
# cp -vr ../extras/res .

# change zram values
sed 's/zramsize=134217728/zramsize=402653184/g' -i fstab.qcom
sed 's/zramsize=134217728/zramsize=402653184/g' -i gpe-fstab.qcom

# remove mpdecision we use Intelliplug
sed -i '/mpdecision/{n; /class main$/d}' init.qcom.rc
sed -i '/mpdecision/d' init.qcom.rc

sed 's/start qcom-post-boot/start pink-post-boot/g' -i init.qcom.rc

sed 's/qcom-post-boot \/system\/bin\/sh \/system\/etc\/init.pink.post_boot.sh/pink-post-boot \/system\/bin\/sh \/init.pink.post_boot.sh/g' -i init.qcom.rc
sed 's/qcom-post-boot \/system\/bin\/sh \/system\/etc\/init.qcom.post_boot.sh/pink-post-boot \/system\/bin\/sh \/init.pink.post_boot.sh/g' -i init.qcom.rc

sed 's/\/etc\/thermal-engine-pink.conf/\/thermal-engine-pink.conf/g' -i init.target.rc
sed 's/\/etc\/thermal-engine-8226.conf/\/thermal-engine-pink.conf/g' -i init.target.rc

sed 's/write \/sys\/block\/mmcblk0\/queue\/scheduler noop/ /g' -i init.qcom.rc
sed 's/write \/sys\/block\/mmcblk0\/queue\/scheduler row/ /g' -i init.qcom.rc

sed 's/write \/sys\/devices\/system\/cpu\/cpu0\/cpufreq\/scaling_governor ondemand/write \/sys\/devices\/system\/cpu\/cpu0\/cpufreq\/scaling_governor intelliactive/g' -i init.qcom.rc
sed 's/write \/sys\/devices\/system\/cpu\/cpu0\/cpufreq\/scaling_governor powersave/write \/sys\/devices\/system\/cpu\/cpu0\/cpufreq\/scaling_governor intellidemand/g' -i init.qcom.rc

find . | cpio -o -H newc | gzip > ../newramdisk.cpio.gz
cd /
