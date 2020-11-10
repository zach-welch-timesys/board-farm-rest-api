#!/bin/bash
###################################################################################################################
# Author:    Ankit Gupta                                                                                          #
# Email:     ankit.gupta@timesys.com                                                                              #
# Date:      2020-09-30                                                                                           #
# Usage:                                                                                                          #
# ebf [OPTIONS]                                                                                                   #
# #################################################################################################################

AUTH_TOKEN=""
OPTION=""
OPTION2=""
SERVER_URL=""
DEVICE_LIST=()
MY_DEVICE_LIST=()
USER_NAME=""
GPIO_PIN_DATA=""


function check_dependencies() {
	packageList="jq curl sshpass"

	for packageName in $packageList; do
      dpkg -s "$packageName" &>> /dev/null
	    if [ $? -ne 0 ];then
        echo "[ERROR] Package $packageName not found. Please install it"
        exit 1
      fi
	done
}

function help() {
  echo " "
  echo "Usage: ebf [OPTIONS] COMMAND"
  echo " "
  echo "Command line tool to access Timesys EBF"
  echo ""
  echo "Options:"
  echo "   login            For login into EBF Server, required only first time"
  echo "   list             To list devices, mydevices and stored configuration"
  echo "   mydevices        Provide the list of devices assigned to current User"
  echo "   <device name>    To see the information and perform operation on a device"
  echo "   help             Provide help guide"
  echo ""
  echo "Commands:"
  echo "   config           Provide the details of User configured and EBF Server"
  echo "   devices          Provide the list of all the active devices in EBF server"
  echo "   status           Provide the device assignee details and status of device power state"
  echo "   allocate         Allocate a device to a User"
  echo "   release          Release a device assigned to current User"
  echo "   force            Release a device assigned to other user"
  echo "   info             Provide details of a device"
  echo "   power            Current status of power or run on/off/reboot/user-defined power command"
  echo "   hotplug          Current state of a hotplug or on/off/switch the state of a hotplug"
  echo "   portfw           Forward a device port to a Zombie port using NAT/SSH"
  echo "   add              Add a IP forward rule"
  echo "   remove           Remove a IP forward rule"
  echo "   serial           Executea command or Download/Upload a file over serial connection"
  echo "   run              Run a command on a device and Display it's OUTPUT"
  echo "   download         Download a file to a local system"
  echo "   upload           Upload a local file to a device"
	echo "   labcontrollers   List all the lab controllers assigned to a device"
  echo ""
  echo "Run 'ebf [Options] help' for more information on a option."
  echo " "
  exit
}

function help_login() {
  echo " "
  echo "Usage: ebf login"
  echo " "
  echo "Command line tool to access Timesys EBF"
  echo ""
  echo "Options:"
  echo "   login            For login into EBF Server, required only first time"
  echo "                    Store the user credentials and EBF server details,"
  echo "                    so you don't need to login again and again."
  echo " "
  exit
}

function help_list() {
  echo " "
  echo "Usage: ebf list [COMMAND]"
  echo " "
  echo "Command line tool to access Timesys EBF"
  echo ""
  echo "Commands:"
  echo "   config           Provide the details of User configured and EBF Server"
  echo "   devices          Provide the list of all the active devices in EBF server"
  echo ""
  echo " "
  exit
}

function help_device() {
  echo " "
  echo "Usage: ebf <device name> [COMMAND]"
  echo " "
  echo "Command line tool to access Timesys EBF"
  echo ""
  echo "Options:"
  echo "   <device name>    To see the information and perform operation on a device"
  echo "   help             Provide help guide"
  echo ""
  echo "Commands:"
  echo "   status           Provide the device assignee details and status of device power state"
  echo "   allocate         Allocate a device to a User"
  echo "   release          Release a device assigned to current User"
  echo "   force            Release a device assigned to other user"
  echo "   info             Provide details of a device"
  echo "   power            Current status of power or run on/off/reboot/user-defined power command"
  echo "   hotplug          Current state of a hotplug or on/off/switch the state of a hotplug"
  echo "   portfw           Forward a device port to a Zombie port using NAT/SSH"
  echo "   add              Add a IP forward rule"
  echo "   remove           Remove a IP forward rule"
  echo "   serial           Executea command or Download/Upload a file over serial connection"
	echo "   ssh              Executea command or Download/Upload a file over ssh connection"
  echo "   run              Run a command on a device and Display it's OUTPUT"
  echo "   download         Download a file to a local system"
  echo "   upload           Upload a local file to a device"
	echo "   labcontrollers   List all the lab controllers assigned to a device"
  echo ""
  echo "Run 'ebf  <device name> [COMMAND] help' for more information on a command."
  echo " "
  exit
}

function help_device_status() {
  echo " "
  echo "Usage: ebf <device name> status"
  echo " "
  echo "Provide the details of device assignee, whether it is assigned"
  echo "to a User or free for allocation."
  echo " "
  exit
}

function help_device_allocate() {
  echo " "
  echo "Usage: ebf <device name> allocate"
  echo " "
  echo "It will allocate the device to the current User"
  echo " "
  exit
}

function help_device_release() {
  echo " "
  echo "Usage: ebf <device name> release [force]"
  echo " "
  echo "It will release the device assigned to the current user"
  echo ""
  echo "Commands:"
  echo "   force            Release a device assigned to other user"
  exit
}

function help_device_release_force() {
  echo " "
  echo "Usage: ebf <device name> release force"
  echo " "
  echo "It will release the device assigned to other user"
  echo ""
  exit
}

function help_device_info() {
  echo " "
  echo "Usage: ebf <device name> info"
  echo " "
  echo "Provides information of a Device like Zombie's, Power port, Power commands,"
  echo "TFTP,NFS dir etc."
  echo ""
  exit
}

function help_device_power() {
  echo " "
  echo "Usage: ebf <device name> power [status/on/off/reboot/user-defined-command]"
  echo " "
  echo "Commands:"
  echo "   status                  Provides the current power status of a device"
  echo "   on                      Power on the device"
  echo "   off                     Power Off the device"
  echo "   reboot                  Power reboot the device"
  echo "   user-defined-command    any other supported user-defined command"
  echo ""
  exit
}

function help_device_hotplug() {
  echo " "
  echo "Usage: ebf <device name> hotplug [1-4] [status/on/off/switch]"
  echo " "
  echo ""
  echo "Commands:"
  echo "   status                  Provides the current Hotplug status whether it is"
  echo "                           connected to devise side or not"
  echo "   on                      Connect hotplug to Device side"
  echo "   off                     Disconnect hotplug from Device"
  echo "   switch                  Toggle the current state of a particular hotplug"
  echo ""
  exit
}

