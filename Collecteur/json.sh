file=data.json
#curl -s https://data.nasa.gov/d.json | jq . > $file
size="$(jq length $file)"
for (( i=0; i<$size; i++ ))
do
    node="$(jq -r ".[$i].ip" data.json)"
    snmpcom="$(jq -r ".[$i].community" data.json)"
    echo $node
    echo $snmpcom
done

~~~~~~~~

while IFS=, read -r Index Descr Type Mtu Speed PhysAddress AdminStatus OperStatus LastChange InOctets InUcastPkts InNUcastPkts InDiscards InErrors InUnknownProtos OutOctets OutUcastPkts OutNUcastPkts OutDiscards OutErrors OutQLen Specific
do
    echo "$node"_"IfIndex"_"$Index"_"$Descr"_"$Type"_"$Mtu"_"$Speed"_"$PhysAddress"_"$AdminStatus"_"$OperStatus"_"$LastChange"_"$InOctets"_"$InUcastPkts"_"$InNUcastPkts"_"$InDiscards"_"$InErrors"_"$InUnknownProtos"_"$OutOctets"_"$OutUcastPkts"_"$OutNUcastPkts"_"$OutDiscards"_"$OutErrors"_"$OutQLen"_"$Specific"
done < _ifTable_temp.csv
