import os
import csv
import re
import time
import requests
import json
from datetime import datetime
from os.path import getsize

DB="http://192.168.1.2:5000"
header = {"Content-Type": "application/json"}

response = requests.get(DB+'/api/devices')
equipment = json.loads(response.text) 

def main():
    os.chdir("/tmp/snmptemp/csv/")
    path = "/tmp/snmptemp/csv/"
    directories = os.listdir(path)

    for file in directories:
        file_size = getsize(file)
        if file_size == 0:
            os.remove(file)
            break
        time.sleep(.300)

        #words = ['ifTable','ipAddrTable','vmVlan','vtpVlanTable','ifAlias','dot1dBasePortTable','dot1dTpFdbTable','vlanTrunkPortDynamicStatus']
        if re.match('.*ifTable.*', file):
            oid="ifTable"
        elif re.match('.*ipAddrTable.*', file):
            oid="ipAddrTable"
        elif re.match('.*vmVlan.*', file):
            oid="vmVlan"
        elif re.match('.*vtpVlanTable.*', file):
            oid="vtpVlanTable"
        elif re.match('.*ifAlias.*', file):
            oid="ifAlias"
        elif re.match('.*dot1dBasePortTable.*', file):
            oid="dot1dBasePortTable"
        elif re.match('.*dot1dTpFdbTable.*', file):
            oid="dot1dTpFdbTable"
        elif re.match('.*vlanTrunkPortDynamicStatus.*', file):
            oid="vlanTrunkPortDynamicStatus"
        else:
            print("Name of the file incorrect")

        print(file)

        IP = file.split("_")[0]
        for device in equipment:
            if device["ip"] == IP:
                type= device["type"]

        with open(file) as csvDataFile:
            print(oid)
            #response = requests.get('http://192.168.1.2:5000/api/devices')
            csvReader = csv.reader(csvDataFile)
            next(csvReader)
            for row in csvReader:
                dateTimeObj = datetime.now()
                liste = "_".join(row)
                payload = {'ip':IP, 'name': oid, 'deviceType':type, 'data':liste, 'timestamp':dateTimeObj}
                r = requests.post(DB+"/api/database/snmpdata/all", data=payload)
            time.sleep(.300)
            os.remove(file)

if __name__ == "__main__":
    main()

print("End")
