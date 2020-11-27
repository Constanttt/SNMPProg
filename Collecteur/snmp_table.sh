#!/bin/bash
#
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
loc="/tmp/snmptemp/csv/"

#SNMP Community for test
#snmpcom="snmpcom"

#DB
DB="192.168.1.2:5000"

#Set invalid VLAN
invalidvlans="100[2-5]"

#Equipments List for test
file=${TmpDir}data.json

#Set Workspace
TmpDir="/tmp/snmptemp/tmp/"

#Set error equipment file
ErrEquip=${loc}snmp_errors.err

#Set error file for emptyCSV to analyse
SnmpEmpty=${loc}snmp_empty.err

#If the folder of all CSV file doesn't exist create it
if [ ! -d ${loc} ]; then
        mkdir -p $loc
fi

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
    node=$1; name=$2; version=$3

    #Depend of the version bring different informations
    if [ $version -eq 2 ];then
        snmpcom=$4; timeout=$5

        #Check if we ask a timeout
        if [ -z $timeout ];then
            #snmptable to get the show interface
            snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Cf , ifTable > ${TmpDir}${node}_${name}_ifTable_temp.csv; returncode=$?
            wait 10
        else
            #snmptable to get the show interface
            snmptable -r 2 -t $timeout -v 2c -m +ALL -c $snmpcom $node -Cb -Cf , ifTable > ${TmpDir}${node}_${name}_ifTable_temp.csv; returncode=$?
        fi
    else
        username=$4; protocol=$5; password=$6; protocolprivacy=$7; passwordprivacy=$8

        #snmptable to get the show interface
        snmptable -v 3 -u $username -a $protocol -A $password -x $protocolprivacy -X $passwordprivacy -l authPriv $node -Cb -Cf , ifTable > ${TmpDir}${node}_${name}_ifTable_temp.csv; returncode=$?
        wait 10
    fi

    if [ $returncode -ne 0 ];then
            curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"SNMP IfTable failed for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
           return 1
        else
            #Delete the three first lines
            tail -n +3 ${TmpDir}${node}_${name}_ifTable_temp.csv > ${loc}${node}_${name}_ifTable.csv
            #Open the CSV file and replace Index by IfIndex for Splunk
            sed -i 's/Index/IfIndex/g' ${loc}${node}_${name}_ifTable.csv
            #Remove the temporary file
            rm ${TmpDir}${node}_${name}_ifTable_temp.csv
    fi
}

function ipAddrTable
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; snmpcom=$3; timeout=$4

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get IP address table
        snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Cf , ipAddrTable > ${TmpDir}${node}_${name}_ipAddrTable_temp.csv; returncode=$?
    	#echo "snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Cf , ipAddrTable"
    else
        #snmptable to get IP address table
        snmptable -r 2 -t $timeout -v 2c -m +ALL -c $snmpcom $node -Cb -Cf , ipAddrTable > ${TmpDir}${node}_${name}_ipAddrTable_temp.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
        curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"SNMP ipAddrTable failed for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
       return 1
    else
        #Delete the three first lines
        tail -n +3 ${TmpDir}${node}_${name}_ipAddrTable_temp.csv > ${loc}${node}_${name}_ipAddrTable.csv
        #Remove the temporary file
        rm ${TmpDir}${node}_${name}_ipAddrTable_temp.csv
    fi
}


