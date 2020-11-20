import os
import csv
import re
import time
from os.path import getsize

def ifTable(file):
    print(file)
    with open(file) as csvDataFile:
        print("ifTable")
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)
        time.sleep(.300)
        os.remove(file)
        

def ipAddrTable(file):
    print(file)
    with open(file) as csvDataFile:
        print("ipAddrTable")
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)
        time.sleep(.300)
        os.remove(file)

def vtpVlanTable(file):
    print(file)
    with open(file) as csvDataFile:
        print("vtpVlanTable")
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)
        time.sleep(.300)
        os.remove(file)

def vmVlan(file):
    print(file)
    with open(file) as csvDataFile:
        print("vmVlan")
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)
        time.sleep(.300)
        os.remove(file)

def ifAlias(file):
    print(file)
    with open(file) as csvDataFile:
        print("ifAlias")
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)
        time.sleep(.300)
        os.remove(file)

def dot1dBasePortTable(file):
    print(file)
    with open(file) as csvDataFile:
        print("dot1dBasePortTable")
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)
        time.sleep(.300)
        os.remove(file)

def dot1dTpFdbTable(file):
    print(file)
    with open(file) as csvDataFile:
        print("dot1dTpFdbTable")
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)
        time.sleep(.300)
        os.remove(file)

def vlanTrunkPortDynamicStatus(file):
    print(file)
    with open(file) as csvDataFile:
        print("vlanTrunkPortDynamicStatus")
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)
        time.sleep(.300)
        os.remove(file)

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