function help_device_portfw() {
  echo " "
  echo "Usage: ebf <device name> portfw [list/add/remove] [NAT/SSH]"
  echo " "
  echo ""
  echo "Commands:"
  echo "   list                  Provides list of all the IP rules forwarded on a Zombie"
  echo "   add  [NAT/SSH]        Add a new NAT/SSH rule"
  echo "   remove  [NAT/SSH]     Remove a NAT/SSH rule"
  echo ""
  exit
}

function help_device_portfw_add_nat() {
  echo " "
  echo "Usage: ebf <device name> portfw add nat <device-ip> <dut-port> <zombie-port> <protocol>"
  echo " "
  exit
}

function help_device_portfw_add_ssh() {
  echo " "
  echo "Usage: ebf <device name> portfw add ssh <device-ip> <username> <password> <dut-port> <zombie-port>"
  echo " "
  exit
}

function help_device_portfw_remove_nat() {
  echo " "
  echo "Usage: ebf <device name> portfw remove nat <device-ip> <dut-port> <zombie-port> <protocol>"
  echo " "
  exit
}

function help_device_portfw_remove_ssh() {
  echo " "
  echo "Usage: ebf <device name> portfw remove ssh <zombie-port>"
  echo " "
  exit
}

function help_device_serial() {
  echo " "
  echo "Usage: ebf <device name> serial [run/download/upload]"
  echo " "
  echo ""
  echo "Commands:"
  echo "   run              Run a command on a device and Display it's OUTPUT using serial console"
  echo "   download         Download a file to a local system from device using serial console"
  echo "   upload           Upload a local file to a device using serial console"
  echo ""
  exit
}

function help_device_ssh() {
  echo " "
  echo "Usage: ebf <device name> ssh [run/download/upload]"
  echo " "
  echo ""
  echo "Commands:"
  echo "   run              Run a command on a device and Display it's OUTPUT using ssh"
  echo "   download         Download a file to a local system from device using ssh"
  echo "   upload           Upload a local file to a device using ssh"
  echo ""
  exit
}

function help_device_ssh_upload() {
  echo " "
  echo "Usage: ebf <device name> ssh upload <src-file-path> <dst-file-path> <permissions[optional]>"
  echo " "
  echo "e.g. ebf bbb01 ssh upload /home/admin/hello.txt /home/user/hello1.txt"
	echo " or"
  echo "e.g. ebf bbb01 ssh upload /home/admin/hello.txt /home/user/hello1.txt 777"
  exit
}

function help_device_ssh_download() {
  echo " "
  echo "Usage: ebf <device name> ssh download <src-file-path> <dst-file-path> "
  echo " "
  echo "e.g. ebf bbb01 ssh download /home/admin/hello.txt ./hello1.txt"
	exit
}


function help_device_gpio() {
  echo " "
  echo "Usage: ebf <device name> gpio [COMMANDS] [GPIO PIN PATTERN] [GPIO_PIN_DATA/OPTIONAL]"
  echo " "
  echo ""
  echo "Commands             GPIO Pin Pattern       GPIO Pin Data"
  echo "  set_mode_mask          1-255                  0-255"
  echo "  get_mode_mask          1-255                           "
  echo "  write_mask             1-255                  0-255    "
  echo "  read_mask              1-255                           "
  echo "  set_mode               1-8                    {read,write}"
  echo "  get_mode               1-8                                "
  echo "  read                   1-8                                "
  echo "  write                  1-8                    0-1         "
}

function execute_api() {
  METHOD=$1
  SERVER_URL="$2/api/v0.2/token/"
  USER_NAME=$3
  PASSWORD=$4
  COMMAND=$(curl -k --location --request "$METHOD" "$SERVER_URL"  --header 'Content-Type: application/json' --data-raw '{"username":"'"$USER_NAME"'" , "password":"'"$PASSWORD"'"}')
  echo "$COMMAND"
}

function user_authentication() {
  LOGIN=0
  check_dependencies
  if [ "$OPTION" == "login" ];then
    if [ -f ~/.ebfconfig ];then
      USER_NAME=$(cat ~/.ebfconfig |grep "username"|cut -d ":" -f2)
      SERVER_URL=$(cat ~/.ebfconfig |grep "server"|cut -d ":" -f2-)
      if [ $USER_NAME ];then
        echo "Already configured for user $USER_NAME and EBF Server $SERVER_URL"
        read -r -p "Do you want to Login with a different User? [y/N] " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
        then
          LOGIN=1
        fi
      fi
    else
      LOGIN=1
    fi
  fi

  if [ $LOGIN -eq 1 ];then
    if [ $SERVER_URL ];then
      read -r -p "Do you want to Change EBF Server $SERVER_URL? [y/N] " response
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]];then
        read -r -p "Provide the EBF Server URL >> " SERVER_URL
        read -r -p "Provide the EBF UserName >> " USER_NAME
        read -s -p "Provide the EBF User Password >> " PASSWORD
				echo ""
      else
        read -r -p "Provide the EBF UserName >> " USER_NAME
        read -s -p "Provide the EBF User Password >> " PASSWORD
				echo ""
      fi
    else
      read -r -p "Provide the EBF Server URL >> " SERVER_URL
      read -r -p "Provide the EBF UserName >> " USER_NAME
      read -s -p "Provide the EBF User Password >> " PASSWORD
			echo ""
    fi
    if [[ "${USER_NAME}" != "" && "${PASSWORD}" != "" && "{$SERVER_URL}" != "" ]];then
      OUTPUT=$(curl -s -k --location --request POST "$SERVER_URL/api/v0.2/token/"  --header 'Content-Type: application/json' --data-raw '{"username":"'"$USER_NAME"'" , "password":"'"$PASSWORD"'"}')
      AUTH_TOKEN=$(echo $OUTPUT|jq -r .data.token)
			RESULT=$(echo $OUTPUT|jq -r .result)
			if [ "$RESULT" == "success" ];then
    		if [ "$AUTH_TOKEN" != "null" ];then
        	echo "token:$AUTH_TOKEN" > ~/.ebfconfig
        	echo "username:$USER_NAME" >> ~/.ebfconfig
        	echo "server:$SERVER_URL" >> ~/.ebfconfig
        	echo "Successfully logged in for user $USER_NAME"
      	else
        	echo "[ERROR] Invalid server URL or credentials"
        	exit 1
      	fi
			else
				MESSAGE=$(echo $OUTPUT|jq -r .message)
				echo "[ERROR]: $MESSAGE"
				exit 1
			fi
    else
      echo "[ERROR] Invalid server URL or credentials"
      exit 1
    fi
  else
    USER_NAME=$(cat ~/.ebfconfig 2> /dev/null |grep "username"|cut -d ":" -f2)
    AUTH_TOKEN=$(cat ~/.ebfconfig 2> /dev/null |grep "token"|cut -d ":" -f2)
    SERVER_URL=$(cat ~/.ebfconfig 2> /dev/null |grep "server"|cut -d ":" -f2-)
		if [[ "${USER_NAME}" == "" || "${AUTH_TOKEN}" == "" || "{$SERVER_URL}" == "" ]];then
			echo "[Error] Invalid credentials, Please login again"
			exit 1
		fi
  fi
}