function vmVlan
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; snmpcom=$3; timeout=$4

    #We don t use the snmp table so we have to inject the header manually
    printf "IfIndex = IfIndexVTP\r\n" > ${TmpDir}${node}_${name}_vmVlan_temp.csv
    printf "IfIndex = IfIndexVTP\r\n" > ${loc}${node}_${name}_vmVlan.csv
    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get Vlan Table
        snmpwalk -v 2c -c $snmpcom $node 1.3.6.1.4.1.9.9.68.1.2.2.1.2 -OQ -Os >> ${TmpDir}${node}_${name}_vmVlan_temp.csv; returncode=$?
    	#echo "snmpwalk -v 2c -m +ALL -c $snmpcom $node vmVlan -OQ -Os"
    else
        #snmptable to get Vlan Table
        snmpwalk -r 2 -t $timeout -v 2c -c $snmpcom $node 1.3.6.1.4.1.9.9.68.1.2.2.1.2 -OQ -Os >> ${TmpDir}${node}_${name}_vmVlan_temp.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
        curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"SNMP vmVlan failed for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
       return 1
    else
        #Cut in all . and keep the 2nd part
        cut -d . -f 2 ${TmpDir}${node}_${name}_vmVlan_temp.csv > ${loc}${node}_${name}_vmVlan.csv
        #Open the CSV file and replace " = " by "," for Splunk
        sed -i 's/ = /,/g'  ${loc}${node}_${name}_vmVlan.csv
    fi
    #Remove the temporary file
    rm ${TmpDir}${node}_${name}_vmVlan_temp.csv
}

function vtpVlanTable
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; snmpcom=$3; timeout=$4

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get VTP
        snmptable -v 2c -c $snmpcom $node -Cb -Ci -Cf , 1.3.6.1.4.1.9.9.46.1.3.1 > ${TmpDir}${node}_${name}_vtpVlanTable_temp.csv; returncode=$?
    	#echo "snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Ci -Cf , vtpVlanTable"
    else
        #snmptable to get VTP
        snmptable -r 2 -t $timeout -v 2c -c $snmpcom $node -Cb -Ci -Cf , 1.3.6.1.4.1.9.9.46.1.3.1 > ${TmpDir}${node}_${name}_vtpVlanTable_temp.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
        curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"SNMP vtpVlanTable failed for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
       return 1
    else
        #Cut in all . and keep the 2nd part | Delete the 3 first lines
        cut -d . -f 2 ${TmpDir}${node}_${name}_vtpVlanTable_temp.csv | tail -n +3 > ${loc}${node}_${name}_vtpVlanTable.csv
        #Open the CSV file and replace the header index by IfIndexVTP for Splunk
        sed -i 's/index/IfIndexVTP/g' ${loc}${node}_${name}_vtpVlanTable.csv
        #Remove the temporary file
        rm ${TmpDir}${node}_${name}_vtpVlanTable_temp.csv
    fi
}

function ifAlias
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; snmpcom=$3; timeout=$4

    #We don't use the snmp table so we have to inject the header manually
    printf "IfIndex = Alias\r\n" > ${TmpDir}${node}_${name}_ifAlias_temp.csv
    printf "IfIndex = Alias\r\n" > ${loc}${node}_${name}_ifAlias.csv

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get Vlan Table
        snmpwalk -v 2c -m +ALL -c $snmpcom $node  ifAlias -OQ -Os >> ${TmpDir}${node}_${name}_ifAlias_temp.csv; returncode=$?
    	#echo "snmpwalk -v 2c -m +ALL -c $snmpcom $node  ifAlias -OQ -Os"
    else
        #snmptable to get Vlan Table
        snmpwalk -r 2 -t $timeout -v 2c -m +ALL -c $snmpcom $node  ifAlias -OQ -Os >> ${TmpDir}${node}_${name}_ifAlias_temp.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
        curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"SNMP ifAlias failed for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
        return 1
    else
        #Cut in all . and keep the 2nd part
        cut -d . -f 2 ${TmpDir}${node}_${name}_ifAlias_temp.csv > ${loc}${node}_${name}_ifAlias.csv
        #Open the CSV file and replace all " = " by "," for Splunk
        sed -i 's/ = /,/g' ${loc}${node}_${name}_ifAlias.csv
    fi
    #Delete the temporary file
    rm ${TmpDir}${node}_${name}_ifAlias_temp.csv
}

