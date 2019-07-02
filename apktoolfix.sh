#!/bin/bash 

#Author: graylagx2
#Name: apktoolfix
#Version: 2.0
#Description: Fix for apktool in kali linux.
#Contact: graylagx2@gmail.com

RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[1;34m'
RESTORE=$'\e[0m'

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
    sleep 1;echo 
}

echo -e "${BLUE}"
echo '
         _______                  _____                     ______ 
        |     __.----.---.-.--.--|     |_.---.-.-----.--.--|__    |
        |    |  |   _|  _  |  |  |       |  _  |  _  |_   _|    __|
        |_______|__| |___._|___  |_______|___._|___  |__.__|______|
                           |_____|             |_____|             
'                                                                     
echo -e "${YELLOW}                           Apktool-Fix Version ${BLUE}2.0${RESTORE}"
echo
                                                      
# Checking internet connection to exit with message if none
[[ $(wget -q --tries=5 --timeout=20 --spider http://google.com ; echo $?) != 0 ]] && echo -e "${RED}Warning!${YELLOW} This script needs an internet connection!" && echo && echo -e "${YELLOW}Please connect to the internet and try again.${RESTORE}" && exit

# Checking for for missing dependencies and install missing
    echo -e "\n${BLUE}[-] ${YELLOW}Checking Dependencies${RESTORE}\n"
    mapfile -t pkg_depends < <(apt-cache depends apktool | cut -d':' -f2 | sed  's/^[ \t]*//;/<java7-runtime-headless>/d;/^apktool\b/d;/libcommons-io-java/d;/libcommons-lang3-java/d;/libguava-java/d;/libstringtemplate-java/d;/libxmlunit-java/d' | sort -u)
    pwd=$(pwd)
    for depend in "${pkg_depends[@]}"; do 
        pkg_qry=$(dpkg-query -s $depend &>/dev/null ; echo $?)
        if [ $pkg_qry = 0 ]; then
            echo -e "${YELLOW}$depend is ${GREEN}Installed.${RESTORE}"
        else 
            echo -e "${YELLOW}$depend is ${RED}missing.${RESTORE}"
            MISSING+=($depend)
            [[ -e /tmp/repair_depends ]] || mkdir /tmp/repair_depends
            cd /tmp/repair_depends && apt-get download $depend &>/dev/null
            cd $pwd     
        fi
    done  

    if [[ ! -z $MISSING ]]; then 
        [[ "${MISSING[*]} " != *"aapt"* ]] && [[ "${MISSING[*]} " == *"google-android-build-tools-installer"* ]] && MISSING=( "${MISSING[@]/google-android-build-tools-installer/}" ) && rm /tmp/repair_depends/google-android-build-tools-installer*
        [[ "${MISSING[*]} " != *"google-android-build-tools-installer"* ]] && [[ $(dpkg-query -s google-android-build-tools-installer &>/dev/null ; echo $?) = 0 ]] && [[ "${MISSING[*]} " == *"aapt"* ]] && MISSING=( "${MISSING[@]/aapt/}" ) && rm /tmp/repair_depends/aapt*
        
        if [[ "${MISSING[*]} " == *"aapt"* ]] && [[ "${MISSING[*]} " == *"google-android-build-tools-installer"* ]]; then
            echo -e "\n${RED}ATTENTION:${YELLOW} The following packages conflict with each other please select one to install:${BLUE}  \n"
          
            options=("aapt" "google-android-build-tools-installer" "help")                    
            select opt in "${options[@]}"
                do
                    case $opt in
                        "aapt")
                            MISSING=( "${MISSING[@]/google-android-build-tools-installer/}" )
                            rm /tmp/repair_depends/google-android-build-tools-installer*
                            break
                        ;;
                        "google-android-build-tools-installer")
                            MISSING=( "${MISSING[@]/aapt/}" )
                            rm /tmp/repair_depends/aapt*
                            break
                        ;;
                        "help")
                            echo
                            echo -e "${YELLOW}The package google-android-build-tools-installer is large and contains aapt in addition to other packages that may not be necessary to run apktool. We recomend just installing aapt itself.${BLUE}"
                            echo
                            sleep 2
                        ;;
                        *)
                            echo
                            echo -e "Invalid option please enter a valid numerical option"
                        ;;
                        esac
                done  

            #use for loop to parse errors
            (dpkg -i /tmp/repair_depends/* &>/dev/null) &  
            echo
            PROG_MESSAGE="${YELLOW}Installing dependencies${RESTORE}"
            COMP_MESSAGE="${YELLOW}Installed dependencies${RESTORE}"
            spinLoader;echo 
        fi              
    
        [[ -z ${MISSING[@]} ]] || echo -e "\n${YELLOW}The following dependencies were installed:\n" && sleep 2 && for depends in ${MISSING[@]}; do echo -e "${BLUE}$depends${RESTORE}"; done; sleep 2
        rm -r -f /tmp/repair_depends
    fi

# Upgrade and install latest version of apktool
APKTOOL_UPGRADE() {
    (axel -n 10 --output=/usr/bin/apktool https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool &>/dev/null;
     axel -n 10 --output=/usr/bin/apktool.jar https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.4.0.jar &>/dev/null;
     [[ -e /usr/bin/apktool ]] && [[ -e /usr/bin/apktool.jar ]] && chmod +x /usr/bin/apktool /usr/bin/apktool.jar) &
    echo
    PROG_MESSAGE="${YELLOW}Installing Apktool 2.4.0${RESTORE}"
    COMP_MESSAGE="${YELLOW}Installed Apktool 2.4.0${RESTORE}"
    spinLoader;echo 
    APKTOOL_VERSION
}

# Check apktool version
APKTOOL_VERSION() {
    echo -e "\n${YELLOW}Checking the version of Apktool you have installed.${RESTORE}"
    sleep 1
    verCheck=$(apktool --version | cut -d'.' -f2)
    if [ $verCheck -lt 4 ]; then
        echo -e "\n${RED}**** ${YELLOW}Apktool is not the latest version! ${RED}****${RESTORE}\n"
        echo -e "\n${YELLOW}Removing Apktool version $(apktool --version) please wait...${RESTORE}"
        [[ -e /usr/bin/apktool ]] && rm -f /usr/bin/apktool
        [[ -e /usr/bin/apktool.jar ]] && rm -f /usr/bin/apktool.jar
        APKTOOL_UPGRADE   
    else
        echo -e "\n${YELLOW}Apktool is ${GREEN}version 2.4.0${RESTORE}" 
        sleep 1
    fi
}

# Testing for which function to run
[[ $(dpkg-query -s apktool &>/dev/null ; echo $?) = 0 ]] || [[ -e /usr/bin/apktool ]] && APKTOOL_VERSION || APKTOOL_UPGRADE

# End
echo -e "\n${GREEN}Apktool Fix Complete${RESTORE}\n"
