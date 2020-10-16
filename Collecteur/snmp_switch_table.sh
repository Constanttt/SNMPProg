#!/bin/bash
#
# Authors : Valentin Ginard
#
# The script is build to parse equipments MIB in order to collect them and bring them in Splunk
# To run this script you need to :
#               Indicate the list of equipments to parse
#               Indicate where store the CSV
#               Indicate the output location
#               Check the SNMP Community
#
##################################################################################################

#Storage of all CSV file
loc="/mnt/share_infra/FileBuffer/snmp/"
#loc="/tmp/snmptemp/csv/switch/"

#SNMP Community
snmpcom="snmpcom"

#Set invalid VLAN
invalidvlans="100[2-5]"

#Equipments List
equipmentlist="/home/shared/lists/ip_switchs.list"
#equipmentlist="/home/a638597/snmp/lists/ip_switch.list"

#Set Workspace
TmpDir="/tmp/snmp_switch_table/"
#TmpDir="/tmp/snmptemp/switch/"

#Set error equipment file
ErrEquip=${loc}snmp_switch_errors.err

#Set error file for emptyCSV to analyse
SnmpEmpty=${loc}snmp_switch_empty.err

#Mail to Send Error files
mailaddress="valentin.ginard@rolex.com"

# Set email sender
senderaddress="noreply@rolex.com (Automated script on SV00567)"

#If the folder of all CSV file doesn't exist create it
if [ ! -d ${TmpDir} ]; then
        mkdir -p $TmpDir
fi

#Clear the workplace
rm ${TmpDir}/tmp.* > /dev/null 2>&1

#Check is the error file if exist
if [ -f $ErrEquip ]
then
        #Clear the error equipment file
        rm ${ErrEquip}
fi

#Check is the empty file if exist
if [ -f $SnmpEmpty ]
then
        #Clear the empty equipment file
        rm ${SnmpEmpty}
fi

function ifTable
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; timeout=$3

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get the show interface
        snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Cf , ifTable > ${TmpDir}${name}_ifTable_temp.csv; returncode=$?
    else
        #snmptable to get the show interface
        snmptable -r 2 -t $timeout -v 2c -m +ALL -c $snmpcom $node -Cb -Cf , ifTable > ${TmpDir}${name}_ifTable_temp.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
       return 1
    else
        #Delete the three first lines
        tail -n +3 ${TmpDir}${name}_ifTable_temp.csv > ${loc}${name}_ifTable.csv
        #Open the CSV file and replace Index by IfIndex for Splunk
        sed -i 's/Index/IfIndex/g' ${loc}${name}_ifTable.csv
        #Remove the temporary file
        rm ${TmpDir}${name}_ifTable_temp.csv
    fi
}

function ipAddrTable
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; timeout=$3

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get IP address table
        snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Cf , ipAddrTable > ${TmpDir}${name}_ipAddrTable_temp.csv; returncode=$?
    else
        #snmptable to get IP address table
        snmptable -r 2 -t $timeout -v 2c -m +ALL -c $snmpcom $node -Cb -Cf , ipAddrTable > ${TmpDir}${name}_ipAddrTable_temp.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
       return 1
    else
        #Delete the three first lines
        tail -n +3 ${TmpDir}${name}_ipAddrTable_temp.csv > ${loc}${name}_ipAddrTable.csv
        #Remove the temporary file
        rm ${TmpDir}${name}_ipAddrTable_temp.csv
    fi
}

function vmVlan
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; timeout=$3
    #We don't use the snmp table so we have to inject the header manually
    printf "IfIndex = IfIndexVTP\r\n" > ${TmpDir}${name}_vmVlan_temp.csv
    printf "IfIndex = IfIndexVTP\r\n" > ${loc}${name}_vmVlan.csv
    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get Vlan Table
        snmpwalk -v 2c -m +ALL -c $snmpcom $node vmVlan -OQ -Os >> ${TmpDir}${name}_vmVlan_temp.csv; returncode=$?
    else
        #snmptable to get Vlan Table
        snmpwalk -r 2 -t $timeout -v 2c -m +ALL -c $snmpcom $node vmVlan -OQ -Os >> ${TmpDir}${name}_vmVlan_temp.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
       return 1
    else
        #Cut in all . and keep the 2nd part
        cut -d . -f 2 ${TmpDir}${name}_vmVlan_temp.csv > ${loc}${name}_vmVlan.csv
        #Open the CSV file and replace " = " by "," for Splunk
        sed -i 's/ = /,/g'  ${loc}${name}_vmVlan.csv
    fi
    #Remove the temporary file
    rm ${TmpDir}${name}_vmVlan_temp.csv
}

