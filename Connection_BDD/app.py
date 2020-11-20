from flask import Flask, render_template
from flask_restful import reqparse, abort, Resource, Api
import json

from flask import Flask, render_template, jsonify
from flask_sqlalchemy import SQLAlchemy

from connectBDD import *

app = Flask(__name__)
api = Api(app)

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///bdd.db'
db = SQLAlchemy(app)

parser = reqparse.RequestParser()
#Get arguments
parser.add_argument('value')
#Post arguments
parser.add_argument('logType')
parser.add_argument('logData')
parser.add_argument('logIP')
parser.add_argument('ip')
parser.add_argument('name')
parser.add_argument('deviceType')
parser.add_argument('data')
parser.add_argument('timestamp')

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

api.add_resource(Logs_all, '/api/database/logs/all') #post, get
api.add_resource(Logs_ip, '/api/database/logs/ip/<value>') #get
api.add_resource(Logs_type, '/api/database/logs/type/<value>') #get

api.add_resource(SNMPData_all, '/api/database/snmpdata/all') #post, get
api.add_resource(SNMPData_ip, '/api/database/snmpdata/ip/<value>') #get
api.add_resource(SNMPData_name, '/api/database/snmpdata/name/<value>') #get
api.add_resource(SNMPData_deviceType, '/api/database/snmpdata/deviceType/<value>') #get


if __name__ == '__main__':
    app.run(debug=True)