from flask import Flask, render_template, request
from flask_restful import reqparse, abort, Resource, Api
import json

from flask import Flask, render_template, jsonify
from flask_sqlalchemy import SQLAlchemy

from lib.connectBDD import *
from lib.Conf_Reader import Conf_Reader

app = Flask(__name__)
api = Api(app)

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///bdd.db'
db = SQLAlchemy(app)

parser = reqparse.RequestParser()
#Get arguments for connectBDD
parser.add_argument('value')
#Post arguments for connectBDD
parser.add_argument('logType')
parser.add_argument('logData')
parser.add_argument('logIP')
parser.add_argument('name')
parser.add_argument('deviceType')
parser.add_argument('data')
parser.add_argument('timestamp')

#Post arguments for many things
parser.add_argument('ip')

#Post arguments for configuration
parser.add_argument('community')
parser.add_argument('type')
parser.add_argument('new_ip')
parser.add_argument('version')
parser.add_argument('username')
parser.add_argument('password')
parser.add_argument('protocol')
parser.add_argument('protocolprivacy')
parser.add_argument('passwordprivacy')

#Invoke-WebRequest -Uri 127.0.0.1:5000/api/database/logs/all
#Invoke-WebRequest -Uri 127.0.0.1:5000/api/database/logs/all -Method POST -Body @{"logType"='test'; "logData"='testData'; "logIP"='6.6.6.6'}
class Logs_all(Resource):
    def get(self):
        data = get_logs()
        print(data)
        return data

    def post(self):
        args = parser.parse_args()
        add_log(args['logType'], args['logData'], args['logIP'])
        return {'logType':args['logType'], 'logData':args['logData'], 'logIP':args['logIP']}, 201

#Invoke-WebRequest -Uri 127.0.0.1:5000/api/database/logs/ip/6.6.6.6
class Logs_ip(Resource):
    def get(self, value):
        data = get_logs_by_ip(value)
        return data

#Invoke-WebRequest -Uri 127.0.0.1:5000/api/database/logs/type/test
class Logs_type(Resource):
    def get(self, value):
        data = get_logs_by_type(value)
        return data

#Invoke-WebRequest -Uri 127.0.0.1:5000/api/database/snmpdata/all
#Invoke-WebRequest -Uri 127.0.0.1:5000/api/database/snmpdata/all -Method POST -Body @{"ip"="4.4.4.4";"name"="un.oid.a.la.con";"deviceType"="Router";"data"="des data de test";"timestamp"="20/11/2020 18:41"}
class SNMPData_all(Resource):
    def get(self):
        data = get_snmpdata()
        return data

    def post(self):
        args = parser.parse_args()
        add_snmpdata(args['ip'], args['name'], args['deviceType'], args['data'], args['timestamp'])
        return {'ip':args['ip'], 'name':args['name'], 'deviceType':args['deviceType'], 'data':args['data'], 'timestamp':args['timestamp']}, 201

#Invoke-WebRequest -Uri http://127.0.0.1:5000/api/database/snmpdata/ip/6.6.6.6
class SNMPData_ip(Resource):
    def get(self, value):
        data = get_snmpdata_by_ip(value)
        return data

#Invoke-WebRequest -Uri http://127.0.0.1:5000/api/database/snmpdata/name/un.oid.a.la.con
class SNMPData_name(Resource):
    def get(self, value):
        data = get_snmpdata_by_name(value)
        return data

#Invoke-WebRequest -Uri 127.0.0.1:5000/api/database/snmpdata/deviceType/Router
class SNMPData_deviceType(Resource):
    def get(self, value):
        data = get_snmpdata_by_deviceType(value)
        return data

class SNMPData_nameip(Resource):
    def get(self, name, ip):
        data = get_snmpdata_by_name_and_ip(name, ip)
        return data

class DeviceList(Resource):
    def get(self):
        cf = Conf_Reader()
        data = cf.get_all()
        return data

    #Invoke-WebRequest -Uri 127.0.0.1:5000/api/devices -Method POST -Body @{'ip'='6.6.6.9';'community'='commu';'type'='switch'}
    def post(self):
        cf = Conf_Reader()
        args = parser.parse_args()

        print(args)

        if args['version'] == '2':
            cf.create_device_v2(args['type'], args['ip'], args['community'], args['version'])
            return {'type':args['type'], 'ip':args['ip'], 'community':args['community']}, 201
            
        elif args['version'] == '3':
            cf.create_device_v3(args['type'], args['ip'], args['version'], args['username'], args['password'], args['protocol'], args['protocolprivacy'], args['passwordprivacy'])
            return {'type':args['type'], 'ip':args['ip'], 'community':args['community']}, 201

        return {}, 400

class Device(Resource):
    def get(self, device_ip):
        cf = Conf_Reader()
        data = cf.get_one(device_ip)
        return data

    #Invoke-WebRequest -Uri 127.0.0.1:5000/api/devices/3.3.3.4 -Method POST -Body @{'new_ip'='9.9.9.9';'community'='commu2';'new_community'='commu';'type'='switch'}
    def post(self, device_ip):
        cf = Conf_Reader()
        args = parser.parse_args()

        if args['version'] == '2':
            cf.edit_device_v2(args['type'],args['ip'], device_ip, args['community'])
            return {'type':args['type'], 'ip':args['ip'], 'old_ip':device_ip, 'community':args['community']}, 200

        elif args['version'] == '3':
            cf.edit_device_v3(args['type'], args['ip'], device_ip, args['username'], args['password'], args['protocol'], args['protocolprivacy'], args['passwordprivacy'])
            return {'type':args['type'], 'ip':args['ip'], 'old_ip':device_ip, 'version':args['version'], 'username':args['username'], 'password':args['password'], 'protocol':args['protocol'], 'protocolprivacy':args['protocolprivacy'], 'passwordprivacy':args['passwordprivacy']}, 200

        return {}, 400

    def delete(self, device_ip): 
        cf = Conf_Reader()
        cf.delete_device(device_ip)

        return "DELETED", 200

api.add_resource(Logs_all, '/api/database/logs/all') #post, get
api.add_resource(Logs_ip, '/api/database/logs/ip/<value>') #get
api.add_resource(Logs_type, '/api/database/logs/type/<value>') #get

api.add_resource(SNMPData_all, '/api/database/snmpdata/all') #post, get
api.add_resource(SNMPData_ip, '/api/database/snmpdata/ip/<value>') #get
api.add_resource(SNMPData_name, '/api/database/snmpdata/name/<value>') #get
api.add_resource(SNMPData_deviceType, '/api/database/snmpdata/deviceType/<value>') #get
api.add_resource(SNMPData_nameip, '/api/database/snmpdata/nameip/<name>/<ip>') #get

api.add_resource(DeviceList, '/api/devices') #get=list post=create
api.add_resource(Device, '/api/devices/<device_ip>') #put/patch update delete=remove

if __name__ == '__main__':
    app.run(debug=True, host= '0.0.0.0')