function vtpVlanTable
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; timeout=$3

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get VTP
        snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Ci -Cf , vtpVlanTable > ${TmpDir}${name}_vtpVlanTable_temp.csv; returncode=$?
    else
        #snmptable to get VTP
        snmptable -r 2 -t $timeout -v 2c -m +ALL -c $snmpcom $node -Cb -Ci -Cf , vtpVlanTable > ${TmpDir}${name}_vtpVlanTable_temp.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
       return 1
    else
        #Cut in all . and keep the 2nd part | Delete the 3 first lines
        cut -d . -f 2 ${TmpDir}${name}_vtpVlanTable_temp.csv | tail -n +3 > ${loc}${name}_vtpVlanTable.csv
        #Open the CSV file and replace the header index by IfIndexVTP for Splunk
        sed -i 's/index/IfIndexVTP/g' ${loc}${name}_vtpVlanTable.csv
        #Remove the temporary file
        rm ${TmpDir}${name}_vtpVlanTable_temp.csv
    fi
}

function lldpRemSysName
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; timeout=$3

    #For this session I create a temporary file for cut it
    #We don't use the snmp table so we have to inject the header manually
    printf "IfIndex,lldp\r\n" >  ${loc}${name}_lldpRemSysName.csv
    printf "IfIndex,lldp\r\n" >  ${TmpDir}${name}_lldpRemSysName_tempo.csv

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get lldp neighbors
        snmpwalk -v 2c -m +ALL -c $snmpcom $node  lldpRemSysName -OQ -Os >> ${TmpDir}${name}_lldpRemSysName_tempo.csv; returncode=$?
    else
        #snmptable to get lldp neighbors
        snmpwalk -r 2 -t $timeout -v 2c -m +ALL -c $snmpcom $node  lldpRemSysName -OQ -Os >> ${TmpDir}${name}_lldpRemSysName_tempo.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
        return 1
    else
        #Cut in all . and keep the end
        cut -d . -f 3,4 ${TmpDir}${name}_lldpRemSysName_tempo.csv > ${TmpDir}${name}_lldpRemSysName_temp.csv
        #Open the CSV file and replace all "." and all " = " by a ","
        sed -i -e 's/\./,/g' -e 's/ = /,/g' ${TmpDir}${name}_lldpRemSysName_temp.csv
        #Cut the file in order to keep the first and last part and inject it into the final CSV
        cut -d, -f 1,3 ${TmpDir}${name}_lldpRemSysName_temp.csv > ${loc}${name}_lldpRemSysName.csv
        #The last cut delete the ",value in the fist line so we put it back
        sed -i -e 's/Port/Port,lldp/g' ${loc}${name}_lldpRemSysName.csv
        #Delete the temporary file
        rm ${TmpDir}${name}_lldpRemSysName_temp.csv
    fi
    #Delete the temporary file
    rm ${TmpDir}${name}_lldpRemSysName_tempo.csv
}

function ifAlias
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; timeout=$3

    #We don't use the snmp table so we have to inject the header manually
    printf "IfIndex = Alias\r\n" > ${TmpDir}${name}_ifAlias_temp.csv
    printf "IfIndex = Alias\r\n" > ${loc}${name}_ifAlias.csv

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get Vlan Table
        snmpwalk -v 2c -m +ALL -c $snmpcom $node  ifAlias -OQ -Os >> ${TmpDir}${name}_ifAlias_temp.csv; returncode=$?
    else
        #snmptable to get Vlan Table
        snmpwalk -r 2 -t $timeout -v 2c -m +ALL -c $snmpcom $node  ifAlias -OQ -Os >> ${TmpDir}${name}_ifAlias_temp.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
        return 1
    else
        #Cut in all . and keep the 2nd part
        cut -d . -f 2 ${TmpDir}${name}_ifAlias_temp.csv > ${loc}${name}_ifAlias.csv
        #Open the CSV file and replace all " = " by "," for Splunk
        sed -i 's/ = /,/g' ${loc}${name}_ifAlias.csv
    fi
    #Delete the temporary file
    rm ${TmpDir}${name}_ifAlias_temp.csv
}

