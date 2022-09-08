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

############ Variable Definitions  ################
#path='/tmp'
#path_package='/tmp/packages_install'
#dst_package="$dst_dir/install-package"

install_archive_url="http://10.0.0.133/installer/packages_install"
DNS_INSTALL_DIR="/root/dns-deploy"
server_name=""
package_password=""

dst_dir="$DNS_INSTALL_DIR"
dst_package="$dst_dir/install-package"
install_script="scripts/dns-bootstrap.sh"

export DNS_INSTALL_DIR

# Installation LOG file
STEP_LOG="/root/dns-deploy.log"
echo -n > $STEP_LOG

server_name=""
package_password=""

# Check if this script has root credentials
if [ $(id -u) -ne "0" ]; then  echo "This script should be executed by root. Aborting."; exit 1; fi


############ Functions Definition ################

# Set the repo config to connect the Repos Server
function set_repo {
    cd $path
    curl -O http://10.0.0.133/installer/repos/remote.repo; rm -rf /etc/yum.repos.d/*;cp -f *.repo /etc/yum.repos.d/ >/dev/null
    check
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
  which curl > /dev/null
  conf_step $? "Detecting URL fetch program"

  # OpenSSL
  which openssl > /dev/null
  if [ $? -ne 0 ]; then
    yum -y install openssl
    conf_step $? "Installing OpenSSL package."
  fi
  which openssl > /dev/null
  conf_step $? "Detecting OpenSSL"

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

  tar -C $dst_dir -xzf $src_file 2>&1 ;  exitstatus=$(($exitstatus+$?))
  if [ ! -x "$dst_dir/$install_script" ]; then
    exitstatus=$(($exitstatus+1))
  fi
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
    tar -zxvf bind-9.11.*.tar.gz
    conf_step $? "Extracting package BIND9"
}

function add_bind9_user {
    useradd -s /sbin/nologin -d /var/named -c "named" named > /dev/null
    conf_step $? "Adding user and group for BIND9"

}

function compli_bind9 {
    cd $dst_package/bind9/bind-9.11.*
    ./configure --without-python    > /dev/null
    make all                        >/dev/null 
    make install                    > /dev/null
    chown -R named:named $bind9_dir
    chown -R named:named $bind9_run
    chown -R named:named $bind9_logs
    conf_step $? "Compiling BIND9"
   
}
function add_named_service {
    cp $dst_package/bind9/named.service.conf /etc/systemd/system/named.service > /dev/null
    conf_step $? "Adding named to Systemd"

}

function bind9_status {
    bind9_version=`named -v > /dev/null`
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
    `rpm -qa gcc`                                                   > /dev/null
        if [ $? -ne 0 ]; then
            yum -y install gcc                                      > /dev/null
            conf_step $? "Installing GCC package."
        else
            conf_step $? "Detecting GCC"
        fi
    `rpm -qa glibc`                                                 > /dev/null
        if [ $? -ne 0 ]; then
            yum -y install glibc glibc-common                       > /dev/null
            conf_step $? "Installing glibc package."
        else
            conf_step $? "Detecting glibc"
        fi
    `rpm -qa make`                                                  > /dev/null
        if [ $? -ne 0 ]; then
            yum -y install make                                     > /dev/null
            conf_step $? "Installing make package."
        else
            conf_step $? "Detecting glibc"
        fi
    `rpm -qa net-snmp`                                              > /dev/null
        if [ $? -ne 0 ]; then
            yum -y install net-snmp                                 > /dev/null
            conf_step $? "Installing net-snmp package."
        else
            conf_step $? "Detecting net-snmp"
        fi
    `rpm -qa bison`                                                 > /dev/null
        if [ $? -ne 0 ]; then
            yum -y install bison                                    > /dev/null
            conf_step $? "Installing bison package."
        else
            conf_step $? "Detecting bison"
        fi
    `rpm -qa ncurses`                                               > /dev/null
        if [ $? -ne 0 ]; then
            yum -y install ncurses-devel                            > /dev/null
            conf_step $? "Installing ncurses package."
        else
            conf_step $? "Detecting ncurses"
        fi
    `rpm -qa readline`                                              > /dev/null
        if [ $? -ne 0 ]; then
            yum -y install readline-devel                           > /dev/null
            conf_step $? "Installing readline package."
        else
            conf_step $? "Detecting readline"
        fi
    `rpm -qa binutils`                                              > /dev/null
        if [ $? -ne 0 ]; then
            yum -y install binutils                                 > /dev/null
            conf_step $? "Installing binutils package."
        else
            conf_step $? "Detecting binutils"
        fi
    `rpm -qa flex`                                                  > /dev/null
            if [ $? -ne 0 ]; then
            yum -y install flex                                     > /dev/null
            conf_step $? "Installing flex package."
        else
            conf_step $? "Detecting flex"
        fi
    `rpm -qa m4`                                                    > /dev/null
        if [ $? -ne 0 ]; then
            yum -y install m4                                       > /dev/null
            conf_step $? "Installing m4 package."
        else
            conf_step $? "Detecting m4"
        fi
    `rpm -qa libssh*`                                               > /dev/null
            if [ $? -ne 0 ]; then
            yum -y install libssh*                                  > /dev/null
            conf_step $? "Installing libssh package."
        else
            conf_step $? "Detecting libssh"
        fi
}

