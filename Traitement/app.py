import os
import csv
from os.path import getsize

def ifTable():
    with open(file) as csvDataFile:
        print("ifTable")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def ipAddrTable():
    with open(file) as csvDataFile:
        print("ipAddrTable")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def vtpVlanTable():
    with open(file) as csvDataFile:
        print("vtpVlanTable")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def vmVlan():
    with open(file) as csvDataFile:
        print("vmVlan")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def ifAlias():
    with open(file) as csvDataFile:
        print("ifAlias")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def dot1dBasePortTable():
    with open(file) as csvDataFile:
        print("dot1dBasePortTable")
        print(file)
        csvReader = csv.reader(csvDataFile)
        for row in csvReader:
            print(row)

def dot1dTpFdbTable():
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
        
    words = ['ifTable','ipAddrTable','vmVlan','vtpVlanTable','ifAlias','dot1dBasePortTable','dot1dTpFdbTable','vlanTrunkPortDynamicStatus']
    for i in words:
        func = print (i)
        getattr(func, lambda: default)()

if __name__ == "__main__":
    main()

print("End")