function cafPortConfigTable
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; timeout=$3

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get the dot1x status of the port
        snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Ci -Cf , cafPortConfigTable > ${TmpDir}${name}_cafPortConfigTable_temp.csv; returncode=$?
    else
        #snmptable to get the dot1x status of the port
        snmptable -r 2 -t $timeout -v 2c -m +ALL -c $snmpcom $node -Cb -Ci -Cf , cafPortConfigTable > ${TmpDir}${name}_cafPortConfigTable_temp.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
        return 1
    else
        #Delete the three first lines
        tail -n +3 ${TmpDir}${name}_cafPortConfigTable_temp.csv > ${loc}${name}_cafPortConfigTable.csv
        #Open the CSV file and replace the header index by IfIndex for Splunk
        sed -i 's/index/IfIndex/g' ${loc}${name}_cafPortConfigTable.csv
        #Remove the temporary file
        rm ${TmpDir}${name}_cafPortConfigTable_temp.csv
    fi
}

function cafSessionTable
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; timeout=$3

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmp to get session
        snmptable -v 2c -m +ALL -c $snmpcom $node -Ox -Cb -Ci -Cf , cafSessionTable > ${TmpDir}${name}_cafSessionTable_temp.csv; returncode=$?
    else
        #snmp to get session
        snmptable -r 2 -t $timeout -v 2c -m +ALL -c $snmpcom $node -Ox -Cb -Ci -Cf , cafSessionTable > ${TmpDir}${name}_cafSessionTable_temp.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
        return 1
    else
        #Cut in all ' and keep the 1st part and the end | Delete the 3 first lines
        cut -d "'" -f 1,3 ${TmpDir}${name}_cafSessionTable_temp.csv| tail -n +3 > ${TmpDir}${name}_cafSessionTable_tempo.csv
        #Open the CSV file and replace all .', by , and index by IfIndex for Splunk
        sed -i -e "s/.',/,/g" -e 's/index/IfIndex/g' ${TmpDir}${name}_cafSessionTable_tempo.csv
        #Delete ClientAddress
        cut -d "," -f 1-3,5-21 ${TmpDir}${name}_cafSessionTable_tempo.csv > ${loc}${name}_cafSessionTable.csv
        #Remove the temporary file
        rm ${TmpDir}${name}_cafSessionTable_temp.csv
        rm ${TmpDir}${name}_cafSessionTable_tempo.csv
    fi
}

function dot1dBasePortTable
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; timeout=$3

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get generic information about every port
        snmptable -v 2c -m +ALL -c $snmpcom@1 $node -Cf , dot1dBasePortTable > /dev/null; returncode=$?
    else
        #snmptable to get generic information about every port
        snmptable -r 1 -t $timeout -v 2c -m +ALL -c $snmpcom@1 $node -Cf , dot1dBasePortTable > /dev/null; returncode=$?
    fi

    if [ $returncode -eq 0 ]; then
        #Check if we ask a timeout
    printf "Port,IfIndex,dot1dBasePortCircuit,dot1dBasePortDelayExceededDiscards,dot1dBasePortMtuExceededDiscards\r\n" > ${TmpDir}${name}_dot1dBasePortTable_temp.csv
        if [ -z $timeout ];then
            snmptable -v 2c -m +ALL -c $snmpcom@1 $node -CH -Cf , dot1dBasePortTable >> ${TmpDir}${name}_dot1dBasePortTable_temp.csv; return=$?
        else
            snmptable -r 1 -t $timeout -v 2c -m +ALL -c $snmpcom@1 $node -CH -Cf , dot1dBasePortTable >> ${TmpDir}${name}_dot1dBasePortTable_temp.csv; return=$?
        fi

        if [ $return -eq 0 ];then
            #snmptable to get VTP | cut in order to keep the vlan id | foreach id do :
            snmptable -r 1 -t 700 -v 2c -m +ALL -c $snmpcom $node -Ci -CH -Cf , vtpVlanTable | cut -d , -f 1 | cut -d . -f 2 | while read line;do
                #If the vlan id match an invalid vlan
                if [[ ! $line =~ $invalidvlans ]];then
                    #Check if we ask a timeout
                    if [ -z $timeout ];then
                        #snmptable to get generic information for the vlan | Delete the 3 first lines and inject the result at the end of the CSV
                        snmptable -v 2c -m +ALL -c $snmpcom@$line $node -CH -Cf , dot1dBasePortTable >> ${TmpDir}${name}_dot1dBasePortTable_temp.csv
                    else
                        #snmptable to get generic information for the vlan | Delete the 3 first lines and inject the result at the end of the CSV
                        snmptable -r 1 -t $timeout -v 2c -m +ALL -c $snmpcom@$line $node -CH -Cf , dot1dBasePortTable >> ${TmpDir}${name}_dot1dBasePortTable_temp.csv
                    fi
                fi
            done
            #Copie to the final CSV
            cat ${TmpDir}${name}_dot1dBasePortTable_temp.csv >> ${loc}${name}_dot1dBasePortTable.csv
            rm ${TmpDir}${name}_dot1dBasePortTable_temp.csv
        fi
    else
        return 1
    fi
}