function list_config(){
    user_authentication
    echo " UserName:       $USER_NAME"
    echo " BFC-SERVER:     $SERVER_URL"
    echo " BFC AUTH-Token: $AUTH_TOKEN"
}

function list_devices() {
  user_authentication
  COUNT=0
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/"  --header 'Authorization: token '$AUTH_TOKEN'')
	RESULT=$(echo $OUTPUT|jq -r .result)
	device=$(echo $OUTPUT|jq -r .data[$COUNT])
	if [ "$RESULT" == "success" ];then
		while [ "$device" != "null" ];
		do
     COUNT=`expr $COUNT + 1`
		 echo "$COUNT $device"
		 device=$(echo $OUTPUT|jq -r .data[$COUNT])
    done
	fi
}

function mydevices() {
  user_authentication
  COUNT=0
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/mine/"  --header 'Authorization: token '$AUTH_TOKEN'')
	RESULT=$(echo $OUTPUT|jq -r .result)
	device=$(echo $OUTPUT|jq -r .data[$COUNT])
	if [ "$RESULT" == "success" ];then
		while [ "$device" != "null" ];
		do
     COUNT=`expr $COUNT + 1`
		 echo "$COUNT $device"
		 device=$(echo $OUTPUT|jq -r .data[$COUNT])
    done
	fi
}

function device_status() {
  user_authentication
  DEVICE=$OPTION
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE"  --header 'Authorization: token '$AUTH_TOKEN'')
	RESULT=$(echo $OUTPUT|jq -r .result)
	MESSAGE=$(echo $OUTPUT|jq -r .message)
  ASSIGNED_INFO=$(echo $OUTPUT|jq -r .data.AssignedTo)
	if [ "$RESULT" == "success" ];then
  	if [ "$ASSIGNED_INFO" == "" ];then
    	echo "Device $DEVICE is free"
  	else
    	echo "Device $DEVICE is assigned to user $ASSIGNED_INFO"
  	fi
	else
		FAILURE_MSG=$(echo $MESSAGE|grep -ow "No Device matches")
		if [ "$FAILURE_MSG" ];then
			echo "[ERROR] Device $DEVICE doesn't exsist"
		else
			echo $MESSAGE
		fi
		exit 1
	fi
}

function device_allocate() {
  user_authentication
  DEVICE=$OPTION
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/assign"  --header 'Authorization: token '$AUTH_TOKEN'')
  RESULT=$(echo $OUTPUT|jq -r .result)
  if [ "$RESULT" == "success" ];then
    echo "Device is assigned to user $USER_NAME"
  else
		MESSAGE=$(echo $OUTPUT|jq -r .message)
    echo "$MESSAGE"
    exit 1
  fi
}

function device_release() {
  user_authentication
  DEVICE=$OPTION
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/release"  --header 'Authorization: token '$AUTH_TOKEN'')
  RESULT=$(echo $OUTPUT|jq -r .result)
  if [ "$RESULT" == "success" ];then
    echo "Device is Released"
  else
		MESSAGE=$(echo $OUTPUT|jq -r .message)
    echo "$MESSAGE"
    exit 1
  fi
}

function device_release_force() {
  user_authentication
  DEVICE=$OPTION
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/release/force"  --header 'Authorization: token '$AUTH_TOKEN'')
  RESULT=$(echo $OUTPUT|jq -r .result)
  if [ "$RESULT" == "success" ];then
    echo "Device is Released"
  else
		MESSAGE=$(echo $OUTPUT|jq -r .message)
    echo "$MESSAGE"
    exit 1
  fi
}

function device_info() {
  user_authentication
  DEVICE=$OPTION
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE"  --header 'Authorization: token '$AUTH_TOKEN'')
  HOSTNAME=$(echo $OUTPUT|jq -r .data.Hostname)
	RESULT=$(echo $OUTPUT|jq -r .result)
	if [ "$RESULT" == "success" ];then
    if [ "$HOSTNAME" != "" ];then
      DEVICE_PORT=$(echo $OUTPUT|jq -r .data.lab.Zombie.DevicePort)
      IOCX_STATUS=$(echo $OUTPUT|jq -r .data.lab.IOCXConnected)
      ZOMBIE_NAME=$(echo $OUTPUT|jq -r .data.lab.Zombie.Hostname)
      ZOMBIE_IP=$(echo $OUTPUT|jq -r .data.lab.Zombie.IPAddress)
      ZOMBIE_URL=$(echo $OUTPUT|jq -r .data.lab.Zombie.URL)
      POWER_SWITCH_NAME=$(echo $OUTPUT|jq -r .data.lab.Power.PowerSwitch)
      POWER_SWITCH_PORT=$(echo $OUTPUT|jq -r .data.lab.Power.PowerSwitchPort)
      POWER_SWITCH_COMMANDS=( $(echo $OUTPUT|jq -r '.data.PowerCommands[]') )
      NETWORK_TFTP_DIR=$(echo $OUTPUT|jq -r '.data.lab.NetworkBoot."TFTP Boot Directory"')
      NETWORK_NFS_DIR=$(echo $OUTPUT|jq -r '.data.lab.NetworkBoot."NFS Root Directory"')
      echo " "
      echo "            ************************  "
      echo "            *  Device Information  *  "
      echo "            ************************  "
      echo " "
      echo " Hostname:                 $HOSTNAME"
      echo " Device Port:              $DEVICE_PORT"
      echo " IOCX Status:              $IOCX_STATUS"
      echo " Zombie Name:              $ZOMBIE_NAME"
      echo " Zombie IP:                $ZOMBIE_IP"
      echo " ZOMBIE_URL:               $ZOMBIE_URL"
      echo " Powe Switch:              $POWER_SWITCH_NAME"
      echo " Power Switch Port:        $POWER_SWITCH_PORT"
      echo " Power Switch Commands:    ${POWER_SWITCH_COMMANDS[@]}"
      echo " TFTP DIR:                 $NETWORK_TFTP_DIR"
      echo " NFS DIR:                  $NETWORK_NFS_DIR"
      echo " "
    else
      echo "[ERROR] NO information found for Device $DEVICE"
      exit 1
    fi
	else
		MESSAGE=$(echo $OUTPUT|jq -r .message)
		FAILURE_MSG=$(echo $MESSAGE|grep -ow "No Device matches")
		if [ "$FAILURE_MSG" ];then
			echo "[ERROR] Device $DEVICE doesn't exsist"
		else
			echo $MESSAGE
		fi
		exit 1
  fi
}