function dot1dBasePortTable
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; snmpcom=$3; timeout=$4

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get generic information about every port
        snmptable -v 2c -m +ALL -c $snmpcom@1 $node -Cf , dot1dBasePortTable > /dev/null; returncode=$?
    	#echo "snmptable -v 2c -m +ALL -c $snmpcom@1 $node -Cf , dot1dBasePortTable"
    else
        #snmptable to get generic information about every port
        snmptable -r 1 -t $timeout -v 2c -m +ALL -c $snmpcom@1 $node -Cf , dot1dBasePortTable > /dev/null; returncode=$?
    fi

    if [ $returncode -eq 0 ]; then
        #Check if we ask a timeout
    printf "Port,IfIndex,dot1dBasePortCircuit,dot1dBasePortDelayExceededDiscards,dot1dBasePortMtuExceededDiscards\r\n" > ${TmpDir}${node}_${name}_dot1dBasePortTable_temp.csv
        if [ -z $timeout ];then
            snmptable -v 2c -m +ALL -c $snmpcom@1 $node -CH -Cf , dot1dBasePortTable >> ${TmpDir}${node}_${name}_dot1dBasePortTable_temp.csv; return=$?
        else
            snmptable -r 1 -t $timeout -v 2c -m +ALL -c $snmpcom@1 $node -CH -Cf , dot1dBasePortTable >> ${TmpDir}${node}_${name}_dot1dBasePortTable_temp.csv; return=$?
        fi

        if [ $return -eq 0 ];then
            #snmptable to get VTP | cut in order to keep the vlan id | foreach id do :
            snmptable -r 1 -t 700 -v 2c -m +ALL -c $snmpcom $node -Ci -CH -Cf , vtpVlanTable | cut -d , -f 1 | cut -d . -f 2 | while read line;do
                #If the vlan id match an invalid vlan
                if [[ ! $line =~ $invalidvlans ]];then
                    #Check if we ask a timeout
                    if [ -z $timeout ];then
                        #snmptable to get generic information for the vlan | Delete the 3 first lines and inject the result at the end of the CSV
                        snmptable -v 2c -m +ALL -c $snmpcom@$line $node -CH -Cf , dot1dBasePortTable >> ${TmpDir}${node}_${name}_dot1dBasePortTable_temp.csv
                    else
                        #snmptable to get generic information for the vlan | Delete the 3 first lines and inject the result at the end of the CSV
                        snmptable -r 1 -t $timeout -v 2c -m +ALL -c $snmpcom@$line $node -CH -Cf , dot1dBasePortTable >> ${TmpDir}${node}_${name}_dot1dBasePortTable_temp.csv
                    fi
                fi
            done
            #Copie to the final CSV
            cat ${TmpDir}${node}_${name}_dot1dBasePortTable_temp.csv >> ${loc}${node}_${name}_dot1dBasePortTable.csv
            rm ${TmpDir}${node}_${name}_dot1dBasePortTable_temp.csv
        fi
    else
        curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"SNMP dot1dBasePortTable failed for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
        return 1
    fi
}