function dot1dTpFdbTable
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; timeout=$3

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get @mac learned for the vlan 1
        snmptable -O0sUX -v 2c -m +ALL -c $snmpcom@1 $node -CH -Cf , dot1dTpFdbTable > /dev/null; returncode=$?
    else
        #snmptable to get @mac learned for the vlan 1
        snmptable -r 1 -t $timeout -O0sUX -v 2c -m +ALL -c $snmpcom@1 $node -CH -Cf , dot1dTpFdbTable > /dev/null; returncode=$?
    fi

    if [ $returncode -eq 0 ]
    then
    printf "Address,Port,Status\r\n" > ${TmpDir}${name}_dot1dTpFdbTable_temp.csv
     
    if [ -z $timeout ];then
            snmptable -v 2c -m +ALL -c $snmpcom@1 $node -CH -Cf , dot1dTpFdbTable >> ${TmpDir}${name}_dot1dTpFdbTable_temp.csv; return=$?
        else
            snmptable -r 1 -t $timeout -v 2c -m +ALL -c $snmpcom@1 $node -CH -Cf , dot1dTpFdbTable >> ${TmpDir}${name}_dot1dTpFdbTable_temp.csv; return=$?
        fi

        if [ $return -eq 0 ];then
       #snmptable to get VTP | cut in order to keep the vlan id | foreach id do :
            snmptable -r 1 -t 700 -v 2c -m +ALL -c $snmpcom $node -Ci -CH -Cf , vtpVlanTable | cut -d , -f 1 | cut -d . -f 2 | while read line; do
            #If the vlan id match an invalid vlan
            if [[ ! $line =~ $invalidvlans ]];then
                #Check if we ask a timeout
                if [ -z $timeout ];then
                    #snmptable to get mac address learned for the vlan | Delete the 3 first lines and inject the result at the end of the CSV
                    snmptable -O0sUX -v 2c -m +ALL -c $snmpcom@$line $node -CH -Cf , dot1dTpFdbTable >> ${TmpDir}${name}_dot1dTpFdbTable_temp.csv
                else
                    #snmptable to get mac address learned for the vlan | Delete the 3 first lines and inject the result at the end of the CSV
                    snmptable -r 1 -t $timeout -O0sUX -v 2c -m +ALL -c $snmpcom@$line $node -CH -Cf , dot1dTpFdbTable >> ${TmpDir}${name}_dot1dTpFdbTable_temp.csv
                fi
            fi
        done

           #Copie to the final CSV
           cat ${TmpDir}${name}_dot1dTpFdbTable_temp.csv >> ${loc}${name}_dot1dTpFdbTable.csv
           rm ${TmpDir}${name}_dot1dTpFdbTable_temp.csv
    fi
    else
        return 1
    fi
}

function vlanTrunkPortDynamicStatus 
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; timeout=$3
    #We don't use the snmp table so we have to inject the header manually
    printf "IfIndex = Trunk\r\n" > ${TmpDir}${name}_vlanTrunkPortDynamicStatus_temp.csv
    printf "IfIndex = Trunk\r\n" > ${loc}${name}_vlanTrunkPortDynamicStatus.csv
    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get Vlan Table
        snmpwalk -v 2c -m +ALL -c $snmpcom $node vlanTrunkPortDynamicStatus  -OQ -Os >> ${TmpDir}${name}_vlanTrunkPortDynamicStatus_temp.csv; returncode=$?
    else
        #snmptable to get Vlan Table
        snmpwalk -r 2 -t $timeout -v 2c -m +ALL -c $snmpcom $node vlanTrunkPortDynamicStatus  -OQ -Os >> ${TmpDir}${name}_vlanTrunkPortDynamicStatus_temp.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
       return 1
    else
        #Cut in all . and keep the 2nd part
        cut -d . -f 2 ${TmpDir}${name}_vlanTrunkPortDynamicStatus_temp.csv > ${loc}${name}_vlanTrunkPortDynamicStatus.csv
        #Open the CSV file and replace " = " by "," for Splunk
        sed -i 's/ = /,/g'  ${loc}${name}_vlanTrunkPortDynamicStatus.csv
    fi
    #Remove the temporary file
    rm ${TmpDir}${name}_vlanTrunkPortDynamicStatus_temp.csv
}


