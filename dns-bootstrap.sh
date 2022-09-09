#!/bin/bash

##########################################################################################################################

# Copyright 2022 Tri Nguyen (trinv@vnnic.vn)
# Author:  Tri Nguyen (trinv@vnnic.vn)
# This program used to install DNS Server Full Automation.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# File : bird_installer.sh : A simple shell script to Install DNS Server Full Automation

##########################################################################################################################

############ Variable Definitions  ################

install_archive_url="http://10.0.0.133/installer/install-package"
DNS_INSTALL_DIR="/root/dns-deploy"
server_name=""
package_password=""
dst_dir="$DNS_INSTALL_DIR"
dst_package="$dst_dir/install-package"
mkdir -p $DNS_INSTALL_DIR

export DNS_INSTALL_DIR

# Installation LOG file
STEP_LOG="/root/dns-deploy.log"
echo -n > $STEP_LOG

# Check if this script has root credentials
if [ $(id -u) -ne "0" ]; then  echo "This script should be executed by root. Aborting."; exit 1; fi


############ Functions Definition ################

# Set the repo config to connect the Repos Server
function set_repo {
    cd $path
    curl -O http://10.0.0.133/installer/repos/remote.repo
    rm -rf /etc/yum.repos.d/*
    cp -f *.repo /etc/yum.repos.d/ 
    conf_step $? "Setting the Repos Server"
}

# User reporting
function conf_step {
  status="$1"
  message="$2"

  printf "%60s ... " "$message"
  if [ $status -eq 0 ]; then
    echo -e "\033[1;32mOK\033[0m"
  else
    echo -e "\033[1;31mFAILED\033[0m"
    exit $status
  fi
}



# Checking the minimum requirements for this script to run
function prerequisites_check {
  which curl                                                >/dev/null 2>&1
  conf_step $? "Detecting URL fetch program"

  # OpenSSL
  rpm -qa | egrep -i '^openssl'                                    >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    yum -y install openssl                                  >/dev/null 2>&1
    conf_step $? "Installing OpenSSL package."
  fi
  conf_step $? "Detecting OpenSSL"
  

  # OpenSSL Devel
  rpm -qa | egrep -i '^openssl-devel'                              >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    yum -y install openssl-devel                            >/dev/null 2>&1
    conf_step $? "Installing OpenSSL Devel package."
  fi
  conf_step $? "Detecting OpenSSL Devel"
  

  # Temporary directory
  mkdir -p $dst_dir
  conf_step $? "Creating temp directory"

}

# Download the Installation Packages on Repos Server
function download_install_package {
  src_url="$1"
  dst_file="$2"

  echo "Downloading installation package, please wait."
  curl -L -s --fail -4 -o "$dst_file" --url "$src_url"
  conf_step $? "Installation package download"
}

### Hostname configuration
function input_data {
  while [ -z "$server_name" ]; do
    echo -n "Specify this host name: "
    read server_name
  done

  while [ -z "$package_password" ]; do
    echo -n "Installation package password: "
    read -s package_password
    export package_password
    echo
  done
}

function decrypt_package {
  key="$1"
  src_file="$2"
  dst_file="$3"

  openssl aes-256-cbc -md sha256 -d -k "$key" -salt -in $src_file -out $dst_file
  conf_step $? "Decrypting installation package"
} 

function unpack_package {
  src_file="$1"
  exitstatus=0

  tar -C $dst_dir -xvf $src_file >/dev/null 2>&1 ;  exitstatus=$(($exitstatus+$?))
  conf_step $exitstatus "Installation package integrity"
}

########################################Install BIND9##################################################
bind9_dir="/data/named"
bind9_run="/var/run-named"
bind9_logs="/data/logdns"

function create_bind9_dir {
    if [ ! -d  "$bind9_dir" ]; then
            mkdir -p $bind9_dir
    fi
    if [ ! -d  "$bind9_run" ]; then
            mkdir -p $bind9_run
    fi
    if [ ! -d  "$bind9_logs" ]; then
            mkdir -p $bind9_logs
    fi
    conf_step $? "Creating BIND9 directory"
}
function extract_bind9 {
    cd $dst_package/bind9
    tar -zxvf bind-9.11.*.tar.gz                                        >/dev/null 2>&1
    conf_step $? "Extracting package BIND9"
}

function add_bind9_user {
    egrep -i "^named" /etc/passwd                                       >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        useradd -s /sbin/nologin -d /var/named -c "named" named         >/dev/null 2>&1
        conf_step $? "Adding user and group for BIND9"
    
    fi
    
    conf_step $? "User named already exists"

}

function compli_bind9 {
    cd $dst_package/bind9/bind-9.11.*
    ./configure --without-python                                        >/dev/null 2>&1
    make all                                                            >/dev/null 2>&1 
    make install                                                        >/dev/null 2>&1
    chown -R named:named $bind9_dir                                     >/dev/null 2>&1
    chown -R named:named $bind9_run                                     >/dev/null 2>&1
    chown -R named:named $bind9_logs                                    >/dev/null 2>&1
    conf_step $? "Compiling BIND9"
   
}
function add_named_service {
    cp $dst_package/bind9/named.service.conf /etc/systemd/system/named.service  >/dev/null 2>&1
    conf_step $? "Adding named to Systemd"

}

function bind9_status {
    bind9_version=`named -v | awk '{print $1" " $2}'`                           >/dev/null 2>&1
    conf_step $? "BIND9 version $bind9_version has been installed"

}


########################################Install BIRD##################################################

# Installation Some Packages Needed to Install BIRD
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
function depend_packages {
    check_binutils
    check_binutils_devel
    check_bison
    check_flex
    check_gcc
    check_glibc
    check_libssh2
    check_m4
    check_make
    check_ncurses
    check_ncurses_devel
    check_readline
    check_readline_devel
    check_snmp
}

function check_gcc {
    rpm -qa  | egrep -i '^gcc'                                                     >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install gcc                                              >/dev/null 2>&1
            conf_step $? "Installing GCC package."
        fi
            conf_step $? "Detecting GCC"
        
}
function check_glibc {        
    rpm -qa  | egrep -i '^glibc'                                                   >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install glibc glibc-common                               >/dev/null 2>&1
            conf_step $? "Installing glibc package."
        fi
            conf_step $? "Detecting glibc"
}
function check_make {        
    rpm -qa  | egrep -i '^make'                                                    >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install make                                             >/dev/null 2>&1
            conf_step $? "Installing make package."
        fi
            conf_step $? "Detecting glibc"
}
function check_snmp {      
    rpm -qa  | egrep -i '^net-snmp'                                                >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install net-snmp                                         >/dev/null 2>&1
            conf_step $? "Installing net-snmp package."
        fi
            conf_step $? "Detecting net-snmp"
}
function check_bison {        
    rpm -qa   | egrep -i '^bison'                                                  >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install bison                                            >/dev/null 2>&1
            conf_step $? "Installing bison package."
        fi
            conf_step $? "Detecting bison"
}
function check_ncurses {        
    rpm -qa   | egrep -i '^ncurses'                                                >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install ncurses                                          >/dev/null 2>&1
            conf_step $? "Installing ncurses package."
        fi
            conf_step $? "Detecting ncurses"
}
function check_ncurses_devel {
    rpm -qa   | egrep -i '^ncurses-devel'                                          >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install ncurses-devel                                    >/dev/null 2>&1
            conf_step $? "Installing ncurses-devel package."
        fi
            conf_step $? "Detecting ncurses-devel"
}
function check_readline {        
    rpm -qa    | egrep -i '^readline'                                              >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install readline                                         >/dev/null 2>&1
            conf_step $? "Installing readline package."
        fi
            conf_step $? "Detecting readline"
}
function check_readline_devel {
    rpm -qa  | egrep -i '^readline-devel'                                          >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install readline-devel                                   >/dev/null 2>&1
            conf_step $? "Installing readline-devel package."
        fi
            conf_step $? "Detecting readline-devel"
        
}
function check_binutils {               
    rpm -qa   | egrep -i '^binutils'                                               >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install binutils                                         >/dev/null 2>&1
            conf_step $? "Installing binutils package."
        fi
            conf_step $? "Detecting binutils"
}
function check_binutils_devel {
    rpm -qa  | egrep -i '^binutils-devel'                                          >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install binutils-devel                                   >/dev/null 2>&1
            conf_step $? "Installing binutils-devel package."
        fi
            conf_step $? "Detecting binutils-devel"
}
function check_flex {        
    rpm -qa | egrep -i '^flex'                                                    >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install flex | wc -l                                     >/dev/null 2>&1
            conf_step $? "Installing flex package."
        fi
            conf_step $? "Detecting flex"
}
function check_m4 {    
    rpm -qa | egrep -i '^m4'                                                       >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install m4 | wc -l                                       >/dev/null 2>&1
            conf_step $? "Installing m4 package."
        fi
            conf_step $? "Detecting m4"
}
function check_libssh2 {        
    rpm -qa  | egrep -i '^libssh2'                                                 >/dev/null 2>&1
            if [ $? -ne 0 ]; then
            yum -y install libssh*                                          >/dev/null 2>&1
            conf_step $? "Installing libssh package."
        fi
            conf_step $? "Detecting libssh"
        
}
##################################################################################################

function extract_bird {
    cd $dst_package/bird
    tar -zxvf bird-*.tar.gz                                                 >/dev/null 2>&1
    conf_step $? "Extracting package BIRD"
}

function compli_bird {
    cd $dst_package/bird/bird-*
    ./configure                                                             >/dev/null 2>&1
    make                                                                    >/dev/null 2>&1
    make install                                                            >/dev/null 2>&1
    conf_step $? "Compiling package BIRD"
}

function bird_status {
    /usr/local/sbin/bird
    bird_version=`/usr/local/sbin/birdc show status | grep 'BIRD' | awk {'print $2'} | head -1`     >/dev/null 2>&1
    conf_step $? "BIRD version $bird_version has been installed"

}

########################################Other Packages##################################################

function install_aide  {
    rpm -qa  | egrep -i '^aide'                                                    >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install aide                                             >/dev/null 2>&1
            conf_step $? "Installing aide package."
        fi
            conf_step $? "Detecting aide"          
}
function config_aide {
    mkdir -p /data/logsystem
    cd $dst_package/aide
    cp -f aide-update /data/logsystem/
    cp -f aide-notify /data/logsystem/
    chown -R 755 /data/logsystem
    conf_step $? "Configuration AIDE"
}

function config_snmpd {
    cd $dst_package/snmpd
    cp -f snmpd.conf /etc/snmp/snmpd.conf
    conf_step $? "Configuration SNMP"
}

function install_syslogng  {
    cd $dst_package/syslog-ng_rh7
    rpm -qa  | egrep -i '^eventlog-'                                                >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            rpm -ivh eventlog-0.2.13-4.el7.x86_64.rpm                       >/dev/null 2>&1            
            conf_step $? "Installing eventlog package."
        fi
            conf_step $? "Detecting eventlog"
    rpm -qa  | egrep -i '^libnet-'                                                  >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            rpm -ivh libnet-1.1.6-7.el7.x86_64.rpm                          >/dev/null 2>&1               
            conf_step $? "Installing libnet package."
        fi
            conf_step $? "Detecting libnet"
    rpm -qa  | egrep -i '^ivykis-'                                                  >/dev/null 2>&1
        if [ $? -ne 0 ]; then
        rpm -ivh ivykis-0.36.2-2.el7.x86_64.rpm                             >/dev/null 2>&1              
            conf_step $? "Installing ivykis package."
        fi
            conf_step $? "Detecting ivykis" 
    rpm -qa  | egrep -i '^syslog-ng-3.5'                                           >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            rpm -ivh syslog-ng-3.5.6-3.el7.x86_64.rpm                       >/dev/null 2>&1 
            conf_step $? "Installing SYSLOG-NG."
        fi
            conf_step $? "Detecting syslog-ng-3.5"            

}
function config_syslogng {
    cd $dst_package/syslog-ng_rh7
    cp -f syslog-ng.conf /etc/syslog-ng/
#    systemctl restart syslog-ng >/dev/null
#    systemctl enable syslog-ng >/dev/null
    conf_step $? "Configuration SYSLOG-NG"
}

function install_ntp  {
    rpm -qa  | egrep -i '^ntp'                                                     >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            yum -y install ntp                                              >/dev/null 2>&1
            conf_step $? "Installing NTP package."
        fi
            conf_step $? "Detecting NTP"          
}

function config_ntp  {
    cd $dst_package/ntp
    cp -f ntp.conf /etc/ntp.conf
    systemctl restart ntpd                                                  >/dev/null 2>&1
    systemctl enable ntpd                                                   >/dev/null 2>&1
    conf_step $? "Configuration NTP"          
}

function install_logrhythm {
    cd $dst_package/logrhythm
    rpm -qa  | egrep -i '^scsm'                                                    >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            rpm -ivh scsm-7.6.0.8004-1.el7.x86_64.rpm                       >/dev/null 2>&1
            conf_step $? "Installing Logrhythm Agent."
        fi
            conf_step $? "Detecting Logrhythm Agent"   
    cp -f scsm_linux.txt /opt/logrhythm/scsm/
    systemctl restart scsm                                                  >/dev/null 2>&1               
    systemctl enable scsm                                                   >/dev/null 2>&1
    conf_step $?  "Logrhythm Agent Installed"   

}
function install_deepsecurity {
    cd $dst_package/deepsecurity
    rpm -qa  | egrep -i '^ds_agent'                                               >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            rpm -ivh Agent-PGPCore-RedHat_EL7-20.0.0-2009.x86_64.rpm        >/dev/null 2>&1
            conf_step $? "Installing Deep Security"
        fi
            conf_step $? "Detecting Logrhythm Agent"   

}

# Remove temporary files after automatic install
function auto_install_cleanup {
  tmp_dir="$DNS_INSTALL_DIR"
  if [ -d "$tmp_dir" ]; then
    rm -rf $tmp_dir
    return $?
  fi

  return 0
}
SRV_IP=`ip route get 1 | sed 's/^.* src \([0-9.]*\).*$/\1/;q'`

### Hostname configuration
function configure_hostname {
  hostnamectl set-hostname "$server_name" && \
  echo "$SRV_IP  $server_name" >> /etc/hosts
  echo "$server_name" > /etc/hostname

  return $?
}

# Perform actions
set_repo
prerequisites_check
input_data
download_install_package $install_archive_url $dst_package.aes
decrypt_package "$package_password" $dst_package.aes $dst_package.tar.gz
unpack_package $dst_package.tar.gz

echo "Checking requirements package, please wait."
depend_packages
echo "Installing BIND9, please wait."
create_bind9_dir
extract_bind9
add_bind9_user
compli_bind9
#add_named_service
bind9_status
echo "Installing BIRD, please wait."
extract_bird
compli_bird
bird_status
echo "Installing Admin Tools, please wait."
install_aide
config_aide
config_snmpd
install_syslogng
config_syslogng
install_logrhythm
install_deepsecurity
configure_hostname
#install_ntp
#config_ntp

echo "Removing temporary files"                  
auto_install_cleanup

echo -e "\n\n----"
echo -e "\033[1;32mDNS Server initial configuration is successful.\033[0m"
echo -e "Server's primary IP address: \033[1m$SRV_IP\033[0m"
echo -e "Server's Hostname: \033[1m$server_name\033[0m"
echo "Please reboot your server to complete this procedure."
echo -e "\nWaiting 60 seconds until automatic reboot. \033[1;33mPress CTRL+C to cancel\033[0m."
sleep 60


reboot