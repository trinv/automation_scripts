#!/bin/bash

##########################################################################################################################

# Copyright 2022 Tri Nguyen (trinv@vnnic.vn)
# Author:  Tri Nguyen (trinv@vnnic.vn)
# This program used to install BIND9 (lastest & stabled BIND9 versions from source code provided by ISC: isc.org)
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# File : bind9_installer.sh : A simple shell script to Install BIND9

##########################################################################################################################


# Text color variables

txtund=$(tput sgr 0 1)    # Underline
txtbld=$(tput bold)       # Bold
txtred=$(tput setaf 1)    # Red
txtgrn=$(tput setaf 2)    # Green
txtylw=$(tput setaf 3)    # Yellow
txtblu=$(tput setaf 4)    # Blue
txtpur=$(tput setaf 5)    # Purple
txtcyn=$(tput setaf 6)    # Cyan
txtwht=$(tput setaf 7)    # White
txtrst=$(tput sgr0)       # Text reset

clear

#########################################################################################################################
echo ""
echo ""
echo "#############################################################"
echo "#############################################################"
echo "##                                                         ##"
echo "##${txtgrn}         Welcome To All In One BIND9 (VNNIC) Script${txtrst}      ##"
echo "##                  Created By trinv                       ##"
echo "##          ${txtylw}          trinv@vnnic.vn   ${txtrst}                    ##"
echo "##                                                         ##"
echo "#############################################################"
echo "#############################################################"
echo ""
echo ""
#########################################################################################################################

sleep 2


############ Variable Definitions  ################
path='/tmp'
log=/tmp/bind9_setup.log
bind9_dir='/data/named'
bind9_run='/var/run-named'
bind9_logs='/data/logdns'


############ Functions Definition ################

stop() {
sleep 2
echo ""
echo ""
exit 0
}

thankyou() {
#########################################################################################################################
echo ""
echo ""
echo "#############################################################"
echo "#############################################################"
echo "##                                                         ##"
echo "##${txtgrn}  Thank You for using All In One BIND9 (VNNIC) Script${txtrst}  ##"
echo "##                       Created By VNNIC                     ##"
echo "##          ${txtylw}           trinv@vnnic.vn   ${txtrst}                 ##"
echo "##                                                         ##"
echo "#############################################################"
echo "#############################################################"
echo ""
echo ""
##########################################################################################################################
sleep 2
}

finish() {
echo "${txtgrn}Congratulation, BIND9 installation Completed successfullyy.${txtrst}"
sleep 5
echo "BIND9 Installation Completed successfullyy" 2> /dev/null  >> $log
echo ""
echo "${txtpur}Here is detail information:${txtrst}"
sleep 2
echo "Here is the details:" 2> /dev/null  >> $log
echo "BIND9 Configuration File ' /etc/named.*.conf '" 2> /dev/null  >> $log
sleep 2

echo
echo "${txtpur}Note${txtrst}"
sleep 2
echo "${txtred} ******** Check BIND9 installation Log File in /tmp/bind9_setup.log ******** ${txtrst}"
echo ""
sleep 2

echo " ${txtgrn}     ********** Thank You For Using All in One BIND9 Script ********** ${txtrst}"
echo "              ${txtgrn}     ******** trinv@vnnic.vn ******** ${txtrst}"
echo "                     ${txtgrn}     ****** Thank You ****** ${txtrst}"
echo

echo " ********** Thank You For Using All in One BIND9 Script ********** " 2> /dev/null >> $log
echo "" 2> /dev/null  >> $log
echo "                  ******** trinv@vnnic.vn ******** " 2> /dev/null  >> $log
echo
echo
sleep 3
cd $path;rm -rf bind-9.*
exit 0
sleep 2
echo
echo
}

check() {
if [ $? != 0 ]
then
echo
echo "${txtred}I am sorry, I cannot continue the process because there was a problem. Please fix it first. ${txtrst}"
stop
thankyou
fi
}