#Function GetSNMP to parse SNMP Values
function GetSNMP
{
    #Get the first argument
    node=$1

    #Get equipments name & Get returncode for snmp name equipment request
    name="$(snmpget -r 1 -t 20 -v 2c -m +ALL -Ov -Oq -c $snmpcom $node sysName.0)"
    
    if [ -z $name ];then
        #Get equipments name & Get returncode for snmp name equipment request
        name="$(snmpget -r 2 -t 60 -v 2c -m +ALL -Ov -Oq -c $snmpcom $node sysName.0)"
        if [ -z $name ];then
            name=$node
        fi
    fi

    #Get exit status of the last command - if no error during last command execution
    if [ $? -eq 0 ]
    then
        #Call ifTable function with the IP and the name
        ifTable $node $name
        #Call ipAddrTable function with the IP and the name
        ipAddrTable $node $name
        #Call vmVlan function with the IP and the name
        vmVlan $node $name
        #Call vtpVlanTable function with the IP and the name
        vtpVlanTable $node $name
        #Call lldpRemSysName function with the IP and the name
        lldpRemSysName $node $name
        #Call ifAlias function with the IP and the name
        ifAlias $node $name
        #Call cafPortConfigTable function with the IP and the name
        cafPortConfigTable  $node $name
        #Call cafSessionTable function with the IP and the name
        cafSessionTable $node $name
        #Call dot1dBasePortTable function with the IP and the name
        dot1dBasePortTable $node $name
        #Call dot1dTpFdbTable function with the IP and the name
        dot1dTpFdbTable $node $name
        #Call vlanTrunkPortDynamicStatus function with the IP and the name
        vlanTrunkPortDynamicStatus $node $name
    else
        printf "$node --> KO \r\n"
    fi
}