function power_status() {
  user_authentication
  DEVICE=$OPTION
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/power"  --header 'Authorization: token '$AUTH_TOKEN'')
  RESULT=$(echo $OUTPUT|jq -r .result)
  STATUS=$(echo $OUTPUT|jq -r .data)
  if [ "$RESULT" == "success" ];then
		if [ "$STATUS" == "" ];then
    	echo "[ERROR] Couldn't access power STATUS for device $DEVICE"
    	exit 1
  	fi
		STATUS=$(echo $STATUS | tr 'a-z' 'A-Z')
    echo "Device $DEVICE is Powered $STATUS"
  else
		MESSAGE=$(echo $OUTPUT|jq -r .message)
		FAILURE_MSG=$(echo $MESSAGE|grep -ow "No Device matches")
		if [ "$FAILURE_MSG" ];then
			echo "[ERROR] Device $DEVICE doesn't exsist"
		else
			echo $MESSAGE
		fi
		exit 1
	fi
}

function power_command() {
  user_authentication
  DEVICE=$OPTION
	POWER_COMMAND="$OPTION3"
  OUTPUT=$(curl -s -k --location --request PUT "$SERVER_URL/api/v0.2/devices/$DEVICE/power/$POWER_COMMAND"  --header 'Authorization: token '$AUTH_TOKEN'')
  RESULT=$(echo $OUTPUT|jq -r .result)
  if [ "$RESULT" == "success" ];then
    echo "Device $DEVICE is Powered $POWER_COMMAND"
  else
		MESSAGE=$(echo $OUTPUT|jq -r .message)
		FAILURE_MSG=$(echo $MESSAGE|grep -ow "No Device matches")
		if [ "$FAILURE_MSG" ];then
			echo "[ERROR] Device $DEVICE doesn't exsist"
			exit 1
		fi
		if [ "$MESSAGE" ];then
    	echo "[ERROR] $MESSAGE"
		else
			echo "[ERROR] Couldn't access Power status for device $DEVICE"
		fi
    exit 1
  fi
}

function sdmux_hotplug() {
  user_authentication
  DEVICE=$OPTION
	HOTPLUG_PORT=$OPTION3
	COMMAND=$OPTION4
  if [ "$COMMAND" == "status" ];then
    OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/hotplug/$HOTPLUG_PORT/"  --header 'Authorization: token '$AUTH_TOKEN'')
	else
    OUTPUT=$(curl -s -k --location --request PUT "$SERVER_URL/api/v0.2/devices/$DEVICE/hotplug/$HOTPLUG_PORT/$COMMAND/"  --header 'Authorization: token '$AUTH_TOKEN'')
  fi
    RESULT=$(echo $OUTPUT|jq -r .result)
    STATUS=$(echo $OUTPUT|jq -r .data)
    if [ "$RESULT" == "success" ] && [ "$STATUS" != "null" ];then
      if [ "$COMMAND" == "status" ];then
        echo "Device $DEVICE Hotplug port $HOTPLUG_PORT is currently $STATUS"
      else
        echo "Device $DEVICE Hotplug port $HOTPLUG_PORT is switched $STATUS"
      fi
    else
			MESSAGE=$(echo $OUTPUT|jq -r .message)
			FAILURE_MSG=$(echo $MESSAGE|grep -ow "No Device matches")
			if [ "$FAILURE_MSG" ];then
				echo "[ERROR] Device $DEVICE doesn't exsist"
				exit 1
			fi
			if [ "$COMMAND" == "status" ];then
				echo "[ERROR] Couldn't fetch the status of Hotplug Port $HOTPLUG_PORT"
			else
      	echo "[ERROR] Couldn't switch Hotplug port to $COMMAND"
			fi
      exit 1
    fi
}

function portfw_list() {
  user_authentication
  DEVICE=$OPTION
	PORTFW_TYPE=$OPTION4
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/portfw/$PORTFW_TYPE/"  --header 'Authorization: token '$AUTH_TOKEN'')
	COUNT=0
	RESULT=$(echo $OUTPUT|jq -r .result)
  PORT_LIST=$(echo $OUTPUT|jq -r .data[$COUNT])
	if [ "$RESULT" == "success" ] && [ "$PORT_LIST" != "null" ];then
  	while [ "$PORT_LIST" != "null" ];
  	do
			COUNT=`expr $COUNT + 1`
    	echo "Rule $COUNT"
    	echo " Device IP: $(echo $PORT_LIST|jq -r .dip)"
    	echo " Zombie Protocol: $(echo $PORT_LIST|jq -r .prot)"
    	echo " Port Forward Type: $(echo $PORT_LIST|jq -r .type)"
    	echo " Zombie Port: $(echo $PORT_LIST|jq -r .zport)  -->  Device Port: $(echo $PORT_LIST|jq -r .dport)"
    	echo " "
    	PORT_LIST=$(echo $OUTPUT|jq -r .data[$COUNT])
  	done
	elif [ "$RESULT" == "success" ] && [ "$PORT_LIST" == "null" ];then
		echo "No IP Forward rule found for device $DEVICE"
	else
		MESSAGE=$(echo $OUTPUT|jq -r .message)
		FAILURE_MSG=$(echo $MESSAGE|grep -ow "No Device matches")
		if [ "$FAILURE_MSG" ];then
			echo "[ERROR] Device $DEVICE doesn't exsist"
		else
			echo $MESSAGE
		fi
		exit 1
	fi
}

