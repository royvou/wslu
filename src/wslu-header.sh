#!/bin/bash
# wslu - Windows 10 linux Subsystem Utility
# Component of Windows 10 linux Subsystem Utility
# <https://github.com/wslutilities/wslu>
# Copyright (C) 2019 Patrick Wu
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Version
wslu_version=VERSIONPLACEHOLDER
wslu_prefix="PREFIXPLACEHOLDER"

# Speed up script by using unicode.
LC_ALL=C
LANG=C

# prevent bash -x
set +x

# when --verbose, verbose; when --debug, debug.
#
# They should not exist at the same time, otherwise
# the output would be too messy.
wslu_debug=0
if [ "$1" == "--verbose" ]; then
	echo -e '\e[38;5;202m\033[1m[verbose] Showing verbose output. \033(B\033[m'
	shift
	set -x
elif [ "$1" == "--debug" ]; then
	wslu_debug=1
	echo -e '\e[38;5;202m\033[1m[debug] Showing debug output. \033(B\033[m'
	shift
fi

# checking interoperability
grep enabled /proc/sys/fs/binfmt_misc/WSLInterop >/dev/null || (echo -e "\e[31m\033[1m[error] WSL Interoperability is disabled. Please enable it before using WSL.\033(B\033[m"; exit 1)

# variables
## color
black=$(echo -e '\e[30m')
red=$(echo -e '\e[31m')
green=$(echo -e '\e[32m')
brown=$(echo -e '\e[33m')
blue=$(echo -e '\e[34m')
purple=$(echo -e '\e[35m')
cyan=$(echo -e '\e[36m')
yellow=$(echo -e '\e[33m')
white=$(echo -e '\e[37m')
dark_gray=$(echo -e '\e[1;30m')
light_red=$(echo -e '\e[1;31m')
light_green=$(echo -e '\e[1;32m')
light_blue=$(echo -e '\e[1;34m')
light_purple=$(echo -e '\e[1;35m')
light_cyan=$(echo -e '\e[1;36m')
light_gray=$(echo -e '\e[37m')
orange=$(echo -e '\e[38;5;202m')
light_orange=$(echo -e '\e[38;5;214m')
deep_purple=$(echo -e '\e[38;5;140m')
bold=$(echo -e '\033[1m')
reset=$(echo -e '\033(B\033[m')

## indicator
info="${green}[info]${reset}"
input_info="${cyan}[input]${reset}"
error="${red}[error]${reset}"
warn="${orange}[warn]${reset}"

## Windows build number constant
readonly BN_SPR_CREATORS=15063		#1703, Redstone 2, Creators Update
readonly BN_FAL_CREATORS=16299		#1709, Redstone 3, Fall Creators Update
readonly BN_APR_EIGHTEEN=17134		#1803, Redstone 4, April 2018 Update
readonly BN_OCT_EIGHTEEN=17763		#1809, Redstone 5, October 2018 Update
readonly BN_MAY_NINETEEN=18362		#1903, 19H1, May 2019 Update
readonly BN_NOV_NINETEEN=18363		#1909, 19H2, November 2019 Update
readonly BN_MAY_TWENTYTY=19041		#2004, 20H1, May 2020 Update

# source default config
if [ -f "${wslu_prefix}/share/wslu/conf" ]; then
	source "${wslu_prefix}/share/wslu/conf"
fi

# source user-defined config
if [ -f "${wslu_prefix}/share/wslu/custom.conf" ]; then
	source "${wslu_prefix}/share/wslu/custom.conf"
fi
if [ -f "$HOME/.config/wslu/conf" ]; then
	source "$HOME/.config/wslu/conf"
fi
if [ -f "$HOME/.wslurc" ]; then
	source "$HOME/.wslurc"
fi

# functions
function debug_echo {
	[ $wslu_debug -eq 1 ] && echo "${orange}${bold}[debug]${reset} $@"
}

function error_echo {
	echo "${error} $1"
	exit $2
}