function EmptyCSV {

    #Get the first argument
    node=$1

    #Get equipments name & Get returncode for snmp name equipment request
    name="$(snmpget -r 1 -t 20 -v 2c -m +ALL -Ov -Oq -c $snmpcom $node sysName.0)"
 
    if [ -z $name ];then
        #Get equipments name & Get returncode for snmp name equipment request
        name="$(snmpget -r 2 -t 60 -v 2c -m +ALL -Ov -Oq -c $snmpcom $node sysName.0)"
        if [ -z $name ];then
            name=$node
        fi
    fi

    # Files to check
    fileifTable=${loc}${name}_ifTable.csv
    fileipAddrTable=${loc}${name}_ipAddrTable.csv
    filevmVlan=${loc}${name}_vmVlan.csv
    filevtpVlanTable=${loc}${name}_vtpVlanTable.csv
    filelldpRemSysName=${loc}${name}_lldpRemSysName.csv
    fileifAlias=${loc}${name}_ifAlias.csv
    filecafPortConfigTable=${loc}${name}_cafPortConfigTable.csv
    filecafSessionTable=${loc}${name}_cafSessionTable.csv
    filedot1dBasePortTable=${loc}${name}_dot1dBasePortTable.csv
    filedot1dTpFdbTable=${loc}${name}_dot1dTpFdbTable.csv
    filevlanTrunkPortDynamicStatus=${loc}${name}_vlanTrunkPortDynamicStatus.csv

    #Minimum size required
    minimumsize=3

    timeoutiftable=700

    if [ -f $fileifTable ];then
        #Calcul the size of all files
        ifTable=$( stat -c %s ${loc}${name}_ifTable.csv)
        #Chech the size for IfTable of the node to know if it empty
        if [ $minimumsize -ge $ifTable ]; then
            echo "IfTable is empty for "$name".Size : " $ifTable >> ${SnmpEmpty}
            rm $fileifTable
        fi
    else
        #Call SNMP function with timeout
        ifTable $node $name $timeoutiftable
        if [ -f $fileifTable ];then
            #Calcul the size of all files
            ifTable=$( stat -c %s ${loc}${name}_ifTable.csv)
            #Chech the size for IfTable of the node to know if it empty
            if [ $minimumsize -ge $ifTable ]; then
                echo "IfTable is empty for "$name".Size : " $ifTable >> ${SnmpEmpty}
                rm $fileifTable
            fi
        else
            echo "IfTable for "$name" doesn't exist" >> ${SnmpEmpty}
            return 1
        fi
    fi

    if [ -f $fileipAddrTable ];then
        #Calcul the size of all files
        ipAddrTable=$( stat -c %s ${loc}${name}_ipAddrTable.csv)
        #Chech the size for ipAddrTable of the node to know if it empty
        if [ $minimumsize -ge $ipAddrTable ]; then
            echo "ipAddrTable is empty for "$name".Size : " $ipAddrTable >> ${SnmpEmpty}
            rm $fileipAddrTable
        fi
    else
        #Call SNMP function with timeout
        ipAddrTable $node $name 700
        if [ -f $fileipAddrTable ];then
            #Calcul the size of all files
            ipAddrTable=$( stat -c %s ${loc}${name}_ipAddrTable.csv)
            #Chech the size for ipAddrTable of the node to know if it empty
            if [ $minimumsize -ge $ipAddrTable ]; then
              echo "ipAddrTable is empty for "$name".Size : " $ipAddrTable >> ${SnmpEmpty}
              rm $fileipAddrTable
            fi
        else
            echo "ipAddrTable for "$name" doesn't exist" >> ${SnmpEmpty}
            return 1
        fi
    fi

    if [ -f $filevmVlan ];then
        #Calcul the size of all files
        vmVlan=$( stat -c %s ${loc}${name}_vmVlan.csv)
        #Chech the size for vmVlan of the node to know if it empty
        if [ $minimumsize -ge $vmVlan ]; then
            echo "vmVlan is empty for "$name".Size : " $vmVlan >> ${SnmpEmpty}
            rm $filevmVlan
        fi
    else
        #Call SNMP function with timeout
        vmVlan $node $name 480
        if [ -f $filevmVlan ];then
            #Calcul the size of all files
            vmVlan=$( stat -c %s ${loc}${name}_vmVlan.csv)
            #Chech the size for vmVlan of the node to know if it empty
            if [ $minimumsize -ge $vmVlan ]; then
                echo "vmVlan is empty for "$name".Size : " $vmVlan >> ${SnmpEmpty}
                rm $filevmVlan
            fi
        else
            echo "vmVlan for "$name" doesn't exist" >> ${SnmpEmpty}
            return 1
        fi
    fi

    if [ -f $filevtpVlanTable ];then
        #Calcul the size of all files
        vtpVlanTable=$( stat -c %s ${loc}${name}_vtpVlanTable.csv)
        #Chech the size for vtpVlanTable of the node to know if it empty
        if [ $minimumsize -ge $vtpVlanTable ]; then
            echo "vtpVlanTable is empty for "$name".Size : " $vtpVlanTable >> ${SnmpEmpty}
            rm $filevtpVlanTable
        fi
    else
        #Call SNMP function with timeout
        vtpVlanTable $node $name 480
        if [ -f $filevtpVlanTable ];then
            #Calcul the size of all files
            vtpVlanTable=$( stat -c %s ${loc}${name}_vtpVlanTable.csv)
            #Chech the size for vtpVlanTable of the node to know if it empty
            if [ $minimumsize -ge $vtpVlanTable ]; then
                echo "vtpVlanTable is empty for "$name".Size : " $vtpVlanTable >> ${SnmpEmpty}
                rm $filevtpVlanTable
            fi
        else
            echo "vtpVlanTable for "$name" doesn't exist" >> ${SnmpEmpty}
            return 1
        fi
    fi

    if [ -f $filelldpRemSysName ];then
        #Calcul the size of all files
        lldpRemSysName=$( stat -c %s ${loc}${name}_lldpRemSysName.csv)
        #Chech the size for lldpRemSysnode of the node to know if it empty
        if [ $minimumsize -ge $lldpRemSysName ]; then
            #echo "lldpRemSysName is empty for "$name".Size : " $lldpRemSysName >> ${SnmpEmpty}
            rm $filelldpRemSysName
        fi
    else
        #Call SNMP function with timeout
        lldpRemSysName $node $name 480
        if [ -f $filelldpRemSysName ];then
            #Calcul the size of all files
            lldpRemSysName=$( stat -c %s ${loc}${name}_lldpRemSysName.csv)
            #Chech the size for lldpRemSysnode of the node to know if it empty
            if [ $minimumsize -ge $lldpRemSysName ]; then
                #echo "lldpRemSysName is empty for "$name".Size : " $lldpRemSysName >> ${SnmpEmpty}
                rm $filelldpRemSysName
            fi
        else
            echo "lldpRemSysName for "$name" doesn't exist" >> ${SnmpEmpty}
            return 1
        fi
    fi

    if [ -f $fileifAlias ];then
        #Calcul the size of all files
        ifAlias=$( stat -c %s ${loc}${name}_ifAlias.csv)
        #Chech the size for ifAlias of the node to know if it empty
        if [ $minimumsize -ge $ifAlias ]; then
            echo "ifAlias is empty for "$name".Size : " $ifAlias >> ${SnmpEmpty}
            rm $fileifAlias
        fi
    else
        #Call SNMP function with timeout
        ifAlias $node $name 480
        if [ -f $fileifAlias ];then
            #Calcul the size of all files
            ifAlias=$( stat -c %s ${loc}${name}_ifAlias.csv)
            #Chech the size for ifAlias of the node to know if it empty
            if [ $minimumsize -ge $ifAlias ]; then
                echo "ifAlias is empty for "$name".Size : " $ifAlias >> ${SnmpEmpty}
                rm $fileifAlias
            fi
        else
            echo "ifAlias for "$name" doesn't exist" >> ${SnmpEmpty}
            return 1
        fi
    fi

    if [ -f $filecafPortConfigTable ];then
        #Calcul the size of all files
        cafPortConfigTable=$( stat -c %s ${loc}${name}_cafPortConfigTable.csv)
        #Chech the size for cafPortConfigTable of the node to know if it empty
        if [ $minimumsize -ge $cafPortConfigTable ]; then
            echo "cafPortConfigTable is empty for "$name".Size : " $cafPortConfigTable >> ${SnmpEmpty}
            rm $filecafPortConfigTable
        fi
    else
        #Call SNMP function with timeou
        cafPortConfigTable $node $name 480
        if [ -f $filecafPortConfigTable ];then
            #Calcul the size of all files
            cafPortConfigTable=$( stat -c %s ${loc}${name}_cafPortConfigTable.csv)
            #Chech the size for cafPortConfigTable of the node to know if it empty
            if [ $minimumsize -ge $cafPortConfigTable ]; then
                echo "cafPortConfigTable is empty for "$name".Size : " $cafPortConfigTable >> ${SnmpEmpty}
                rm $filecafPortConfigTable
            fi
        else
            echo "cafPortConfigTable for "$name" doesn t exist" >> ${SnmpEmpty}
            return 1
        fi
    fi

    if [ -f $filecafSessionTable ];then
        #Calcul the size of all files
        cafSessionTable=$( stat -c %s ${loc}${name}_cafSessionTable.csv)
        #Chech the size for cafSessionTable of the node to know if it empty
        if [ $minimumsize -ge $cafSessionTable ]; then
            #echo "cafSessionTable is empty for "$name".Size : " $cafSessionTable >> ${SnmpEmpty}
            rm $filecafSessionTable
        fi
    else
        #Call SNMP function with timeout
        cafSessionTable $node $name 480
        if [ -f $filecafSessionTable ];then
            cafSessionTable=$( stat -c %s ${loc}${name}_cafSessionTable.csv)
            #Chech the size for cafSessionTable of the node to know if it empty
            if [ $minimumsize -ge $cafSessionTable ]; then
                #echo "cafSessionTable is empty for "$name".Size : " $cafSessionTable >> ${SnmpEmpty}
                rm $filecafSessionTable
            fi
        else
            echo "cafSessionTable for "$name" doesn't exist" >> ${SnmpEmpty}
            return 1
        fi
    fi
    
    if [ -f $filevlanTrunkPortDynamicStatus ];then
        #Calcul the size of all files
        vlanTrunkPortDynamicStatus=$( stat -c %s ${loc}${name}_vlanTrunkPortDynamicStatus.csv)
        #Chech the size for vlanTrunkPortDynamicStatus of the node to know if it empty
        if [ $minimumsize -ge $vlanTrunkPortDynamicStatus ]; then
            echo "vlanTrunkPortDynamicStatus is empty for "$name".Size : " $vlanTrunkPortDynamicStatus >> ${SnmpEmpty}
            rm $filevlanTrunkPortDynamicStatus
        fi
    else
        #Call SNMP function with timeout
        vlanTrunkPortDynamicStatus $node $name 480
        if [ -f $filevlanTrunkPortDynamicStatus ];then
            #Calcul the size of all files
            vlanTrunkPortDynamicStatus=$( stat -c %s ${loc}${name}_vlanTrunkPortDynamicStatus.csv)
            #Chech the size for vlanTrunkPortDynamicStatus of the node to know if it empty
            if [ $minimumsize -ge $vlanTrunkPortDynamicStatus ]; then
                echo "vlanTrunkPortDynamicStatus is empty for "$name".Size : " $vlanTrunkPortDynamicStatus >> ${SnmpEmpty}
                rm $filevlanTrunkPortDynamicStatus
            fi
        else
            echo "vlanTrunkPortDynamicStatus for "$name" doesn't exist" >> ${SnmpEmpty}
            return 1
        fi
    fi
}