function dot1dTpFdbTable
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; snmpcom=$3; timeout=$4

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get @mac learned for the vlan 1
        snmptable -O0sUX -v 2c -m +ALL -c $snmpcom@1 $node -CH -Cf , dot1dTpFdbTable > /dev/null; returncode=$?
    	#echo "snmptable -O0sUX -v 2c -m +ALL -c $snmpcom@1 $node -CH -Cf , dot1dTpFdbTable"
    else
        #snmptable to get @mac learned for the vlan 1
        snmptable -r 1 -t $timeout -O0sUX -v 2c -m +ALL -c $snmpcom@1 $node -CH -Cf , dot1dTpFdbTable > /dev/null; returncode=$?
    fi

    if [ $returncode -eq 0 ];then
    printf "Address,Port,Status\r\n" > ${TmpDir}${node}_${name}_dot1dTpFdbTable_temp.csv
     
    	if [ -z $timeout ];then
            snmptable -v 2c -m +ALL -c $snmpcom@1 $node -CH -Cf , dot1dTpFdbTable >> ${TmpDir}${node}_${name}_dot1dTpFdbTable_temp.csv; return=$?
        else
            snmptable -r 1 -t $timeout -v 2c -m +ALL -c $snmpcom@1 $node -CH -Cf , dot1dTpFdbTable >> ${TmpDir}${node}_${name}_dot1dTpFdbTable_temp.csv; return=$?
        fi

        if [ $return -eq 0 ];then
       #snmptable to get VTP | cut in order to keep the vlan id | foreach id do :
            snmptable -r 1 -t 700 -v 2c -m +ALL -c $snmpcom $node -Ci -CH -Cf , vtpVlanTable | cut -d , -f 1 | cut -d . -f 2 | while read line; do
            #If the vlan id match an invalid vlan
            if [[ ! $line =~ $invalidvlans ]];then
                #Check if we ask a timeout
                if [ -z $timeout ];then
                    #snmptable to get mac address learned for the vlan | Delete the 3 first lines and inject the result at the end of the CSV
                    snmptable -O0sUX -v 2c -m +ALL -c $snmpcom@$line $node -CH -Cf , dot1dTpFdbTable >> ${TmpDir}${node}_${name}_dot1dTpFdbTable_temp.csv
                else
                    #snmptable to get mac address learned for the vlan | Delete the 3 first lines and inject the result at the end of the CSV
                    snmptable -r 1 -t $timeout -O0sUX -v 2c -m +ALL -c $snmpcom@$line $node -CH -Cf , dot1dTpFdbTable >> ${TmpDir}${node}_${name}_dot1dTpFdbTable_temp.csv
                fi
            fi
        done
           #Copie to the final CSV
           cat ${TmpDir}${node}_${name}_dot1dTpFdbTable_temp.csv >> ${loc}${node}_${name}_dot1dTpFdbTable.csv
           rm ${TmpDir}${node}_${name}_dot1dTpFdbTable_temp.csv
    fi
    else
        curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"SNMP dot1dTpFdbTable failed for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
        return 1
    fi
}

function vlanTrunkPortDynamicStatus 
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; snmpcom=$3; timeout=$4
    #We don't use the snmp table so we have to inject the header manually
    printf "IfIndex = Trunk\r\n" > ${TmpDir}${node}_${name}_vlanTrunkPortDynamicStatus_temp.csv
    printf "IfIndex = Trunk\r\n" > ${loc}${node}_${name}_vlanTrunkPortDynamicStatus.csv
    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get Vlan Table
        snmpwalk -v 2c -c $snmpcom $node 1.3.6.1.4.1.9.9.46.1.6.1.1.14  -OQ -Os >> ${TmpDir}${node}_${name}_vlanTrunkPortDynamicStatus_temp.csv; returncode=$?
    	#echo "snmpwalk -v 2c -m +ALL -c $snmpcom $node vlanTrunkPortDynamicStatus  -OQ -Os"
    else
        #snmptable to get Vlan Table
        snmpwalk -r 2 -t $timeout -v 2c -c $snmpcom $node 1.3.6.1.4.1.9.9.46.1.6.1.1.14  -OQ -Os >> ${TmpDir}${node}_${name}_vlanTrunkPortDynamicStatus_temp.csv; returncode=$?
    fi

    if [ $returncode -ne 0 ];then
        curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"SNMP vlanTrunkPortDynamicStatus failed for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
       return 1
    else
        #Cut in all . and keep the 2nd part
        cut -d . -f 2 ${TmpDir}${node}_${name}_vlanTrunkPortDynamicStatus_temp.csv > ${loc}${node}_${name}_vlanTrunkPortDynamicStatus.csv
        #Open the CSV file and replace " = " by "," for Splunk
        sed -i 's/ = /,/g'  ${loc}${node}_${name}_vlanTrunkPortDynamicStatus.csv
    fi
    #Remove the temporary file
    rm ${TmpDir}${node}_${name}_vlanTrunkPortDynamicStatus_temp.csv
}


