from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import json

from initBDD import SNMPData, Logs

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///bdd.db'
db = SQLAlchemy(app)

limit = 500

def get_logs():
    comma_list = Logs.query.all()
    arr = []
    for elem in comma_list:
        temp = str(elem).split(',')
        arr.append({
            "id":temp[0],
            "logType":temp[1],
            "logData":temp[2],
            "logIP":temp[3]
        })
    return arr

def get_logs_by_ip(ip):
    comma_list = Logs.query.filter_by(logIP=ip).all()
    arr = []
    for elem in comma_list:
        temp = str(elem).split(',')
        arr.append({
            "id":temp[0],
            "logType":temp[1],
            "logData":temp[2],
            "logIP":temp[3]
        })
    return arr

def get_logs_by_type(log_type):
    comma_list = Logs.query.filter_by(logType=log_type).all()
    arr = []
    for elem in comma_list:
        temp = str(elem).split(',')
        arr.append({
            "id":temp[0],
            "logType":temp[1],
            "logData":temp[2],
            "logIP":temp[3]
        })
    return arr

def get_snmpdata():
    comma_list = SNMPData.query.all()
    arr = []
    for elem in comma_list:
        temp = str(elem).split(',')
        arr.append({
            "id":temp[0],
            "ip":temp[1],
            "name":temp[2],
            "deviceType":temp[3],
            "data":temp[4],
            "timestamp":temp[5]
        })
    return arr

def get_snmpdata_by_ip(ip):
    comma_list = SNMPData.query.filter_by(ip=ip).all()
    arr = []
    for elem in comma_list:
        temp = str(elem).split(',')
        arr.append({
            "id":temp[0],
            "ip":temp[1],
            "name":temp[2],
            "deviceType":temp[3],
            "data":temp[4],
            "timestamp":temp[5]
        })
    return arr

def get_snmpdata_by_name(name):
    comma_list = SNMPData.query.filter_by(name=name).all()
    arr = []
    for elem in comma_list:
        temp = str(elem).split(',')
        arr.append({
            "id":temp[0],
            "ip":temp[1],
            "name":temp[2],
            "deviceType":temp[3],
            "data":temp[4],
            "timestamp":temp[5]
        })
    return arr

def get_snmpdata_by_deviceType(device_type):
    comma_list = SNMPData.query.filter_by(deviceType=device_type).all()
    arr = []
    for elem in comma_list:
        temp = str(elem).split(',')
        arr.append({
            "id":temp[0],
            "ip":temp[1],
            "name":temp[2],
            "deviceType":temp[3],
            "data":temp[4],
            "timestamp":temp[5]
        })
    return arr

def add_log(logType, logData, logIP):
    log = Logs(logType=logType, logData=logData, logIP=logIP)
    db.session.add(log)
    db.session.commit()

def add_snmpdata(ip, name, deviceType, data, timestamp):
    snmpdataaa = SNMPData(ip=ip, name=name, deviceType=deviceType, data=data, timestamp=timestamp)
    db.session.add(snmpdataaa)
    db.session.commit()

#print(get_logs())
