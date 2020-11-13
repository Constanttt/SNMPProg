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
loc="/tmp/snmptemp/csv/switch/"

#SNMP Community for test
#snmpcom="snmpcom"

#Set invalid VLAN
invalidvlans="100[2-5]"

#Equipments List for test
file=${TmpDir}data.json

#Set Workspace
TmpDir="/tmp/snmptemp/switch/"

#Set error equipment file
ErrEquip=${loc}snmp_switch_errors.err

#Set error file for emptyCSV to analyse
SnmpEmpty=${loc}snmp_switch_empty.err

#Mail to Send Error files
mailaddress="valentin.ginard@etu.univ-smb.fr"

# Set email sender
senderaddress="noreply@etu.univ-smb.fr (Automated script)"

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
    node=$1; name=$2; snmpcom=$3; timeout=$4

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get the show interface
        snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Cf , ifTable > ${TmpDir}${name}_ifTable_temp.csv; returncode=$?
        #echo "snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Cf , ifTable"
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
    node=$1; name=$2; snmpcom=$3; timeout=$4

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get IP address table
        snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Cf , ipAddrTable > ${TmpDir}${name}_ipAddrTable_temp.csv; returncode=$?
    	#echo "snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Cf , ipAddrTable"
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
    node=$1; name=$2; snmpcom=$3; timeout=$4

    #We don t use the snmp table so we have to inject the header manually
    printf "IfIndex = IfIndexVTP\r\n" > ${TmpDir}${name}_vmVlan_temp.csv
    printf "IfIndex = IfIndexVTP\r\n" > ${loc}${name}_vmVlan.csv
    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get Vlan Table
        snmpwalk -v 2c -m +ALL -c $snmpcom $node vmVlan -OQ -Os >> ${TmpDir}${name}_vmVlan_temp.csv; returncode=$?
    	#echo "snmpwalk -v 2c -m +ALL -c $snmpcom $node vmVlan -OQ -Os"
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
    node=$1; name=$2; snmpcom=$3; timeout=$4

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get VTP
        snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Ci -Cf , vtpVlanTable > ${TmpDir}${name}_vtpVlanTable_temp.csv; returncode=$?
    	#echo "snmptable -v 2c -m +ALL -c $snmpcom $node -Cb -Ci -Cf , vtpVlanTable"
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

function ifAlias
{
    #Get the first & second argument & third if exist
    node=$1; name=$2; snmpcom=$3; timeout=$4

    #We don't use the snmp table so we have to inject the header manually
    printf "IfIndex = Alias\r\n" > ${TmpDir}${name}_ifAlias_temp.csv
    printf "IfIndex = Alias\r\n" > ${loc}${name}_ifAlias.csv

    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get Vlan Table
        snmpwalk -v 2c -m +ALL -c $snmpcom $node  ifAlias -OQ -Os >> ${TmpDir}${name}_ifAlias_temp.csv; returncode=$?
    	#echo "snmpwalk -v 2c -m +ALL -c $snmpcom $node  ifAlias -OQ -Os"
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
    node=$1; name=$2; snmpcom=$3; timeout=$4
    #We don't use the snmp table so we have to inject the header manually
    printf "IfIndex = Trunk\r\n" > ${TmpDir}${name}_vlanTrunkPortDynamicStatus_temp.csv
    printf "IfIndex = Trunk\r\n" > ${loc}${name}_vlanTrunkPortDynamicStatus.csv
    #Check if we ask a timeout
    if [ -z $timeout ];then
        #snmptable to get Vlan Table
        snmpwalk -v 2c -m +ALL -c $snmpcom $node vlanTrunkPortDynamicStatus  -OQ -Os >> ${TmpDir}${name}_vlanTrunkPortDynamicStatus_temp.csv; returncode=$?
    	#echo "snmpwalk -v 2c -m +ALL -c $snmpcom $node vlanTrunkPortDynamicStatus  -OQ -Os"
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
    node=$1; snmpcom=$2

    #Get equipments name & Get returncode for snmp name equipment request
    name="$(snmpget -r 1 -t 20 -v 2c -m +ALL -Ov -Oq -c $snmpcom $node sysName.0)"
    
    if [ -z $name ];then
        #Get equipments name & Get returncode for snmp name equipment request
        name="$(snmpget -r 2 -t 60 -v 2c -m +ALL -Ov -Oq -c $; name=$2; $node sysName.0)"
        if [ -z $name ];then
            name=$node
        fi
    fi

    #Get exit status of the last command - if no error during last command execution
    if [ $? -eq 0 ]
    then
        #Call ifTable function with the IP and the name
        ifTable $node $name $snmpcom
        #Call ipAddrTable function with the IP and the name
        ipAddrTable $node $name $snmpcom
        #Call vmVlan function with the IP and the name
        #vmVlan $node $name $snmpcom
        #Call vtpVlanTable function with the IP and the name
        #vtpVlanTable $node $name $snmpcom
        #Call ifAlias function with the IP and the name
        ifAlias $node $name $snmpcom
        #Call dot1dBasePortTable function with the IP and the name
        dot1dBasePortTable $node $name $snmpcom
        #Call dot1dTpFdbTable function with the IP and the name
        dot1dTpFdbTable $node $name $snmpcom
        #Call vlanTrunkPortDynamicStatus function with the IP and the name
        #vlanTrunkPortDynamicStatus $node $name $snmpcom
    else
        printf "$node --> KO \r\n"
    fi
}