#Function GetSNMP to parse SNMP Values
function GetSNMP
{
    #Get arguments
    node=$1;  version=$2

    #Depend of the version bring different informations
    if [ $version -eq 2 ];then
        snmpcom=$3; 

        #Get equipments name & Get returncode for snmp name equipment request
        name="$(snmpget -r 1 -t 20 -v 2c -m +ALL -Ov -Oq -c $snmpcom $node sysName.0)"
    
        if [ -z $name ];then
            #Get equipments name & Get returncode for snmp name equipment request
            name="$(snmpget -r 1 -t 20 -v 2c -m +ALL -Ov -Oq -c $snmpcom $node sysName.0)"
            if [ -z $name ];then
                name=$node
            fi
        fi

        #Call ifTable function with the IP and the name
        ifTable $node $name $version $snmpcom
        #Call ipAddrTable function with the IP and the name
        ipAddrTable $node $name $snmpcom
        #Call ifAlias function with the IP and the name
        ifAlias $node $name $snmpcom
        #Call ifAlias function with the IP and the name
        vmVlan $node $name $snmpcom
        #Call ifAlias function with the IP and the name
        vtpVlanTable $node $name $snmpcom
        #Call dot1dBasePortTable function with the IP and the name
        dot1dBasePortTable $node $name $snmpcom
        #Call dot1dTpFdbTable function with the IP and the name
        dot1dTpFdbTable $node $name $snmpcom
        #Call vlanTrunkPortDynamicStatus function with the IP and the name
        vlanTrunkPortDynamicStatus $node $name $snmpcom
    else
        username=$3; protocol=$4; password=$5; protocolprivacy=$6; passwordprivacy=$7

        #Get equipments name & Get returncode for snmp name equipment request
        name="$(snmpget -r 1 -t 20 -v 3 -u $username -a $protocol -A $password -x $protocolprivacy -X $passwordprivacy -l authPriv -Ov -Oq $node sysName.0)"
        
        if [ -z $name ];then
            #Get equipments name & Get returncode for snmp name equipment request
            name="$(snmpget -r 1 -t 20 -v 3 -u $username -a $protocol -A $password -x $protocolprivacy -X $passwordprivacy -l authPriv -Ov -Oq $node sysName.0)"
            if [ -z $name ];then
                name=$node
            fi
        fi

         #Call ifTable function with the IP and the name
        ifTable $node $name $version $username $protocol $password $protocolprivacy $passwordprivacy
    fi
}

