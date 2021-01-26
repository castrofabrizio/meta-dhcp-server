DESCRIPTION = "Boot script for initramfs overlayfs mount"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING;md5=3da9cfbcb788c80a0384361b4de20420"

inherit update-alternatives features_check

S = "${WORKDIR}"

ALTERNATIVE_${PN} = "init"
ALTERNATIVE_PRIORITY = "250"

ALTERNATIVE_LINK_NAME[init] = "${base_sbindir}/init"
ALTERNATIVE_PRIORITY[init] = "250"

SRC_URI += " \
	file://COPYING \
	file://overlayfs-init.sh \
"

do_install () {
	install -d ${D}/sbin
	install -d ${D}/bin
	install -m 0777 ${WORKDIR}/overlayfs-init.sh ${D}/sbin

	cd ${D}/sbin
	ln -sf overlayfs-init.sh init

	cd ${D}/bin
	ln -sf ../sbin/overlayfs-init.sh init

	cd ${D}
	ln -sf sbin/overlayfs-init.sh init
}

FILES_${PN} += " \
	/sbin/init \
	/bin/init \
	/init \
"
