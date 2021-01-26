FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
	file://initramfs-additions.cfg \
"

do_deploy_prepend() {
	CMD_LINE="${CMD_LINE} init=/sbin/overlayfs-init.sh "
}