function EmptyCSV {

    #Get the first argument
    node=$1; version=$2; snmpcom=$3

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
    fileifTable=${loc}${node}_${name}_ifTable.csv
    fileipAddrTable=${loc}${node}_${name}_ipAddrTable.csv
    filevmVlan=${loc}${node}_${name}_vmVlan.csv
    filevtpVlanTable=${loc}${node}_${name}_vtpVlanTable.csv
    fileifAlias=${loc}${node}_${name}_ifAlias.csv
    filedot1dBasePortTable=${loc}${node}_${name}_dot1dBasePortTable.csv
    filedot1dTpFdbTable=${loc}${node}_${name}_dot1dTpFdbTable.csv
    filevlanTrunkPortDynamicStatus=${loc}${node}_${name}_vlanTrunkPortDynamicStatus.csv

    #Minimum size required
    minimumsize=3

    if [ -f $fileifTable ];then
        #Calcul the size of all files
        ifTable=$( stat -c %s ${loc}${node}_${name}_ifTable.csv)
        #Chech the size for IfTable of the node to know if it empty
        if [ $minimumsize -ge $ifTable ]; then
            echo "IfTable is empty for "$name".Size : " $ifTable >> ${SnmpEmpty}
            curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"IfTable is empty for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
            rm $fileifTable
        fi
    fi

    if [ -f $fileipAddrTable ];then
        #Calcul the size of all files
        ipAddrTable=$( stat -c %s ${loc}${node}_${name}_ipAddrTable.csv)
        #Chech the size for ipAddrTable of the node to know if it empty
        if [ $minimumsize -ge $ipAddrTable ]; then
            curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"ipAddrTable is empty for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
            echo "ipAddrTable is empty for "$name".Size : " $ipAddrTable >> ${SnmpEmpty}
            rm $fileipAddrTable
        fi
    fi

    if [ -f $filevmVlan ];then
        #Calcul the size of all files
        vmVlan=$( stat -c %s ${loc}${node}_${name}_vmVlan.csv)
        #Chech the size for vmVlan of the node to know if it empty
        if [ $minimumsize -ge $vmVlan ]; then
            curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"vmVlan is empty for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
            echo "vmVlan is empty for "$name".Size : " $vmVlan >> ${SnmpEmpty}
            rm $filevmVlan
        fi
    fi

    if [ -f $filevtpVlanTable ];then
        #Calcul the size of all files
        vtpVlanTable=$( stat -c %s ${loc}${node}_${name}_vtpVlanTable.csv)
        #Chech the size for vtpVlanTable of the node to know if it empty
        if [ $minimumsize -ge $vtpVlanTable ]; then
            curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"vtpVlanTable is empty for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
            echo "vtpVlanTable is empty for "$name".Size : " $vtpVlanTable >> ${SnmpEmpty}
            rm $filevtpVlanTable
        fi
    fi

    if [ -f $fileifAlias ];then
        #Calcul the size of all files
        ifAlias=$( stat -c %s ${loc}${node}_${name}_ifAlias.csv)
        #Chech the size for ifAlias of the node to know if it empty
        if [ $minimumsize -ge $ifAlias ]; then
            curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"ifAlias is empty for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
            echo "ifAlias is empty for "$name".Size : " $ifAlias >> ${SnmpEmpty}
            rm $fileifAlias
        fi
    fi
    
    if [ -f $filedot1dBasePortTable ];then
        #Calcul the size of all files
        dot1dBasePortTable=$( stat -c %s ${loc}${node}_${name}_dot1dBasePortTable.csv)
        #Chech the size for dot1dBasePortTable of the node to know if it empty
        if [ $minimumsize -ge $dot1dBasePortTable ]; then
            curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"filedot1dBasePortTable is empty for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
            echo "dot1dBasePortTable is empty for "$name".Size : " $dot1dBasePortTable >> ${SnmpEmpty}
            rm $filedot1dBasePortTable
        fi
    fi

    if [ -f $filedot1dTpFdbTable ];then
        #Calcul the size of all files
        dot1dTpFdbTable=$( stat -c %s ${loc}${node}_${name}_dot1dTpFdbTable.csv)
        #Chech the size for dot1dTpFdbTable of the node to know if it empty
        if [ $minimumsize -ge $dot1dTpFdbTable ]; then
            curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"filedot1dTpFdbTable is empty for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
            echo "dot1dTpFdbTable is empty for "$name".Size : " $dot1dTpFdbTable >> ${SnmpEmpty}
            rm $filedot1dTpFdbTable
        fi
    fi

    if [ -f $filevlanTrunkPortDynamicStatus ];then
        #Calcul the size of all files
        vlanTrunkPortDynamicStatus=$( stat -c %s ${loc}${node}_${name}_vlanTrunkPortDynamicStatus.csv)
        #Chech the size for vlanTrunkPortDynamicStatus of the node to know if it empty
        if [ $minimumsize -ge $vlanTrunkPortDynamicStatus ]; then
            curl -X POST -H "Content-Type: application/json" -d '{"logType":"Error","logData":"vlanTrunkPortDynamicStatus is empty for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
            echo "vlanTrunkPortDynamicStatus is empty for "$name".Size : " $vlanTrunkPortDynamicStatus >> ${SnmpEmpty}
            rm $filevlanTrunkPortDynamicStatus
        fi
    fi
}

