#!/bin/bash

##########################################################################################################################

# Copyright 2022 Tri Nguyen (trinv@vnnic.vn)
# Author:  Tri Nguyen (trinv@vnnic.vn)
# This program used to install DNS Server Automation)
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# File : bird_installer.sh : A simple shell script to Install BIRD

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
echo "##${txtgrn}        Welcome To All In One DNS Server (VNNIC) Script${txtrst}     ##"
echo "##                  Created By trinv                       ##"
echo "##          ${txtylw}       trinv@vnnic.vn   ${txtrst}                       ##"
echo "##                                                         ##"
echo "#############################################################"
echo "#############################################################"
echo ""
echo ""
#########################################################################################################################

sleep 2


############ Variable Definitions  ################
path='/tmp'
log=/tmp/bird_setup.log
path_package='/tmp/packages_install'
bird_logs='/data/logbird'

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
    echo "##${txtgrn} Thank You for using All In One DNS Server (VNNIC) Script${txtrst}##"
    echo "##                       Created By VNNIC                     ##"
    echo "##          ${txtylw}              trinv@vnnic.vn   ${txtrst}              ##"
    echo "##                                                         ##"
    echo "#############################################################"
    echo "#############################################################"
    echo ""
    echo ""
    ##########################################################################################################################
    sleep 2
}

finish() {
    echo "${txtgrn}Congratulation, DNS Server installation Completed successfullyy.${txtrst}"
    sleep 5
    echo "DNS Server Installation Completed successfullyy" 2> /dev/null  >> $log
    echo ""
    sleep 1
    #cd $path_package;rm -rf *
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
set_repo () {
    cd $path
    curl -O http://10.0.0.133/installer/repos/remote.repo; rm -rf /etc/yum.repos.d/*;cp -f *.repo /etc/yum.repos.d/ 2>/dev/null
    check
}

download_packages () {
    echo "${txtylw}Dowloading the packages installation${txtrst}" 
    cd $path
    curl http://10.0.0.133/installer/packages_install.tar.gz -O 2>/dev/null
    check
    echo " ${txtgrn}Done{txtrst}"
    sleep 1
    echo "${txtylw}Extract package installation${txtrst}"
    tar -xvf packages_install.tar.gz 2>/dev/null
    check
    echo " ${txtgrn}Done{txtrst}"

}

install_bird() {
    echo "${txtylw}Extract package BIRD${txtrst}"
    sleep 1
    cd $path_package/bird
    tar -zxvf bird-*.tar.gz 
    check
    echo "${txtgrn}Done${txtrst}"
    sleep 1
    echo "Extract package BIRD successfully"
    echo
    echo "${txtylw}Compiling BIRD${txtrst}"
    sleep 1
    cd $path_package/bird/bird-*
    ./configure;check;echo;sleep 1;make;echo;sleep 1;check;make install;check 2>/dev/null >> $log
    /usr/local/sbin/bird
    echo "${txtgrn}Done${txtrst}"
    echo
    sleep 1
    echo "${txtylw}Restarting BIRD Service${txtrst}"
    sleep 1
    #cp $path/bird.service.conf /etc/systemd/system/bird.service 2>/dev/null
    #systemctl daemon-reload 2>/dev/null
    #systemctl restart bird 2>/dev/null
    #systemctl enable bird 2>/dev/null
    echo "${txtgrn}Done${txtrst}"
    sleep 1
    echo "Restarting BIRD Service Successfull" 2>/dev/null >> $log
    bird_version=`/usr/local/sbin/birdc show status | grep 'BIRD' | awk {'print $2'} | head -1 2>/dev/null`
    sleep 2
    echo
    echo
    echo "${txtgrn}${bird_version} has been installed !!!${txtrst}"

}

install_bird_depend() {
############ Installation Some Packages Needed to Install BIRD  ################
    set_repo
    echo "${txtylw}Installation Some Packages Needed to Install BIRD.${txtrst}"

    #################################################################################
    #Requirement packages:
    #+ GNU C Compiler (or LLVM Clang)
    #+ GNU Make
    #+ GNU Bison
    #+ GNU M4
    #+ Flex
    #+ ncurses library: yum install ncurses-devel
    #+ GNU Readline library: yum install readline-devel
    #+ libssh library (optional, for RPKI-Router protocol)
    #+ binutils
    #################################################################################

    sleep 1
    yum install -y gcc glibc glibc-common gd gd-devel make net-snmp-* wget zip unzip tar curl bison ncurses-devel readline-devel binutils flex m4 libssh*;check
    sleep 1
    echo "${txtgrn}Done${txtrst}"
    echo
    sleep 2
}

install_aide () {
    echo "${txtylw}Installation AIDE.${txtrst}"
    yum install -y aide
    check
    echo "${txtgrn}Done${txtrst}"
}

install_snmpd () {
    echo "${txtylw}Installation SNMP.${txtrst}"
    yum install -y net-snmp
    check
    cd $path_package/snmpd
    cp -f snmpd* /etc/snmpd/snmpd.conf
    systemctl restart snmpd 2>/dev/null
    systemctl enable snmpd 2>/dev/null 
    echo "${txtgrn}Done${txtrst}"
}

install_syslogng () {
    echo "${txtylw}Installation Syslog-NG.${txtrst}"
    cd $path_package/syslog-ng_rh7
    rpm -ivh eventlog-0.2.13-4.el7.x86_64.rpm 2>/dev/null
    rpm -ivh libnet-1.1.6-7.el7.x86_64.rpm 2>/dev/null
    rpm -ivh ivykis-0.36.2-2.el7.x86_64.rpm 2>/dev/null
    rpm -ivh syslog-ng-3.5.6-3.el7.x86_64.rpm 2>/dev/null
    check
    cp -f syslog-ng.conf /etc/syslog-ng/
    systemctl restart syslog-ng 2>/dev/null
    systemctl enable syslog-ng 2>/dev/null
    check
    echo "${txtgrn}Done${txtrst}"
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
check_os () {
    ############ Checking OS  ################
    echo "${txtylw}Try to check your operating system "
    sleep 2
    if [ -f /etc/debian_version ]
        then
            echo "${txtgrn}Your Operating System is `cat /etc/os-release | grep ^NAME | awk 'NR > 1 {print $1}' RS='"' FS='"'` `cat /etc/debian_version`${txtrst}"
            sleep 2
            echo
            install_packet_debian
            echo
        else

    if [ -f /etc/redhat-release ]
        then
            echo "${txtgrn}Your Operating System is `cat /etc/redhat-release`"
            sleep 2
            echo
            install_server
        else
    if [ -f /etc/SUSE-brand ]
    then
        echo "${txtgrn}Your Operating System is `cat /etc/os-release | grep PRETTY_NAME | sed 's/.*=//' | sed 's/^.//' | sed 's/.$//'`"
        echo
        sleep 2
        install_packet_opensuse
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

install_server () {
    download_packages
    install_bird_depend
    install_bird
    install_aide
    install_syslogng
    install_snmpd
}

notice () {
    ############ Disable Firewall and SELinux  ################
    echo
    sleep 2
    echo "${txtbld}The script will install DNS Server Automation${txtrst}"
    sleep 3
    echo
    echo
}

install_dns_server () {
    notice
    check_internet
    check_user
    check_os
}

install_dns_server