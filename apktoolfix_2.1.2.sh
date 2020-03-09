#!/bin/bash

#Author: graylagx2
#Name: apktoolfix
#Version: 2.1.2
#Description: This bash script automates the process of fixing/installing a working 
#             version of apktool. It also checks on system requirments to verify
#             the script will have no issues working.
#
#Contact: graylagx2@gmail.com

_SILENT_JAVA_OPTIONS="$_JAVA_OPTIONS"
unset _JAVA_OPTIONS
alias java='java "$_SILENT_JAVA_OPTIONS"'

RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[1;34m'
RESTORE=$'\e[0m'
L_GREY=$'\e[0;37m'

spinLoader() {
    pid=$!
    spin='\|/-'
    i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${BLUE}[${spin:$i:1}]${RESTORE} $PROG_MESSAGE"
        sleep .1
    done
    printf "\r ${GREEN}[-]${RESTORE} $COMP_MESSAGE"
    sleep 1;echo java_V=$(java -version 2>&1 | awk 'NR == 1 { gsub("\"",""); print $3}' | awk -F. '{print $1"."$2}')

}

echo -e "${BLUE}"
echo '
         _______                  _____                     ______ 
        |     __.----.---.-.--.--|     |_.---.-.-----.--.--|__    |
        |    |  |   _|  _  |  |  |       |  _  |  _  |_   _|    __|
        |_______|__| |___._|___  |_______|___._|___  |__.__|______|
                           |_____|             |_____|             
'                                                                     
echo -e "${YELLOW}                           Apktool-Fix Version ${BLUE}2.1.2${RESTORE}\n"
echo -e "${L_GREY}This script was developed to be used with the kali-linux distribution any use outside of this distribution may not work${RESTORE}\n"
sleep 2
                                                      
# Checking internet connection to exit with message if none
[[ $(wget -q --tries=5 --timeout=20 --spider http://google.com ; echo $?) != 0 ]] && echo -e "${RED}Warning!${YELLOW} This script needs an internet connection!" && echo && echo -e "${YELLOW}Please connect to the internet and try again.${RESTORE}" && exit

# Checking for for missing dependencies and install missing
echo -e "\n${BLUE}[-] ${YELLOW}Checking Dependencies${RESTORE}\n";

# Checking the current version of java thats installed
java_V=$(java -version 2>&1 | awk 'NR == 1 { gsub("\"",""); print $3}' | awk -F. '{print $1"."$2}' 2>/dev/null)
# Testing if java version is equal or greater than 1.8
declare $(awk -v version="$java_V" 'BEGIN{if(version>1.8){ print "java_Met=true"}}')
if [ "$java_Met" == "true" ]; then     
    sleep 0.5;echo -e "${GREEN}  [-] ${YELLOW} Java-Version 1.8 or greater is ${GREEN}Installed.${RESTORE}"
    mapfile -t pkg_depends < <(apt-cache depends apktool | cut -d':' -f2 | sed '/^apktool\b/d;/^i386\b/d;/headless/d')
    pwd=$(pwd)
    
    for depend in "${pkg_depends[@]}"; do 
        pkg_qry=$(dpkg-query -s $depend &>/dev/null ; echo $?)
        if [ $pkg_qry = 0 ]; then
            sleep 0.5;echo -e "${GREEN}  [-] ${YELLOW}$depend is ${GREEN}Installed.${RESTORE}"
        else 
            sleep 0.5;echo -e "${RED}  [-] ${YELLOW}$depend is ${RED}missing.${RESTORE}"
            MISSING+=($depend)
            [[ -e /tmp/repair_depends ]] || mkdir /tmp/repair_depends
            cd /tmp/repair_depends && apt-get download $depend &>/dev/null
            cd $pwd     
        fi
    
    done

    if [[ ! -z $MISSING ]]; then 
        (dpkg -i /tmp/repair_depends/* &>/dev/null) & 
        echo 
        PROG_MESSAGE="${YELLOW}Installing missing dependencies${RESTORE}"
        COMP_MESSAGE="${YELLOW}Installed dependencies${RESTORE}"
        spinLoader;echo              
    
        [[ -z ${MISSING[@]} ]] || echo -e "\n${YELLOW}The following dependencies were installed:\n" && sleep 2 && for depends in ${MISSING[@]}; do echo -e "${BLUE}$depends${RESTORE}"; done; sleep 2
        rm -r -f /tmp/repair_depends
    fi

else 
    sleep 0.5
    echo -e "${RED}  [-] ${YELLOW}Java-Version 1.8 or greater is ${RED}Missing.${RESTORE}\n"    
    mapfile -t java_depends < <(apt-cache depends apktool | grep "headless" | cut -d':' -f2| sed 's/^[ \t]*//;/<java8-runtime-headless>/d' |sort -u)
    echo -e '${BLUE}Please select a ${YELLOW}\e[4mJava-Version\e[0m${BLUE} to be installed: \n${BLUE}'
    select opt in "${java_depends[@]}"; do
        if [ -z $opt ] || [ "$opt" == [a-zA-Z] ]; then
            echo -e "${RED}ERROR: ${YELLOW}Invalid option please choose a valid numerical value from menu${BLUE}"
        else
            echo -e "\n${GREEN}Installing: ${YELLOW}$opt${RESTORE}"
            apt-get install "$opt"
            break
        fi
    
    done
fi

# Upgrade and install latest version of apktool
APKTOOL_UPGRADE() {
    (wget -O /usr/bin/apktool https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool &>/dev/null;
     wget -O /usr/bin/apktool.jar https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.4.1.jar &>/dev/null;
     [[ -e /usr/bin/apktool ]] && [[ -e /usr/bin/apktool.jar ]] && chmod +x /usr/bin/apktool /usr/bin/apktool.jar) &
    echo
    PROG_MESSAGE="${YELLOW}Installing Apktool 2.4.1${RESTORE}"
    COMP_MESSAGE="${YELLOW}Installed Apktool 2.4.1${RESTORE}"
    spinLoader
    [[ -e /root/.local/share/apktool/framework/1.apk ]] && apktool empty-framework-dir --force &>/dev/null && echo -e "\n${YELLOW}  Emptying framework-dir" 
    APKTOOL_VERSION
}

# Check apktool version
APKTOOL_VERSION() {
    echo -e "\n${BLUE}[-]${YELLOW} Checking the version of ${BLUE}Apktool${YELLOW} you have installed.${RESTORE}"
    sleep 1
    if [ ! -e /usr/bin/apktool.jar ] || [ $(apktool --version | cut -d'.' -f2,3 | tr -d '.' | cut -f1 -d'-' 2>/dev/null) -lt 41 ]; then
        echo -e "\n${RED}**** ${YELLOW}Apktool is not the correct version! ${RED}****${RESTORE}\n"
        echo -e "${YELLOW}Removing Apktool version $(apktool --version 2>/dev/null) please wait...${RESTORE}"
        [[ -e /usr/bin/apktool ]] && rm -f /usr/bin/apktool
        [[ -e /usr/bin/apktool.jar ]] && rm -f /usr/bin/apktool.jar
        APKTOOL_UPGRADE   
    else
        [[ -e /root/.local/share/apktool/framework/1.apk ]] && apktool empty-framework-dir --force &>/dev/null && echo -e "\n${YELLOW}  Emptying framework-dir" 
        echo -e "\n${YELLOW}  Apktool is the ${GREEN}Correct${YELLOW} version${RESTORE}" 
        sleep 1
    fi
}

# Testing for which function to run
[[ $(dpkg-query -s apktool &>/dev/null ; echo $?) = 0 ]] || [[ -e /usr/bin/apktool ]] && APKTOOL_VERSION || APKTOOL_UPGRADE

# End