#Register start time
start=$(date +"%T")
StartDate=$(date -u -d "$start" +"%s")

#Debug
echo "~~~~~~~Start : $start~~~~~~ "

curl $DB/api/devices | jq . > $file

if [ $? -ne 0 ];then
    curl -X POST -H "Content-Type: application/json" -d '{"logType":"Critical","logData":"Unable to get equipment List","logIP":"0.0.0.0"}' $DB/api/database/logs/all
    echo "Unable to get equipment List - Warning High" >> ${ErrEquip}
fi

size="$(jq length $file)"
for (( i=0; i < $size; i++ ))
do
    echo "\n\r~~~~~~~Start i=$i~~~~~~"
    node="$(jq -r ".[$i].ip" data.json)"
    version="$(jq -r ".[$i].version" data.json)"
    echo "node : $node"
    echo "version : $version"

    if [ $version -eq 3 ];then
        username="$(jq -r ".[$i].username" data.json)"
        password="$(jq -r ".[$i].password" data.json)"
        protocol="$(jq -r ".[$i].protocol" data.json)"
        protocolprivacy="$(jq -r ".[$i].protocolprivacy" data.json)"
        passwordprivacy="$(jq -r ".[$i].passwordprivacy" data.json)"
        echo "username : $username"
        echo "password : $password"
        echo "protocol : $protocol"
        echo "protocolprivacy : $protocolprivacy"
        echo "passwordprivacy : $passwordprivacy"
    else
        snmpcom="$(jq -r ".[$i].community" data.json)"
        echo "community : $snmpcom"
    fi
    
    #Ping and snmp request to check connectivity
    if [ $version -eq 2 ];then
        ping $node -c 1 -w 1 &> /dev/null && snmpget -r 1 -t 20 -v 2c -m +ALL -Ov -Oq -c $snmpcom $node sysName.0 &> /dev/null; return=$?
    else
        ping $node -c 1 -w 1 &> /dev/null && snmpget -r 1 -t 20 -v 3 -u $username -a $protocol -A $password -x $protocolprivacy -X $passwordprivacy -l authPriv -Ov -Oq $node sysName.0 &> /dev/null; return=$?
    fi

    if [ $return -ne 0 ];then
        curl -X POST -H "Content-Type: application/json" -d '{"logType":"Notification","logData":"Ping or SNMP no answered for '$node'","logIP":"'$node'"}' $DB/api/database/logs/all
        echo "Ping or SNMP no answered for " $node >> ${ErrEquip}
        echo "Ping or SNMP no answered for " $node
    fi

    #Check return code
    if [ $? -eq 0 ];then

        #Depend of the version bring different informations
        if [ $version -eq 2 ];then
            #Exec the function GetSNMP with as param the name of the equipment
            GetSNMP $node $version $snmpcom  &
            #Get the PID of the function
            Id[${i}]=$!
            #Store tehe PID
            equipment[${Id[${i}]}]=$node
            # Wait the end of the function
            wait ${Id[${x}]}; returncode=$?
            #Double check
            EmptyCSV ${equipment[${Id[${x}]}]} $version $snmpcom &
        else
            #Exec the function GetSNMPv3 with as param the name of the equipment
            GetSNMP $node $version $username $protocol $password $protocolprivacy $passwordprivacy &
            #Get the PID of the function
            Id[${i}]=$!
            #Store tehe PID
            equipment[${Id[${i}]}]=$node
            # Wait the end of the function
            wait ${Id[${x}]}; returncode=$?
        fi
    fi
done

end=$(date +"%T"); FinalDate=$(date -u -d "$end" +"%s"); duration=$(date -u -d "0 $FinalDate sec - $StartDate sec" +"%H:%M:%S")

#Check is the error file if exist
if [ -f $file ]
then
    #Clear the error equipment file
    rm ${file}
fi

echo "$duration : END"