function extract_bird {
    cd $dst_package/bird
    tar -zxvf bird-*.tar.gz                                         > /dev/null
    conf_step $? "Extracting package BIRD"
}

function compli_bird {
    cd $dst_package/bird/bird-*
    ./configure                                                     > /dev/null
    make                                                            > /dev/null
    make install                                                    > /dev/null
    /usr/local/sbin/bird
    conf_step $? "Compiling package BIRD"
}

function bird_status {
    /usr/local/sbin/bird
    bird_version=`/usr/local/sbin/birdc show status | grep 'BIRD' | awk {'print $2'} | head -1 > /dev/null`
    conf_step $? "BIRD version $bird_version has been installed"

}

########################################Other Packages##################################################

function install_aide  {
    `rpm -qa aide`                                                  > /dev/null
        if [ $? -ne 0 ]; then
            yum -y install aide                                     > /dev/null
            conf_step $? "Installing aide package."
        else
            conf_step $? "Detecting aide"
        fi    
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
    rpm -ivh eventlog-0.2.13-4.el7.x86_64.rpm >/dev/null            > /dev/null
    rpm -ivh libnet-1.1.6-7.el7.x86_64.rpm >/dev/null               > /dev/null
    rpm -ivh ivykis-0.36.2-2.el7.x86_64.rpm >/dev/null              > /dev/null
    rpm -ivh syslog-ng-3.5.6-3.el7.x86_64.rpm >/dev/null            > /dev/null
    conf_step $? "Installing SYSLOG-NG"

}
function config_syslogng {
    cd $dst_package/syslog-ng_rh7
    cp -f syslog-ng.conf /etc/syslog-ng/
#    systemctl restart syslog-ng >/dev/null
#    systemctl enable syslog-ng >/dev/null
    conf_step $? "Configuration SYSLOG-NG"
}

function install_logrhythm {
    cd $dst_package/logrhythm
    rpm -ivh scsm-7.6.0.8004-1.el7.x86_64.rpm                       > /dev/null
    cp -f scsm_linux.txt /opt/logrhythm/scsm/
    systemctl restart scsm                                          >/dev/null               
    systemctl enable scsm                                           >/dev/null
    conf_step $? "Installing Logrhythm Agent"

}
function install_deepsecurity {
    cd $dst_package/deepsecurity
    rpm -ivh Agent-PGPCore-RedHat_EL7-20.0.0-2009.x86_64.rpm        > /dev/null
    conf_step $? "Installing Deep Security"

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


# Perform actions
download_install_package $install_archive_url $dst_package.aes
decrypt_package "$package_password" $dst_package.aes $dst_package.tar.gz
unpack_package $dst_package.tar.gz

set_repo
depend_packages
create_bind9_dir
extract_bind9
add_bind9_user
compli_bind9
bind9_status

extract_bird
compli_bird
bird_status

install_aide
config_aide
config_snmpd
install_syslogng
config_syslogng
install_logrhythm
install_deepsecurity

echo "Removing temporary files"                  
auto_install_cleanup

echo -e "\n\n----"
echo -e "\033[1;32mDNS Server initial configuration is successful.\033[0m"
echo -e "Server's primary IP address: \033[1m$SRV_IP\033[0m"
echo "Please reboot your server to complete this procedure."
echo -e "\nWaiting 60 seconds until automatic reboot. \033[1;33mPress CTRL+C to cancel\033[0m."
sleep 60


reboot