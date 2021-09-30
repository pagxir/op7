##!/bin/bash
# Bash Color
green='\e[32m'
red='\e[31m'
yellow='\e[33m'
blink_red='\033[05;31m'
restore='\033[0m'
reset='\e[0m'

# SkyDragon Kernel Build Script
# Version 2.0
##############################################
# User Variables
export LOCALVERSION="-SDK_OP7TP_OOS11_RV.2.1"
# Kernel zip Name
export kn="SDK_OP7TP_OOS11_RV.2.1.zip"
# Kernel Defconfig
export dc=SD_defconfig

### System Variables ###
##############################################
# Map current directory
export k=$(pwd)
export kd=$k/guacamole
######################
# Target Architecture
export ARCH=arm64
# Target Sub-Architecture
export SUBARCH=arm64
######################
# Compiler Type
export CC=clang
export ccs="CC=clang"
# Path To Clang
export CLANG_PATH=$k/prebuilts/clang/clang-r383902/bin/
# Location of Clang Libary to LD Library Path
export LD_LIBRARY_PATH=$k/prebuilts/clang/clang-r383902/lib64:$LD_LIBRARY_PATH
# Export Clang Path to $PATH
export PATH=${CLANG_PATH}:${PATH}
# Clang Target Triple
export CLANG_TRIPLE=aarch64-linux-gnu-
# Location of Aarch64 GCC Toolchain *
######################
export CROSS_COMPILE=$k/prebuilts/arm64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
# Location Arm32 GCC Toolchain *
 export CROSS_COMPILE_ARM32=$k/prebuilts/arm/arm-linux-androideabi-4.9/bin/arm-cortex_a15-linux-gnueabihf-
######################
# CPU threads
# All Available cores (Used for normal compilation)
export th="-j$(grep -c ^processor /proc/cpuinfo)"
# 12 Cores Only: Recompile (Only used for 'recompiles' to catch errors more easily)
export thrc="-j12"
######################
# Compile Path to out 
o="O=$k/out/guacamole"
# Source Path to clean(empty) out folder
co=$k/out/guacamole
######################
# Destination Path for uploading kernel zip
zu=$k/upload/
# Destination path for build.log
zbl=$k/build-op711.log
######################
# Source path for building kernel zip
zp=$k/ak3/
# Destination patch for Changelog
zc=$zp/Changelog.txt
# Number of days to log in changelog
zcdt=180
# Destination Path for compiled modules
zm=$zp/system/lib/modules
# DTBToolCM
dtbtool=$zp/tools/dtbToolCM
# Destination path for compiled dtb image
zd=$zp/dtb

##############################################
# Image Type (Only ONE of the following (lz4/gz) can Enabled!)
##############################################
####### GZ Image (Comment to Disable) ########
img_gz=Image.gz-dtb
### Source Path to compiled Image.gz-dtb
io=$co/arch/arm64/boot/$img_gz
### Destination path for compiled Image.gz-dtb
zi=$zp/$img_gz
##############################################

###### LZ4 Image (Uncomment to Enable) #######
# img_lz4=Image.lz4-dtb
### Source Path to compiled Image.lz4-dtb
# io=$$co/arch/arm64/boot/$img_lz4
### Destination path for compiled Image.lz4-dtb
# zi=$zp/$img_lz4
##############################################

## Uncompressed Image (Uncomment to Enable) ##
# img_uc=Image-dtb
### Source Path to compiled Image-dtb
# io=$$co/arch/arm64/boot/$img_uc
### Destination path for compiled Image-dtb
# zi=$zp/$img_uc
##############################################

##############################################
# DTBO Image
dtbo=dtbo.img
# Source Path to compiled dtbo image
j=$co/arch/arm64/boot/$dtbo
# Destination path for compiled dtbo image
zj=$zp/$dtbo

##############################################
# Functions
##############################################

