ISO_URL  := http://ftp.twaren.net/ubuntu-cd/precise/
ISO_FILE := ubuntu-12.04.2-alternate-amd64.iso

all: iso

iso: 
	mkdir -p cd-src cd-dst
	if [ ! -f /usr/bin/genisoimage ]; then apt-get -y install genisoimage; fi
	if [ ! -f /usr/bin/isohybrid ]; then apt-get -y install syslinux; fi
	if [ ! -f $(ISO_FILE) ]; then wget $(ISO_URL)/$(ISO_FILE); fi
	mount -o loop $(ISO_FILE) cd-src/
	rsync -av cd-src/ cd-dst/
	umount cd-src
	cp isolinux/* 	cd-dst/isolinux
	cp img/* 	cd-dst/isolinux
	cp preseed/* 	cd-dst/preseed
	genisoimage -r -V "cloud-interop" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o cloud-interop.iso cd-dst

clean:
	rm -rf cd-src cd-dst cloud-interop.iso

dist-clean: clean
	rm -rf $(ISO_FILE)