function portfw_add() {
  user_authentication
  DEVICE=$OPTION
	PORTFW_TYPE=$OPTION4
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE"  --header 'Authorization: token '$AUTH_TOKEN'')
  ZOMBIE_NAME=$(echo $OUTPUT|jq -r .data.lab.Zombie.Hostname)
  if [ "$PORTFW_TYPE" == "NAT" ];then
		DEVICE_IP=$OPTION5
		DUT_PORT=$OPTION6
		ZOMBIE_PORT=$OPTION7
		PROTOCOL=$OPTION8
		if [ "$OPTION9" == "" ] && [ "$PROTOCOL" != "" ];then
    	OUTPUT=$(curl -s -k --location --request POST "$SERVER_URL/api/v0.2/zombies/$ZOMBIE_NAME/portforward/nat/"  --header 'Content-Type: application/json' --header 'Authorization: token '$AUTH_TOKEN'' --data-raw '{ "device_ip":"'"$DEVICE_IP"'", "dut_port":"'"$DUT_PORT"'", "zombie_port":"'"$ZOMBIE_PORT"'", "pcol":"'"$PROTOCOL"'" }')
    	RESULT=$(echo $OUTPUT|jq -r .result)
		else
			help_device_portfw_add_nat
			exit 1
		fi
	else
		DEVICE_IP=$OPTION5
		USERNAME=$OPTION6
		PASSWORD=$OPTION7
		DUT_PORT=$OPTION8
		ZOMBIE_PORT=$OPTION9
		if [ "$OPTION10" == "" ] && [ "$ZOMBIE_PORT" != "" ];then
    	OUTPUT=$(curl -s -k --location --request POST "$SERVER_URL/api/v0.2/devices/$DEVICE/portfw/ssh/"  --header 'Content-Type: application/json' --header 'Authorization: token '$AUTH_TOKEN'' --data-raw '{ "dut_ip":"'"$DEVICE_IP"'", "username":"'"$USERNAME"'", "dut_pw":"'"$PASSWORD"'", "dut_port":"'"$DUT_PORT"'", "zombie_port":"'"$ZOMBIE_PORT"'" }')
    	RESULT=$(echo $OUTPUT|jq -r .result)
		else
			help_device_portfw_add_ssh
			exit 1
		fi
  fi
  if [ "$RESULT" == "success" ];then
    echo "Successfully Forwarded the port"
  else
		MESSAGE=$(echo $OUTPUT|jq -r .message)
		FAILURE_MSG=$(echo $MESSAGE|grep -ow "No Device matches")
		if [ "$FAILURE_MSG" ];then
			echo "[ERROR] Device $DEVICE doesn't exsist"
		else
    	echo "[ERROR]: Couldn't forward port"
			echo $MESSAGE
			exit 1
		fi
  fi
}

function portfw_remove() {
  user_authentication
  DEVICE=$OPTION
  COUNT=0
	PORTFW_TYPE=$OPTION4
	if [ "$PORTFW_TYPE" == "nat" ];then
		DEVICE_IP=$OPTION5
		DUT_PORT=$OPTION6
		ZOMBIE_PORT=$OPTION7
		PROTOCOL=$OPTION8
		if [ "$OPTION9" == "" ] && [ "$PROTOCOL" != "" ];then
    	OUTPUT=$(curl -s -k --location --request DELETE "$SERVER_URL/api/v0.2/devices/$DEVICE/portfw/$PORTFW_TYPE/"  --header 'Content-Type: application/json' --header 'Authorization: token '$AUTH_TOKEN'' --data-raw '{ "device_ip":"'"$DEVICE_IP"'", "dut_port":"'"$DUT_PORT"'", "zombie_port":"'"$ZOMBIE_PORT"'", "pcol":"'"$PROTOCOL"'" }')
    	RESULT=$(echo $OUTPUT|jq -r .result)
		else
			help_device_portfw_remove_nat
			exit 1
		fi
	else
		ZOMBIE_PORT=$OPTION5
		if [ "$OPTION6" == "" ] && [ "$ZOMBIE_PORT" != "" ];then
    	OUTPUT=$(curl -s -k --location --request DELETE "$SERVER_URL/api/v0.2/devices/$DEVICE/portfw/$PORTFW_TYPE/?ports=$ZOMBIE_PORT"  --header 'Content-Type: application/json' --header 'Authorization: token '$AUTH_TOKEN'' )
    	RESULT=$(echo $OUTPUT|jq -r .result)
		else
			help_device_portfw_remove_ssh
			exit 1
		fi
  fi
	if [ "$RESULT" == "success" ];then
		echo " Successfully Deleted the port forwarded rule"
	else
		MESSAGE=$(echo $OUTPUT|jq -r .message)
		FAILURE_MSG=$(echo $MESSAGE|grep -ow "No Device matches")
		if [ "$FAILURE_MSG" ];then
			echo "[ERROR] Device $DEVICE doesn't exsist"
		else
    	echo "[ERROR]: No port forward rule found"
			echo $MESSAGE
			exit 1
		fi
	fi
}

function execute_serial_command() {
  user_authentication
  DEVICE=$OPTION
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/mine/"  --header 'Authorization: token '$AUTH_TOKEN'')
  MY_DEVICE_LIST=( $(echo $OUTPUT|jq -r '.[].hostname') )
  if [[ "${MY_DEVICE_LIST[@]}" =~ "${DEVICE}" ]]; then
    read -r -p "Enter the command you want to execute on $DEVICE >> " DEVICE_COMMAND
    if [ "$DEVICE_COMMAND" != "" ];then

      OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/run/serial/"  --header 'Content-Type: application/json' --header 'Authorization: token '$AUTH_TOKEN'' --data-raw '{ "command":"'"$DEVICE_COMMAND"'" }')
      echo $OUTPUT|jq -r .data[0]
    else
      echo "Command shouldn't be empty"
      exit 1
    fi
  else
    echo "[ERROR] Device $DEVICE is not assigned to you"
    exit 1
  fi
}