bind9_intro () {
printf "%s\n" "#####################################################################"
printf "%s\n" "#  _____           _        _ _     ______               _   ____   #"       
printf "%s\n" "# |_   _|         | |      | | |   |  __  \(_)          | |/  __  \ #" 
printf "%s\n" "#   | |  _ __  ___| |_ __ _| | |   | |__| | _ _ __    __| || |__| | #"
printf "%s\n" "#   | | |  _ \/ __] __/ _  | | |   |  __ - | |  _ \ /  _  |\ ___/ | #"
printf "%s\n" "#  _| |_| | | \__ \ || (_| | | |   | |__| || | | | | \__| |    / /  #"
printf "%s\n" "# |_____|_| |_|___/\__\__,_|_|_|   |______/|_|_| |_|\___/_|   /_/   #"
printf "%s\n" "#                                                                   #"
printf "%s\n" "#                                                                   #"
printf "%s\n" "#                                                                   #"
printf "%s\n" "#####################################################################"

}

bind9core_centos_install() {

echo "${txtylw}Extract package BIND9${txtrst}"
sleep 2
cd $path
tar -zxvf bind-9.11.*.tar.gz 
#rm -rf bind9.tar.gz
check
echo "${txtgrn}Done${txtrst}"
sleep 2
echo "Extract package BIND9 successfully" 2>/dev/null >> $log
echo;echo
echo "${txtylw}Adding user and group for BIND9${txtrst}"
sleep 2
useradd -s /sbin/nologin -d /var/named -c "named" named 2>/dev/null >> $log
echo "Adding user and group for BIND9 successfully" 2> /dev/null >> $log
echo "${txtgrn}Done${txtrst}"
sleep 2;echo
echo "${txtylw}Compiling BIND9${txtrst}"
sleep 2
cd $path/bind-9.11.*
./configure --without-python 2>/dev/null >> $log
check
echo
sleep 1
make all 2>/dev/null >> $log
echo
sleep 1
check
make install 2>/dev/null >> $log
check
echo "${txtgrn}Done${txtrst}"
echo
sleep 2
chown -R named:named $bind9_dir
chown -R named:named $bind9_run
chown -R named:named $bind9_logs
echo "${txtylw}Restarting BIND9 Service${txtrst}"
sleep 1
cp $path/named.service.conf /etc/systemd/system/named.service 2>/dev/null
systemctl daemon-reload 2>/dev/null
systemctl restart named 2>/dev/null
systemctl enable named 2>/dev/null
echo "${txtgrn}Done${txtrst}"
sleep 2
echo "Restarting BIND9 Service Successfull" 2>/dev/null >> $log
bind9_version=`named -v 2>/dev/null`
sleep 2
echo
echo
echo "${txtgrn}${bind9_version} has been installed !!!${txtrst}"

}


install_centos() {
############ Installation Some Packages Needed to Install BIND9  ################
bind9_intro
echo "${txtylw}Installation Some Packages Needed to Install BIND9.${txtrst}"


sleep 1
yum install -y gcc glibc glibc-common gd gd-devel make net-snmp-* wget zip unzip tar curl;check
sleep 1
echo "${txtgrn}Done${txtrst}"
echo
sleep 2
bind9_centos
}

create_bind9_directory () {


if [ ! -d  "$bind9_dir" ]; then
        mkdir -p $bind9_dir
fi

if [ ! -d  "$bind9_run" ]; then
        mkdir -p $bind9_run
fi

if [ ! -d  "$bind9_logs" ]; then
        mkdir -p $bind9_logs
fi



}
bind9_centos() {

############ Download BIND9 version bind-9.11.x  ################
echo "${txtylw}Download BIND9 version bind-9.11.x${txtrst}"
echo
create_bind9_directory
echo
read -p "Are you sure want to continue (y/n)? " answer
	case $answer in
        [yY]* )   echo "${txtpur}Okay, I will download BIND9 version bind-9.11.x from ISC.${txtrst}"
            sleep 2
            echo
	        cd $path;wget  --no-check-certificate https://ftp.isc.org/isc/bind9/9.11.37/bind-9.11.37.tar.gz
        	count=`ls -1 bind-9.*.tar.gz  2>/dev/null | wc -l`
                if [ $count != 0 ]
                    then
                        bind9core_centos_install
                else
			        echo;
                    echo "${txtylw}Wait a minute, I look for another source ...${txtrst}";sleep 2
                    mv bind-9.*.tar.gz /opt/
                    cd $path;wget  --no-check-certificate 'https://ftp.isc.org/isc/bind9/9.11.37/bind-9.11.37.tar.gz'       	        
                    echo "${txtgrn}BIND9 version bind-9.11.x has been download and we will install it to your server${txtrst}"
			        echo
                    sleep 2
                        bind9core_centos_install
                fi
		        ;;
	    [nN]* )   sleep 2
		    thankyou
		;;
	    * )    echo "Just enter Y or N, please."
        ;;
    esac    	            
        
}