function help {
	app_name=$(basename "$1")
	echo -e "$app_name - Part of wslu, a collection of utilities for Windows 10 Windows Subsystem for Linux
Usage: $2

For more help for $app_name, please use the command \`man $app_name\` or visit the following site: https://wslutiliti.es/wslu/man/$app_name.html.
For overall help, you can use the command \`man wslu\` or visite the following site: https://wslutiliti.es/wslu."
}

function double_dash_p {
	echo "${@//\\/\\\\}"
}

function interop_prefix {

	win_location="/mnt/"
	if [ -f /etc/wsl.conf ]; then
		tmp="$(awk -F '=' '/root/ {print $2}' /etc/wsl.conf | awk '{$1=$1;print}')"
		[ "$tmp" == "" ] || win_location="$tmp"
		[[ "$win_location" =~ ^.*/$ ]] || win_location="$win_location/" # make sure it always end with slash
		unset tmp
	fi
	echo "$win_location"

	unset win_location
}

function sysdrive_prefix {
	win_location="$(interop_prefix)"
	hard_reset=0
	for pt in $(ls "$win_location"); do
		if [ $(echo "$pt" | wc -l) -eq 1 ]; then
			if [ -d "$win_location$pt/Windows/System32" ]; then
				hard_reset=1
				win_location="$pt"
				break
			fi
		fi 
	done

	if [ $hard_reset -eq 0 ]; then
		win_location="c"
	fi

	echo "$win_location"

	unset win_location
	unset hard_reset
}

function chcp_com {
	"$(interop_prefix)$(sysdrive_prefix)"/Windows/System32/chcp.com "$@" >/dev/null
}

function winps_exec {
	chcp_com "$(cat ~/.config/wslu/oemcp)"
	"$(interop_prefix)$(sysdrive_prefix)"/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -NonInteractive –ExecutionPolicy Bypass -Command "$@"
	EXIT_STATUS=$?
	chcp_com 65001
	return $EXIT_STATUS
}

function baseexec_gen {
	wslutmpbuild=$("$(interop_prefix)$(sysdrive_prefix)"/Windows/System32/reg.exe query "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion" /v CurrentBuild | tail -n 2 | head -n 1 | sed -e 's|\r||g')
	wslutmpbuild=${wslutmpbuild##* }
	wslutmpbuild="$(( $wslutmpbuild + 0 ))"
	if [ $wslutmpbuild -ge $BN_MAY_NINETEEN ]; then
		# The environment variable only available in 19H1 or later.
		wslu_distro_regpath=$("$(interop_prefix)"c/Windows/System32/reg.exe query "HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Lxss" /s /f DistributionName 2>&1 | sed -e 's|\r||g' | grep -B1 -e "$WSL_DISTRO_NAME$" | head -n1 )
		if "$(interop_prefix)$(sysdrive_prefix)"/Windows/System32/reg.exe query "$wslu_distro_regpath" /v PackageFamilyName &>/dev/null; then
			wslu_distro_packagename=$("$(interop_prefix)$(sysdrive_prefix)"/Windows/System32/reg.exe query "$wslu_distro_regpath" /v PackageFamilyName | tail -n 2 | head -n 1 | sed -e 's|\r||g')
			# if it is a store distro
			wslu_distro_packagename=${wslu_distro_packagename##* }
			wslu_base_exec_folder_path="$(wslpath "$(winps_exec "[Environment]::GetFolderPath('LocalApplicationData')" | tr -d "\r")\\Microsoft\\WindowsApps\\$wslu_distro_packagename")"
			wslpath -w "$(find "$wslu_base_exec_folder_path" -name "*.exe")" > ~/.config/wslu/baseexec
		else
			# if it is imported distro
			echo "$(wslpath -w "$(interop_prefix)$(sysdrive_prefix)")Windows\\System32\\wsl.exe" > ~/.config/wslu/baseexec
		fi
	else
		# older version fallback.
		echo "$(wslpath -w "$(interop_prefix)$(sysdrive_prefix)")\\Windows\\System32\\wsl.exe" > ~/.config/wslu/baseexec
	fi
}

function var_gen {
	date +"%s" > ~/.config/wslu/triggered_time

	rm ~/.config/wslu/baseexec
	rm ~/.config/wslu/oemcp

	# generate oem codepage
	"$(interop_prefix)$(sysdrive_prefix)"/Windows/System32/reg.exe query "HKLM\\SYSTEM\\CurrentControlSet\\Control\\Nls\\CodePage" /v OEMCP 2>&1 | sed -n 3p | sed -e 's|\r||g' | grep -o '[[:digit:]]*' > ~/.config/wslu/oemcp
	# generate base exe location
	baseexec_gen

}

function wslu_file_check {
	should_i_show=""
	[[ "$3" == "?!S" ]] && should_i_show="n"

	if [[ ! -f "$1/$2" ]]; then
		[[ -z "$should_i_show" ]] && echo "${warn} $2 not found in Windows directory. Copying right now..."
		[[ -d "$1" ]] || mkdir "$1"
		if [[ -f "/usr/share/wslu/$2" ]]; then
			cp "/usr/share/wslu/$2" "$1"
			[[ -z "$should_i_show" ]] && echo "${info} $2 copied. Located at \"$1\"."
		else
			[[ -z "$should_i_show" ]] && echo "${error} $2 not found. Failed to copy."
			exit 30
		fi
	fi
}

function wslu_get_build {
	build=$("$(interop_prefix)$(sysdrive_prefix)"/Windows/System32/reg.exe query "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion" /v CurrentBuild | tail -n 2 | head -n 1 | sed -e 's|\r||g')
	echo "${build##* }"
}


# first run, saving some information
if [ ! -d ~/.config/wslu ]; then
	mkdir -p ~/.config/wslu
fi

# This gets tirggered then:
# 1. if it's the first time the script is triggered, i.e.,
#    ~/.config/wslu/triggered time
# 2. if update_time is also not present, i.e.,
#    badly installed packages or installed via install script
if [ ! -f ~/.config/wslu/triggered_time ] || [ ! -f /usr/share/wslu/updated_time ]; then
	var_gen
# This gets triggered when:
#    installed time is larger than the last triggered time
elif [ $(cat ~/.config/wslu/triggered_time) -lt $(cat /usr/share/wslu/updated_time) ]; then
	var_gen
fi

# basic distro detection
distro="$(head -n1 /etc/os-release | sed -e 's/NAME=\"//g')"
case $distro in
	*Pengwin*) distro="pengwin";;
	*WLinux*) distro="wlinux";;
	Ubuntu*) distro="ubuntu";;
	*Debian*) distro="debian";;
	*Kali*) distro="kali";;
	openSUSE*) distro="opensuse";;
	SLES*) distro="sles";;
	Alpine*) distro="alpine";;
	Arch*) distro="archlinux";;
	*Oracle*) distro="oracle";;
	Scientific*) distro="scilinux";;
	*Fedora\ Remix\ for\ WSL*) distro="fedoraremix";;
	*Fedora*) distro="fedora";;
	*Gentoo*) distro="gentoo";;
	*Generic*) [ "fedora" == "$(grep -e "LIKE=" /etc/os-release | sed -e 's/ID_LIKE=//g')" ] && distro="oldfedora" || distro="unknown";;
	*) distro="unknown";;
esac
