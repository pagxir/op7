##!/bin/bash
# Bash Color
green='\e[32m'
red='\e[31m'
yellow='\e[33m'
blink_red='\033[05;31m'
restore='\033[0m'
reset='\e[0m'

#SkyDragon Kernel Build Script
##############################################

# Kernel zip Name
kn=SDK_OP7TP_OOS9_DV.20.0.0.zip

# Resource Locations
##############################################
# Target Architecture
export ARCH=arm64
# Target Sub-Architecture
export SUBARCH=arm64
# Path To Clang
export CLANG_PATH=/android/toolchains/gclang/bin/
# Export Clang Path to $PATH
export PATH=${CLANG_PATH}:${PATH}
# Clang Target Triple
export CLANG_TRIPLE=aarch64-linux-gnu-
# Location of Aarch64 GCC Toolchain *
export CROSS_COMPILE=/android/toolchains/aarch64-9.1/bin/aarch64-linux-gnu-
# Location Arm32 GCC Toolchain *
export CROSS_COMPILE_ARM32=/android/toolchains/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
# Export Clang Libary To LD Library Path
export LD_LIBRARY_PATH=/android/toolchains/gclang/lib64:$LD_LIBRARY_PATH


# Paths
##############################################
# Map current directory
KERNEL_DIR=`pwd`
# Source Path to kernel tree
k="/android/kernels/sm8150qs"

# CPU threads
th="-j$(grep -c ^processor /proc/cpuinfo)"
thrc="-j12"

# Source defconfig used to build
dc=SD_defconfig

# Image Name
img_gz=Image.gz-dtb
img_lz4=Image.lz4-dtb
# Source Path to compiled Image.gz-dtb
io=$k/out/arch/arm64/boot/$img_gz
# Destination path for compiled Image.gz-dtb
zi=$k/build/$img_gz

# DTBToolCM
dtbtool=$k/build/tools/dtbToolCM
# Destination path for compiled dtb image
zd=$k/build/dtb

# Compile Path to out 
o="O=$k/out"
# Source Path to clean(empty) out folder
co=$k/out

# Source path for building kernel zip
zp=$k/build/

# Destination patch for Changelog
zc=$k/build/Changelog.txt

# Destination Path for compiled modules
zm=$k/build/system/lib/modules

# Destination Path for uploading kernel zip
zu=$k/upload/


# Main Menu
##############################################
# Function to display menu
 show_menus() {
		clear
		echo "	~~~~~~~~~~~~~~~~~~"
		echo "	M A I N - M E N U"
		echo "	~~~~~~~~~~~~~~~~~~"
		echo "	1. Make Kernel"
		echo "	2. Recompile Kernel"
		echo "	3. Make Full Zip"
		echo "	4. Make Changelog"
		echo "	5. Exit"
}

# Functions
##############################################
# Function to Pause
function pause() {
	local message="$@"
	[ -z $message ] && message="Press [Enter] key to continue.."
	read -p "$message" readEnterkey
}

# Function to clean up pregenerated images
function make_bclean {
		echo
		echo -e "${yellow}Cleaning up pregenerated images${red}"
		rm -rf $zi
		rm -rf $zd
		rm -rf $zc
		echo -e "${green}Completed!"
}

# Function to only compile the kernel
function make_kernel {
		echo
		echo -e "${yellow}Cleaning up out directory${red}"
		rm -rf "$co"
		echo -e "${green}Out directory removed!"
		echo -e "${yellow}Making new out directory"
		mkdir -p "$co"
		echo -e "${green}Created new out directory"
		echo -e "${yellow}Establishing build environment..${restore}"
		make "$o" CC=clang $dc
		echo -e "${yellow}Starting Compile..${restore}"
		time make "$o" CC=clang $th
		echo -e "${green}Compilation Successful!${restore}"
}

# Function to recompile the kernel at a slower rate
# after fixing an error without starting over
function recompile_kernel {
		echo
		echo -e "${yellow}Picking up where you left off..${restore}"
		make "$o" CC=clang $thrc
		echo -e "${green}Compilation Successful!${restore}"
		pause
}

# Function to build the full kernel zip
function make_zip {
		echo
		make_bclean
		make_kernel
		echo -e "${yellow}Copying kernel to zip directory"
		cp "$io" "$zi"
		echo -e "${green}Copy Successful${restore}"
		make_clog
		echo -e "${yellow}Making zip file.."
		cd "$zp"
		zip -r "$kn" *
		echo -e "${yellow}Moving zip to upload directory"
		mv "$kn" "$zu" 
		echo -e "${yellow}Back to Start.."
		cd $k
		echo -e "${green}Completed build script!${restore}"
		pause
}

# Function to generate a dtb image
function make_dtb {
		echo
		echo -e "${yellow}Generating DTB Image"
		$dtbtool -2 -o $zd -s 2048 -p $co/scripts/dtc/ $co/arch/arm64/boot/dts/qcom/
		echo -e "${green}DTB Generated!${restore}"
}

# Generate Changelog
function make_clog {
		echo
		echo -e "${yellow}Generating Changelog.."
		rm -rf $zc
		touch $zc
	for i in $(seq 180);
	do
		local After_Date=`date --date="$i days ago" +%F`
		local kcl=$(expr $i - 1)
		local Until_Date=`date --date="$kcl days ago" +%F`
		echo "====================" >> $zc;
		echo "     $Until_Date    " >> $zc;
		echo "====================" >> $zc;
		git log --after=$After_Date --until=$Until_Date --pretty=tformat:"%h  %s  [%an]" --abbrev-commit --abbrev=7 >> $zc
		echo "" >> $zc;
	done
		sed -i 's/project/ */g' $zc
		sed -i 's/[/]$//' $zc
		echo -e "${yellow}Changelog Complete!${restore}"
}

# Function to read menu choices
read_options(){
	local choice
	read -p "Enter choice [1-5] " choice
	case $choice in
		1) make_kernel ;;
		2) recompile_kernel ;;
		3) make_zip ;;
		4) make_clog ;;
		5) exit 0;;
		*) echo -e "${red}Error...${restore}" && sleep 2
	esac
}

# Main Logic
while true
do
	clear
	show_menus
	read_options
done