install_bind9_centos () {
install_centos
}

check_internet () {
############ Checking Internet  ################
echo "${txtylw}I will check whether the server is connected to the internet or not. ${txtrst}"
echo "${txtylw}Please wait a minute ...${txtrst}"
ping -q -c5 google.com >> /dev/null
if [ $? = 0 ]
then
echo "${txtgrn}Great, Your server is connected to the internet${txtrst}"
echo "Your System is Connected to Internet" 2> /dev/null  >> $log
sleep 2
echo
else
echo "${txtred}Your server is not connected to the internet so the I can not continue to install Nagios.${txtrst}"
echo "${txtred}Please connect the internet first ...!${txtrst}"
echo "Please connect to the internet ..." 2> /dev/null >> $log
stop
fi
}

check_user () {
############ Checking account  ################
echo "${txtylw}Try to check your account "
sleep 2
user=`whoami`
if [ $user = "root" ]
then
echo "${txtgrn}Good, your account is root${txtrst}"
echo "Your account is root" 2> /dev/null >> $log
echo
else
echo "${txtred}Please change first to root account${txtrst}"
echo "Please change first to root" 2> /dev/null >> $log
stop
fi
sleep 1
}

check_packet_centos () {
############ Checking BIND9  ################
echo "${txtylw}Try to check existing BIND9 "

#find / -name named.conf > check_named.txt

#size1=`ls -al | grep check_named.txt | awk '{print $5}'`
#sleep 2

#named -v | grep 'BIND' >>/dev/null

check_bind=`ls -1 /usr/local/sbin/named  2>/dev/null | wc -l`

if [$check_bind != 0]
then
    echo "${txtgrn}It looks like you have installed BIND9. ${txtrst}"
	sleep 1
	echo "${txtgrn}Please, delete your BIND9 first. ${txtrst}"
	echo
    sleep 2
    exit

else

    echo "${txtcyn}Ok, I will install BIND9 in your server as soon as possible. ${txtrst}"
    sleep 2
    echo
    install_bind9_centos
fi

}


check_os () {
############ Checking OS  ################
echo "${txtylw}Try to check your operating system "
sleep 2
if [ -f /etc/debian_version ]
then
echo "${txtgrn}Your Operating System is `cat /etc/os-release | grep ^NAME | awk 'NR > 1 {print $1}' RS='"' FS='"'` `cat /etc/debian_version`${txtrst}"
sleep 2
echo
check_packet_ubuntu
echo
else

if [ -f /etc/redhat-release ]
then
echo "${txtgrn}Your Operating System is `cat /etc/redhat-release`"
sleep 2
echo
check_packet_centos
else

if [ -f /etc/SUSE-brand ]
then
echo "${txtgrn}Your Operating System is `cat /etc/os-release | grep PRETTY_NAME | sed 's/.*=//' | sed 's/^.//' | sed 's/.$//'`"
echo
sleep 2
check_packet_opensuse
echo
else

echo "${txtred}I think your OS is not Debian/Ubuntu or RedHat-Based (CentOS, AlmaLinux, RockyLinux) or openSUSE${txtrst}"
echo "${txtred}I am sorry, only work on Linux Debian/Ubuntu, RedHat-Based (CentOS, AlmaLinux, RockyLinux), and openSUSE${txtrst}"
echo "${txtred}So, I can not install BIND9 in your server${txtrst}"
stop
fi
fi
fi
}

notice () {
############ Disable Firewall and SELinux  ################
echo
sleep 2
echo "${txtbld}The script will install BIND9 from source code with using customized folder (/data/named)${txtrst}"
sleep 3
echo
echo
}

install_bind9 () {
notice
check_internet
check_user
check_os
}




echo "What do you want from me?"
echo "${txtgrn}1. Install BIND9${txtrst}"
echo "${txtred}2. Uninstall BIND9${txtrst}"
echo -n "Enter Your choice: "
read IN_CASE
echo
case $IN_CASE in
1) 
install_bind9 ;;
2)
delete_bind9 ;;

*) echo "${txtred}Enter the wrong number and exit the program${txtrst}"
   echo;;

esac