function execute_ssh_command() {
  user_authentication
  DEVICE=$OPTION
  DEVICE_COMMAND=$OPTION4
  if [ "$DEVICE_COMMAND" != "" ];then
		DEVICE_COMMAND=$(jq -aRs . <<< $DEVICE_COMMAND)
		DEVICE_COMMAND=${DEVICE_COMMAND#\"}
		DEVICE_COMMAND=${DEVICE_COMMAND%\"}
		OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/run/ssh/"  --header 'Content-Type: application/json' --header 'Authorization: token '$AUTH_TOKEN'' --data-raw '{ "command": "'"$DEVICE_COMMAND"'" }')
		RESULT=$(echo $OUTPUT|jq -r .result)
		RETURN_CODE=$(echo $OUTPUT|jq -r .data.return_code)
    if [ "$RESULT" == "success" ];then
      COUNT=0
      DATA=$(echo $OUTPUT|jq -r .data.data[$COUNT])
      while [ "$DATA" != "null" ];
      do
				COUNT=`expr $COUNT + 1`
				echo $DATA
				DATA=$(echo $OUTPUT|jq -r .data.data[$COUNT])
			done
			return $RETURN_CODE
	 else
		 MESSAGE=$(echo $OUTPUT|jq -r .message)
 		 FAILURE_MSG=$(echo $MESSAGE|grep -ow "No Device matches")
 		 if [ "$FAILURE_MSG" ];then
 		 	echo "[ERROR] Device $DEVICE doesn't exsist"
 		 else
 		 	echo $MESSAGE
 			exit 1
 		 fi
	 fi
	else
		echo "echo Command shouldn't be empty"
		exit 1
	 fi
}

function serial_download() {
  user_authentication
  DEVICE=$OPTION
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/mine/"  --header 'Authorization: token '$AUTH_TOKEN'')
  MY_DEVICE_LIST=( $(echo $OUTPUT|jq -r '.[].hostname') )
  if [[ "${MY_DEVICE_LIST[@]}" =~ "${DEVICE}" ]]; then
    read -r -p "Enter the file PATH you want to download from $DEVICE >> " FILE_PATH
    if [ "$FILE_PATH" != "" ];then
      FILE_PATH=${FILE_PATH%/}
      OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/download/serial/$FILE_PATH/" --header 'Authorization: token '$AUTH_TOKEN'' --output ${FILE_PATH##*/})
      echo $OUTPUT
    else
      echo "FILE_PATH shouldn't be empty"
      exit 1
    fi
  else
    echo "[ERROR] Device $DEVICE is not assigned to you"
    exit 1
  fi
}

function serial_upload() {
  user_authentication
  DEVICE=$OPTION
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/mine/"  --header 'Authorization: token '$AUTH_TOKEN'')
  MY_DEVICE_LIST=( $(echo $OUTPUT|jq -r '.[].hostname') )
  if [[ "${MY_DEVICE_LIST[@]}" =~ "${DEVICE}" ]]; then
    read -r -p "Enter the file PATH you want to upload to $DEVICE >> " FILE_PATH
    if [ "$FILE_PATH" != "" ] && [ -f $FILE_PATH ];then
      OUTPUT=$(curl -s -k --location --request POST "$SERVER_URL/api/v0.2/devices/$DEVICE/upload/serial/" --header 'Authorization: token '$AUTH_TOKEN'' --form 'file=@'$FILE_PATH'' )
      RESULT=$(echo $OUTPUT|jq -r .result)
      if [ "$RESULT" == "success" ];then
        echo "Successfully Uploaded the File"
      else
        echo "[ERROR]: Couldn't Upload the File"
        exit 1
      fi
    else
      echo "FILE_PATH shouldn't be empty"
      exit 1
    fi
  else
    echo "[ERROR] Device $DEVICE is not assigned to you"
    exit 1
  fi
}

function ssh_download() {
	user_authentication
  DEVICE=$OPTION
  SRC_FILE_PATH=${OPTION4%/}
	FILE_NAME=${SRC_FILE_PATH##*/}
	DST_FILE_PATH=${OPTION5%/}
	if [ ! -d "$DST_FILE_PATH" ];then
		PARENT_DST_FILE_PATH=${DST_FILE_PATH%/*}
		if [ ! -d "$PARENT_DST_FILE_PATH" ];then
		 echo "[ERROR] Destination download path is not Valid!"
		 exit 1
		fi
	else
		DST_FILE_PATH="$DST_FILE_PATH/$FILE_NAME"
	fi
  if [ "$SRC_FILE_PATH" != "" ];then
    OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/downld/ssh?path=$SRC_FILE_PATH" --header 'Authorization: token '$AUTH_TOKEN'' --output ${DST_FILE_PATH})
		if [ $? -eq 0 ];then
			echo "Successfully Downloaded file $DST_FILE_PATH"
		else
			echo "[ERROR] Couldn't download file"
			help_device_ssh_download
			exit 1
		fi
  else
		help_device_ssh_download
    echo "FILE_PATH shouldn't be empty"
    exit 1
  fi
}

function ssh_upload() {
  user_authentication
  DEVICE=$OPTION
	SRC_FILE_PATH=$OPTION4
	DST_FILE_PATH=${OPTION5}
	FILE_PERMISSIONS=${OPTION6}
  if [ "$SRC_FILE_PATH" != "" ] && [ -f $SRC_FILE_PATH ];then
		if [ "$FILE_PERMISSIONS" != "" ];then
			OUTPUT=$(curl -s -k --location --request POST "$SERVER_URL/api/v0.2/devices/$DEVICE/upload/ssh/" --header 'Authorization: token '$AUTH_TOKEN'' --form 'file=@'$SRC_FILE_PATH'' --form 'path='$DST_FILE_PATH'' --form 'permission='$FILE_PERMISSIONS'' )
		else
    	OUTPUT=$(curl -s -k --location --request POST "$SERVER_URL/api/v0.2/devices/$DEVICE/upload/ssh/" --header 'Authorization: token '$AUTH_TOKEN'' --form 'file=@'$SRC_FILE_PATH'' --form 'path='$DST_FILE_PATH'' )
		fi
    RESULT=$(echo $OUTPUT|jq -r .result)
		MESSAGE=$(echo $OUTPUT|jq -r .message)
		if [ "$RESULT" == "success" ];then
      echo ""
      echo "Successfully File $MESSAGE"
    else
      echo ""
      echo "[ERROR]: $MESSAGE"
      exit 1
    fi
	else
		help_device_ssh_upload
    echo "[ERROR]: Please provide a valid File Path"
    exit 1
  fi
}

function device_gpio() {
  COMMAND=$OPTION3
  GPIO_PATTERN=$OPTION4
  GPIO_DATA=$OPTION5
  if [ "$COMMAND" == "set_mode" ] || [ "$COMMAND" == "write" ] || [ "$COMMAND" == "read" ] || [ "$COMMAND" == "get_mode" ];then
    if [[ "$GPIO_PATTERN" =~ ^[0-9]+$ ]] && [ "$GPIO_PATTERN" -ge 1 ] && [ "$GPIO_PATTERN" -le 8 ]; then
      echo ""
    else
      echo "[ERROR]: Invalid GPIO Pattern"
      help_device_gpio
      exit 1
    fi
  else
    if [[ "$GPIO_PATTERN" =~ ^[0-9]+$ ]] && [ "$GPIO_PATTERN" -ge 1 ] && [ "$GPIO_PATTERN" -le 255 ]; then
      echo " "
    else
      echo "[ERROR]: Invalid GPIO Pattern"
      help_device_gpio
      exit 1
    fi
  fi

  if [ "$GPIO_PIN_DATA" == "yes" ];then
    if [ "$COMMAND" == "set_mode" ];then
      if [ "$GPIO_DATA" == "read" ] || [ "$GPIO_DATA" == "write" ];then
        echo " "
      else
        echo "[ERROR]: Invalid GPIO data"
        help_device_gpio
        exit 1
      fi
    elif [ "$COMMAND" == "write" ];then
      if [[ "$GPIO_DATA" =~ ^[0-9]+$ ]] && [ "$GPIO_DATA" -ge 0 ] && [ "$GPIO_DATA" -le 1 ]; then
        echo " "
      else
        echo "[ERROR]: Invalid GPIO DATA"
        help_device_gpio
        exit 1
      fi
    else
      if [[ "$GPIO_DATA" =~ ^[0-9]+$ ]] && [ "$GPIO_DATA" -ge 0 ] && [ "$GPIO_DATA" -le 255 ]; then
        echo " "
      else
        echo "[ERROR]: Invalid GPIO DATA"
        help_device_gpio
        exit 1
      fi
    fi
  fi
  user_authentication
  DEVICE=$OPTION
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/gpio/$COMMAND/$GPIO_PATTERN/$GPIO_DATA"  --header 'Authorization: token '$AUTH_TOKEN'')
	RESULT=$(echo $OUTPUT|jq -r .result)
	STATUS=$(echo $OUTPUT|jq -r .status)
  if [ "$RESULT" == "success" ];then
    echo " $STATUS"
	else
		MESSAGE=$(echo $OUTPUT|jq -r .message)
		FAILURE_MSG=$(echo $MESSAGE|grep -ow "No Device matches")
		if [ "$FAILURE_MSG" ];then
			echo "[ERROR] Device $DEVICE doesn't exsist"
		else
			echo $MESSAGE
			echo "[ERROR]: Couldn't execute GPIO command"
		fi
    exit 1
  fi
}

function device_console() {
  user_authentication
  DEVICE=$OPTION
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/console/serial/isactive/"  --header 'Authorization: token '$AUTH_TOKEN'')
	ISACTIVE=$(echo $OUTPUT|jq -r .data.isActive)
  if [ "$ISACTIVE" == "true" ];then
    OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE"  --header 'Authorization: token '$AUTH_TOKEN'')
    DEVICE_PORT=$(echo $OUTPUT|jq -r .data.lab.Zombie.DevicePort)
    ZOMBIE_IP=$(echo $OUTPUT|jq -r .data.lab.Zombie.IPAddress)
    if [ "$ZOMBIE_IP" != "" ] && [ "$DEVICE_PORT" != "" ];then
      sshpass -p "zuser" ssh -t zuser@$ZOMBIE_IP "connect_serial DUT$DEVICE_PORT"
    else
      echo "[ERROR] Couldn't access console for device $DEVICE"
      exit 1
    fi
  else
    OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/console/serial/restart/"  --header 'Authorization: token '$AUTH_TOKEN'')
    OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/console/serial/isactive/"  --header 'Authorization: token '$AUTH_TOKEN'')
    ISACTIVE=$(echo $OUTPUT|jq -r .data.isActive)
    if [ "$ISACTIVE" == "true" ];then
      OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE"  --header 'Authorization: token '$AUTH_TOKEN'')
      DEVICE_PORT=$(echo $OUTPUT|jq -r .data.lab.Zombie.DevicePort)
      ZOMBIE_IP=$(echo $OUTPUT|jq -r .data.lab.Zombie.IPAddress)
      if [ "$ZOMBIE_IP" != "" ] && [ "$DEVICE_PORT" != "" ];then
        sshpass -p "zuser" ssh -t zuser@$ZOMBIE_IP "connect_serial DUT$DEVICE_PORT"
      else
        echo "[ERROR] Couldn't access console for device $DEVICE"
        exit 1
      fi
    else
			MESSAGE=$(echo $OUTPUT|jq -r .message)
			FAILURE_MSG=$(echo $MESSAGE|grep -ow "No Device matches")
			if [ "$FAILURE_MSG" ];then
				echo "[ERROR] Device $DEVICE doesn't exsist"
			else
				echo $MESSAGE
				echo "[ERROR] Couldn't access console STATUS for device $DEVICE"
			fi
      exit 1
    fi
  fi
}

function list_labcontrollers() {
  user_authentication
  DEVICE=$OPTION
	COUNT=0
  OUTPUT=$(curl -s -k --location --request GET "$SERVER_URL/api/v0.2/devices/$DEVICE/labcontrollers/"  --header 'Authorization: token '$AUTH_TOKEN'')
  RESULT=$(echo $OUTPUT|jq -r .result)
	CONTROLLERS_LIST=$(echo $OUTPUT|jq -r .data[$COUNT])
  if [ "$RESULT" == "success" ] && [ $"CONTROLLERS_LIST" != "null" ];then
    while [ "$CONTROLLERS_LIST" != "null" ];
    do
      COUNT=`expr $COUNT + 1`
      echo "Controller : $COUNT"
      echo " ID              : $(echo $CONTROLLERS_LIST|jq -r .id)"
      echo " Controller Type : $(echo $CONTROLLERS_LIST|jq -r .type)"
      echo " "
      CONTROLLERS_LIST=$(echo $OUTPUT|jq -r .data[$COUNT])
    done
	elif [ "$RESULT" == "success" ] && [ $"CONTROLLERS_LIST" == "null" ]; then
		echo "No labcontroller found for device $DEVICE"
  else
		MESSAGE=$(echo $OUTPUT|jq -r .message)
		FAILURE_MSG=$(echo $MESSAGE|grep -ow "No Device matches")
		if [ "$FAILURE_MSG" ];then
			echo "[ERROR] Device $DEVICE doesn't exsist"
		else
			echo $MESSAGE
		fi
    exit 1
  fi
}

OPTION=$1
shift
OPTION2=$1
shift
OPTION3=$1
shift
OPTION4="$1"
shift
OPTION5=$1
shift
OPTION6=$1
shift
OPTION7=$1
shift
OPTION8=$1
shift
OPTION9=$1
shift
OPTION10=$1

case "$OPTION" in
  login)
    if [ "$OPTION2" == "" ];then
      user_authentication
    else
      help_login
    fi
    ;;
  mydevices)
    if [ "$OPTION2" == "" ];then
      mydevices
    else
      help
    fi
    ;;
  list)
    case "$OPTION2" in
      config)
        if [ "$OPTION3" == "" ];then
          list_config
        else
          help_list
        fi
        ;;
      devices)
        if [ "$OPTION3" == "" ];then
          list_devices
        else
          help_list
        fi
        ;;
      *)
        help_list
        ;;
    esac
    ;;
  *)
    case "$OPTION2" in
      status)
        if [ "$OPTION3" == "" ];then
          device_status
        else
          help_device_status
        fi
        ;;
      allocate)
        if [ "$OPTION3" == "" ];then
          device_allocate
        else
          help_device_allocate
        fi
        ;;
      release)
        case "$OPTION3" in
          force)
            if [ "$OPTION4" == "" ];then
              device_release_force
            else
              help_device_release_force
            fi
            ;;
          *)
            if [ "$OPTION3" == "" ];then
              device_release
            else
              help_device_release
            fi
            ;;
        esac
        ;;
      info)
        if [ "$OPTION3" == "" ];then
          device_info
        else
          help_device_info
        fi
        ;;
      power)
        case "$OPTION3" in
          status)
            if [ "$OPTION4" == "" ];then
              power_status
            else
              help_device_power
            fi
            ;;
          *)
            if [ "$OPTION3" != "" ];then
              if [ "$OPTION4" == "" ];then
                power_command $OPTION3
              else
                help_device_power
              fi
            else
              help_device_power
            fi
            ;;
        esac
        ;;
      hotplug)
        OPTION_LIST="on off switch status"
        if [[ "$OPTION3" =~ ^[0-9]+$ ]] && [ "$OPTION3" -ge 1 ] && [ "$OPTION3" -le 4 ]; then
          if [[ $OPTION_LIST =~ (^|[[:space:]])"$OPTION4"($|[[:space:]]) ]] ; then
            sdmux_hotplug $OPTION3 $OPTION4
          else
            echo "[ERROR]: Not a valid option $OPTION4"
            help_device_hotplug
            exit 1
          fi
        else
          echo "Not Valid Hotplug Number: $OPTION3"
          help_device_hotplug
          exit 1
        fi
        ;;
      portfw)
        case "$OPTION3" in
          list)
            OPTION4=$(echo $OPTION4 | tr 'A-Z' 'a-z')
            if [ "$OPTION4" == "nat" ] || [ "$OPTION4" == "ssh" ];then
              if [ "$OPTION5" == "" ];then
                portfw_list
              else
                help_device_portfw
              fi
            else
              help_device_portfw
            fi
            ;;
          add)
            OPTION4=$(echo $OPTION4 | tr 'a-z' 'A-Z')
            if [ "$OPTION4" == "NAT" ] || [ "$OPTION4" == "SSH" ];then
              portfw_add
            else
              help_device_portfw
            fi
            ;;
          remove)
            OPTION4=$(echo $OPTION4 | tr 'A-Z' 'a-z')
            if [ "$OPTION4" == "nat" ] || [ "$OPTION4" == "ssh" ];then
              portfw_remove
						else
              help_device_portfw
            fi
            ;;
          *)
            help_device_portfw
            ;;
        esac
        ;;
      serial)
        case "$OPTION3" in
          run)
            if [ "$OPTION4" == "" ];then
							echo "Feature not implemented"
              #execute_serial_command
            else
              help_device_serial
            fi
            ;;
          download)
            if [ "$OPTION4" == "" ];then
              #serial_download
							echo "Feature not implemented"
            else
              help_device_serial
            fi
            ;;
          upload)
            if [ "$OPTION4" == "" ];then
              #serial_upload
							echo "Feature not implemented"
            else
              help_device_serial
            fi
            ;;
          *)
            help_device_serial
            ;;
        esac
        ;;
			ssh)
				case "$OPTION3" in
					run)
						if [ "$OPTION5" == "" ];then
							execute_ssh_command
						else
							help_device_ssh
						fi
						;;
					download)
						if [ "$OPTION6" == "" ];then
							ssh_download
						else
							help_device_ssh
						fi
						;;
					upload)
						if [ "$OPTION7" == "" ];then
							ssh_upload
						else
							help_device_ssh
						fi
						;;
					*)
						help_device_serial
						;;
				esac
				;;
      console)
        if [ "$OPTION3" == "" ];then
          device_console
        else
          help_device_status
        fi
        ;;
      gpio)
        case "$OPTION3" in
          read_mask)
            if [ "$OPTION4" == "" ];then
              help_device_gpio
            else
              if [ "$OPTION5" == "" ];then
                device_gpio
              else
                help_device_gpio
              fi
            fi
            ;;
          get_mode)
            if [ "$OPTION4" == "" ];then
              help_device_gpio
            else
              if [ "$OPTION5" == "" ];then
                device_gpio
              else
                help_device_gpio
              fi
            fi
            ;;
          get_mode_mask)
            if [ "$OPTION4" == "" ];then
              help_device_gpio
            else
              if [ "$OPTION5" == "" ];then
                device_gpio
              else
                help_device_gpio
              fi
            fi
            ;;
          read)
            if [ "$OPTION4" == "" ];then
              help_device_gpio
            else
              if [ "$OPTION5" == "" ];then
                device_gpio
              else
                help_device_gpio
              fi
            fi
            ;;
          set_mode_mask)
            if [ "$OPTION4" == "" ] || [ "$OPTION5" == "" ];then
              help_device_gpio
            else
              if [ "$OPTION6" == "" ];then
                GPIO_PIN_DATA="yes"
                device_gpio
              else
                help_device_gpio
              fi
            fi
            ;;
          write_mask)
            if [ "$OPTION4" == "" ] || [ "$OPTION5" == "" ];then
              help_device_gpio
            else
              if [ "$OPTION6" == "" ];then
                GPIO_PIN_DATA="yes"
                device_gpio
              else
                help_device_gpio
              fi
            fi
            ;;
          set_mode)
            if [ "$OPTION4" == "" ] || [ "$OPTION5" == "" ];then
              help_device_gpio
            else
              if [ "$OPTION6" == "" ];then
                GPIO_PIN_DATA="yes"
                device_gpio
              else
                help_device_gpio
              fi
            fi
            ;;
          write)
            if [ "$OPTION4" == "" ] || [ "$OPTION5" == "" ];then
              help_device_gpio
            else
              if [ "$OPTION6" == "" ];then
                GPIO_PIN_DATA="yes"
                device_gpio
              else
                help_device_gpio
              fi
            fi
            ;;
          *)
            help_device_gpio
            ;;
        esac
        ;;
      list)
        case "$OPTION3" in
          labcontrollers)
            if [ "$OPTION4" == "" ];then
              list_labcontrollers
            else
              help
            fi
            ;;
          *)
            help
            ;;
          esac
          ;;
      *)
        help
        ;;
    esac
    ;;
esac
