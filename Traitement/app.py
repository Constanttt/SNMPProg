import os
import csv
import re
from os.path import getsize

def ifTable(file):
    with open(file) as csvDataFile:
        print("ifTable")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def ipAddrTable(file):
    with open(file) as csvDataFile:
        print("ipAddrTable")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def vtpVlanTable(file):
    with open(file) as csvDataFile:
        print("vtpVlanTable")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def vmVlan(file):
    with open(file) as csvDataFile:
        print("vmVlan")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def ifAlias(file):
    with open(file) as csvDataFile:
        print("ifAlias")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def dot1dBasePortTable(file):
    with open(file) as csvDataFile:
        print("dot1dBasePortTable")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def dot1dTpFdbTable(file):
    with open(file) as csvDataFile:
        print("dot1dTpFdbTable")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def vlanTrunkPortDynamicStatus():
    with open(file) as csvDataFile:
        print("vlanTrunkPortDynamicStatus")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def main():
    os.chdir("/tmp/snmptemp/csv/switch/")
    path = "/tmp/snmptemp/csv/switch/"
    directories = os.listdir(path)

    for file in directories:
        file_size = getsize(file)
        if file_size == 0:
            os.remove(file)

        #words = ['ifTable','ipAddrTable','vmVlan','vtpVlanTable','ifAlias','dot1dBasePortTable','dot1dTpFdbTable','vlanTrunkPortDynamicStatus']
        if re.match('.*ifTable.*', file):
            ifTable(file)
        elif re.match('.*ipAddrTable.*', file):
            ipAddrTable(file)
        elif re.match('.*vmVlan.*', file):
            vmVlan(file)
        elif re.match('.*vtpVlanTable.*', file):
            vtpVlanTable(file)
        elif re.match('.*ifAlias.*', file):
            ifAlias(file)
        elif re.match('.*dot1dBasePortTable.*', file):
            dot1dBasePortTable(file)
        elif re.match('.*dot1dTpFdbTable.*', file):
            dot1dTpFdbTable(file)
        elif re.match('.*vlanTrunkPortDynamicStatus.*', file):
            vlanTrunkPortDynamicStatus(file)
        else:
            print("Name of the file incorrect")

if __name__ == "__main__":
    main()

print("End")