#Define Variables
i=1
j=1

#Register start time
start=$(date +"%T")
StartDate=$(date -u -d "$start" +"%s")

#Foreach Node in the equipmentlist
for Node in $(cat $equipmentlist);do
    #Ping and snmp request
    ping $Node -c 1 -w 1 &> /dev/null && snmpget -r 1 -t 20 -v 2c -m +ALL -Ov -Oq -c $snmpcom $Node sysName.0 &> /dev/null
    #Check return code
    if [ $? -eq 0 ];then
        #Exec the function GetSNMP with as param the name of the equipment
        GetSNMP $Node &
        #Get the PID of the function
        Id[${i}]=$!
        #Store tehe PID
        equipment[${Id[${i}]}]=$Node
        #Run 10 process
        R=$((${i}%10))
        #If R is a "modulo" of 10
        if [[ $R = 0 ]];then
            # For x=j higher or equal of i incr x
            for ((x=${j}; x <= ${i}; x++));do
                # Wait the end of the function
                wait ${Id[${x}]}
                #Double check
                EmptyCSV ${equipment[${Id[${x}]}]} &
                if [ $? -ne 0 ];then
                    # get return and store it
                    echo "SNMP NOK for " ${equipment[${Id[${x}]}]} >> ${ErrEquip}
                    echo "SNMP NOK for " ${equipment[${Id[${x}]}]}
                else
                    # get return
                    echo "SNMP OK for " ${equipment[${Id[${x}]}]}
                fi
            done
            #incr j by i value +1
            let j=${i}+1
        fi
        let i=${i}+1
    else
        echo "Ping or SNMP no answered for " $Node >> ${ErrEquip}
        echo "Ping or SNMP no answered for " $Node
    fi