######################
# Function to Pause
function pause() {
	local message="$@"
	[ -z $message ] && message="Press [Enter] key to continue.."
	read -p "$message" readEnterkey
}
######################
# Function to goto menu
function pmenu() {
	local message="$@"
	[ -z $message ] && message="Press [Enter] key to return to the main menu.."
	read -p "$message" readEnterkey
	show_menus
}
######################
# Function to clean up pregenerated images
function make_bclean {
		echo
		echo -e "${yellow}Cleaning up pregenerated images${red}"
		rm -rf $zd
		rm -rf $zi
		rm -rf $zj
		rm -rf $zc
		rm -rf $zbl
		echo -e "${green}Completed!${restore}"
}
######################
# Function to clean generated out folder
function make_oclean {
		echo
		echo -e "${yellow}Cleaning up out directory${red}"
		rm -rf "$co"
		echo -e "${green}Out directory removed!${restore}"
}
######################
# Funtion to clean source tree
function make_sclean {
		echo
		echo -e "Entering kernel directory.."
		cd $kd
		echo -e "${yellow}Cleaning source directory..${red}"
#		make clean && make mrproper
		echo -e "${green}Cleaning Completed!${restore}"
		cd $k
}
######################
# Function to clean up pregenerated images
function make_fclean {
		echo
		make_bclean
		make_oclean
		make_sclean
		echo -e "${green}Environment Cleaning Successful!${restore}"
}
######################
# Function to only compile the kernel, test builds
function make_kernel {
		echo
		make_bclean
		make_oclean
		echo -e "${yellow}Making new out directory"
		mkdir -p "$co"
		echo -e "Entering kernel directory.."
		cd $kd
		echo -e "${yellow}Establishing build environment..${restore}"
		make "$o" $ccs $dc
		echo -e "${yellow}~~~~~~~~~~~~~~~~~~"
		echo -e "${yellow}Starting Compile.."
		echo -e "${yellow}~~~~~~~~~~~~~~~~~~${restore}"
		time make "$o" $ccs $th |& tee -a "$zbl"
		if [ $? -eq 0 ]; then
			echo -e "${green}Compilation Successful!${restore}"
			pause
		else
			echo -e "${red}Compilation Failed!${restore}"
			pause
		fi
}
######################
# Function to recompile the kernel at a slower rate
# after fixing an error without starting over
function recompile_kernel {
		echo
		echo -e "${yellow}Picking up where you left off..${restore}"
		time make "$o" $ccs $thrc |& tee -a "$zbl"
		if [ $? -eq 0 ]; then
			echo -e "${green}Compilation Successful!${restore}"
			pause
		else
			echo -e "${red}Compilation Failed!${restore}"
			pause
		fi
}
######################
# Function for full kernel compile
function make_fkernel {
		echo -e "${yellow}Making new out directory${restore}"
		mkdir -p "$co"
		echo -e "Entering kernel directory.."
		cd $kd
		echo -e "${yellow}Establishing build environment..${restore}"
		make "$o" $ccs $dc
		echo -e "${yellow}Starting Compile..${restore}"
		make "$o" $ccs $th |& tee -a "$zbl"
		if [ $? -eq 0 ]; then
			echo -e "${green}Compilation Successful!${restore}"
			cd $k
		else
			echo -e "${red}Compilation Failed!${restore}"
			cd $k
			pause
		fi
}
######################
# Function to generate the kernel zip
function make_zip {
		echo
		echo -e "${yellow}Copying kernel to zip directory..${red}"
		if [ -f "$io" ]; then
			cp "$io" "$zi" |& tee -a "$zbl"
			if [ $? -eq 0 ]; then
			echo -e "${green}Copy Successful${restore}"
			else
			echo -e "${red}Copy Failed!${restore}"
			pmenu
			exit
			fi
		else
			echo -e "${yellow}No kernel to copy, trying prebuilt in build folder..${red}"
			if [ -f "$zi" ]; then
			echo -e "${green}Prebuilt exists! Continuing with build folder kernel..${restore}"
			else
			echo -e "${red}No Prebuilt kernel either! COMPILE FIRST!${restore}"
			pmenu
			exit
			fi
		fi
# Uncomment to enable making dtb
#		make_dtb
# Uncomment to enable copying dtbo
#		echo -e "${yellow}Copying dtbo to zip directory..${red}"
#		cp "$j" "$zj"
		make_clog
		echo -e "${yellow}Making zip file....${red}"
		cd "$zp"
		zip -r "$kn" *
		if [ $? -eq 0 ]; then
			echo -e "${green}Zip Creation Successful${restore}"
		else
			echo -e "${red}Zip Creation Failed!${restore}"
			pmenu
			exit
		fi
		if [ -d "$zu" ]; then
			echo -e "${yellow}Moving zip to upload directory"
			mv "$kn" "$zu"
			if [ $? -eq 0 ]; then
				echo -e "${green}Zip Moved to Upload Folder Successfully${restore}"
			else
				echo -e "${red}Zip Moving Failed!${restore}"
				pmenu
				exit
			fi
		else
			echo -e "${yellow}Creating upload directory"
			mkdir -p "$zu"
			echo -e "${yellow}Moving zip to upload directory"
			mv "$kn" "$zu" 
			if [ $? -eq 0 ]; then
				echo -e "${green}Zip Moved to Upload Folder Successfully${restore}"
			else
				echo -e "${red}Zip Moving Failed!${restore}"
				pmenu
				exit
			fi
		fi
		echo -e "${green}Completed build script!${restore}"
		cd $k
		echo -e "${restore}Back at Start"
		pause
}
######################
# Function to generate a dtb image
function make_dtb {
	if [ -f "$dtbtool" ]; then
		echo -e "${yellow}Generating DTB Image"
		$dtbtool -2 -o $zd -s 2048 -p $co/scripts/dtc/ $co/arch/arm64/boot/dts/qcom/
		echo -e "${green}DTB Generated!${restore}"
	else
		echo -e "${yellow}No DTB Tool Available!${restore}"
	fi
}
######################
# Generate Changelog
function make_clog {
		echo
		echo -e "Entering kernel directory.."
		cd $kd
		echo -e "${yellow}Generating Changelog.."
		rm -rf $zc
		touch $zc
	for i in $(seq $zcdt);
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
		cd $k
}
######################
# Function to build the full kernel zip
function make_full {
		echo
		make_fclean
		make_fkernel
		make_zip
}

##############################################
# Main Menu
##############################################
# Function to display menu
 show_menus() {
		clear
		echo "	~~~~~~~~~~~~~~~~~~"
		echo "	M A I N - M E N U"
		echo "	~~~~~~~~~~~~~~~~~~"
		echo "	1. Compile Kernel"
		echo "	2. Recompile Kernel"
		echo "	3. Generate Kernel Zip"
		echo "	4. Make Full Build"
		echo "	5. Generate Stand-Alone Changelog"
 		echo "	6. Clean Environment"
  		echo "	7. Exit"
}
######################
# Function to read menu choices
read_options(){
	local choice
	read -p "Enter choice [1-7] " choice
	case $choice in
		1) make_kernel ;;
		2) recompile_kernel ;;
		3) make_zip ;;
		4) make_full ;;
		5) make_clog ;;
		6) make_fclean ;;
		7) exit 0;;
		*) echo -e "${red}Error...${restore}" && sleep 1
	esac
}
##############################################
# Main Logic
##############################################
while true
do
	clear
	show_menus
	read_options
done
