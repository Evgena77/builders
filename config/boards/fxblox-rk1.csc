# Rockchip RK3588 SoC octa core 8-32GB SoC eMMC USB-C DP NvME SATA M2
BOARD_NAME="FxBlox RK1"
BOARDFAMILY="rockchip-rk3588"
BOARD_MAINTAINER="mahdichi"
BOOTCONFIG="fxblox-rk1-rk3588_defconfig"
BOOT_SOC="rk3588"
KERNEL_TARGET="legacy,vendor"
FULL_DESKTOP="yes"
BOOT_LOGO="desktop"
BOOT_FDT_FILE="rockchip/rk3588-fxblox-rk1.dtb"
BOOT_SCENARIO="spl-blobs"
BOOT_SUPPORT_SPI="yes"
BOOT_SPI_RKSPI_LOADER="yes"
IMAGE_PARTITION_TABLE="gpt"
DDR_BLOB='rk35/rk3588_ddr_lp4_2112MHz_lp5_2736MHz_v1.11.bin'
BL31_BLOB='rk35/rk3588_bl31_v1.38.elf'


function post_family_tweaks__fxblox-rk1_naming_audios() {
	display_alert "$BOARD" "Renaming fxblox rk1 audios" "info"

	mkdir -p $SDCARD/etc/udev/rules.d/
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-dp0-sound", ENV{SOUND_DESCRIPTION}="DP0 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-dp1-sound", ENV{SOUND_DESCRIPTION}="DP1 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	return 0
}

function post_family_config_branch_legacy__fxblox-rk1_uboot_add_sata_target() {
	display_alert "$BOARD" "Configuring ($BOARD) standard and sata uboot target map" "info"

	UBOOT_TARGET_MAP="
	BL31=$RKBIN_DIR/$BL31_BLOB $BOOTCONFIG spl/u-boot-spl.bin u-boot.dtb u-boot.itb;;idbloader.img u-boot.itb rkspi_loader.img
	BL31=$RKBIN_DIR/$BL31_BLOB $BOOTCONFIG spl/u-boot-spl.bin u-boot.dtb u-boot.itb;; rkspi_loader_sata.img
	"
}

function post_uboot_custom_postprocess__create_sata_spi_image() {
	display_alert "$BOARD" "Create rkspi_loader_sata.img" "info"

	dd if=/dev/zero of=rkspi_loader_sata.img bs=1M count=0 seek=16
	/sbin/parted -s rkspi_loader_sata.img mklabel gpt
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart idbloader 64 7167
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart vnvm 7168 7679
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart reserved_space 7680 8063
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart reserved1 8064 8127
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart uboot_env 8128 8191
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart reserved2 8192 16383
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart uboot 16384 32734
	dd if=idbloader.img of=rkspi_loader_sata.img seek=64 conv=notrunc
	dd if=u-boot.itb of=rkspi_loader_sata.img seek=16384 conv=notrunc
}

# Override family config for this board; let's avoid conditionals in family config.
function post_family_config__fxblox-rk1_use_vendor_uboot() {
	BOOTSOURCE='https://github.com/functionland/u-boot.git'
	BOOTBRANCH='branch:next-dev'
	BOOTPATCHDIR="legacy"
}