done

#if R is not a "modulo" of 10
if [ $R != 0 ];then
    for ((x=${j}; x < ${i}; x++));do
        # Wait the end of the function
        wait ${Id[${x}]}
        #double check
        EmptyCSV ${equipment[${Id[${x}]}]} &
        if [ $? -ne 0 ];then
            # get return and store it
            echo "SNMP NOK for " ${equipment[${Id[${x}]}]} >> ${ErrEquip}
            echo "SNMP NOK for " ${equipment[${Id[${x}]}]}
        else
            # get return
            echo "SNMP OK for " ${equipment[${Id[${x}]}]}
        fi
    done
    let j=${i}+1
fi

#Register start time
end=$(date +"%T")
FinalDate=$(date -u -d "$end" +"%s")

duration=$(date -u -d "0 $FinalDate sec - $StartDate sec" +"%H:%M:%S")

if [[ -f $ErrEquip && -f $SnmpEmpty ]];then
    # Send a mail which say the reason of the error
    subject="Script SNMP Switch error";
    echo "`date`
    Script duration: $duration minutes
    Error processing script please look at logfile attached" | mailx -r "$sender" -s "$subject" -a "${ErrEquip}" -a "${SnmpEmpty}" $mailaddress;
elif [ -f $ErrEquip ];then
    # Send a mail which say the reason of the error
    subject="Script SNMP Switch error";
    echo "`date`
    Script duration: $duration minutes
    Error processing script please look at logfile attached" | mailx -r "$sender" -s "$subject" -a "${ErrEquip}" $mailaddress;
elif [ -f $SnmpEmpty ];then
    # Send a mail which say the reason of the error
    subject="Script SNMP Switch error";
    echo "`date`
    Script duration: $duration minutes
    Error processing script please look at logfile attached" | mailx -r "$sender" -s "$subject" -a "${SnmpEmpty}" $mailaddress;
fi