function EmptyCSV {

    #Get the first argument
    node=$1; snmpcom=$2;

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
    #filevmVlan=${loc}${name}_vmVlan.csv
    #filevtpVlanTable=${loc}${name}_vtpVlanTable.csv
    fileifAlias=${loc}${name}_ifAlias.csv
    filedot1dBasePortTable=${loc}${name}_dot1dBasePortTable.csv
    filedot1dTpFdbTable=${loc}${name}_dot1dTpFdbTable.csv
    #filevlanTrunkPortDynamicStatus=${loc}${name}_vlanTrunkPortDynamicStatus.csv

    #Minimum size required
    minimumsize=3

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
        #ifTable $node $name $snmpcom 10
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
        #ipAddrTable $node $name $snmpcom 10
        if [ -f $fileipAddrTable ];then
            #Calcul the size of all files
            ipAddrTable=$( stat -c %s ${loc}${name}_ipAddrTable.csv)
            #Chech the size for ipAddrTable of the node to know if it empty
            if [ $minimumsize -ge $ipAddrTable ]; then
              echo "ipAddrTable is empty for "$name".Size : " $ipAddrTable >> ${SnmpEmpty}
              rm $fileipAddrTable
            fi
        else
            echo "ipAddrTable for "$name" doesn t exist" >> ${SnmpEmpty}
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
    fi

    if [ -f $filevtpVlanTable ];then
        #Calcul the size of all files
        vtpVlanTable=$( stat -c %s ${loc}${name}_vtpVlanTable.csv)
        #Chech the size for vtpVlanTable of the node to know if it empty
        if [ $minimumsize -ge $vtpVlanTable ]; then
            echo "vtpVlanTable is empty for "$name".Size : " $vtpVlanTable >> ${SnmpEmpty}
            rm $filevtpVlanTable
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
        #ifAlias $node $name $snmpcom 10
        if [ -f $fileifAlias ];then
            #Calcul the size of all files
            ifAlias=$( stat -c %s ${loc}${name}_ifAlias.csv)
            #Chech the size for ifAlias of the node to know if it empty
            if [ $minimumsize -ge $ifAlias ]; then
                echo "ifAlias is empty for "$name".Size : " $ifAlias >> ${SnmpEmpty}
                rm $fileifAlias
            fi
        else
            echo "ifAlias for "$name" doesn t exist" >> ${SnmpEmpty}
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
        #vlanTrunkPortDynamicStatus $node $name $snmpcom 10
        if [ -f $filevlanTrunkPortDynamicStatus ];then
            #Calcul the size of all files
            vlanTrunkPortDynamicStatus=$( stat -c %s ${loc}${name}_vlanTrunkPortDynamicStatus.csv)
            #Chech the size for vlanTrunkPortDynamicStatus of the node to know if it empty
            if [ $minimumsize -ge $vlanTrunkPortDynamicStatus ]; then
                echo "vlanTrunkPortDynamicStatus is empty for "$name".Size : " $vlanTrunkPortDynamicStatus >> ${SnmpEmpty}
                rm $filevlanTrunkPortDynamicStatus
            fi
        else
            echo "vlanTrunkPortDynamicStatus for "$name" doesn t exist" >> ${SnmpEmpty}
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

#Debug
echo "~~~~~~~Start : $start~~~~~~ "

curl 127.0.0.1:5000/api/devices | jq . > $file
size="$(jq length $file)"
for (( i=0; i < $size; i++ ))
do
    echo "\n\r~~~~~~~Start i=$i~~~~~~"
    node="$(jq -r ".[$i].ip" data.json)"
    snmpcom="$(jq -r ".[$i].community" data.json)"
    echo "node : $node"
    echo "community : $snmpcom"
    #Ping and snmp request
    ping $node -c 1 -w 1 &> /dev/null && snmpget -r 1 -t 20 -v 2c -m +ALL -Ov -Oq -c $snmpcom $node sysName.0 &> /dev/null
    #Check return code
    if [ $? -eq 0 ];then
        #Exec the function GetSNMP with as param the name of the equipment
        GetSNMP $node $snmpcom &
        #Get the PID of the function
        Id[${i}]=$!
        #Store tehe PID
        equipment[${Id[${i}]}]=$node
        # Wait the end of the function
        wait ${Id[${x}]}
        #Double check
        EmptyCSV ${equipment[${Id[${x}]}]} $snmpcom &
        if [ $? -ne 0 ];then
                    # get return and store it
                    echo "SNMP NOK for " ${equipment[${Id[${x}]}]} >> ${ErrEquip}
                    echo "SNMP NOK for " ${equipment[${Id[${x}]}]}
        else
                    # get return
                    echo "SNMP OK for " ${equipment[${Id[${x}]}]}
        fi
    else
        echo "Ping or SNMP no answered for " $node >> ${ErrEquip}
        echo "Ping or SNMP no answered for " $node
    fi
done

end=$(date +"%T")
FinalDate=$(date -u -d "$end" +"%s")

duration=$(date -u -d "0 $FinalDate sec - $StartDate sec" +"%H:%M:%S")


#Check is the error file if exist
if [ -f $file ]
then
        #Clear the error equipment file
        rm ${file}
fi

echo "$FinalDate : END"
