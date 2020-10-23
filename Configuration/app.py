#! /usr/bin/python
# -*- coding:utf-8 -*-

from flask import Flask, render_template
from flask_restful import reqparse, abort, Resource, Api
import json

from Conf_Reader import Conf_Reader

app = Flask(__name__)
api = Api(app)

parser = reqparse.RequestParser()
parser.add_argument('ip')
parser.add_argument('community')
parser.add_argument('type')
parser.add_argument('new_ip')
parser.add_argument('new_community')

class DeviceList(Resource):
    def get(self):
        cf = Conf_Reader()
        data = cf.get_all()
        return data

    #Invoke-WebRequest -Uri 127.0.0.1:5000/api/devices -Method POST -Body @{'ip'='6.6.6.9';'community'='commu';'type'='switch'}
    def post(self):
        cf = Conf_Reader()
        args = parser.parse_args()

        cf.create_device(args['type'], args['ip'], args['community'])

        return {'type':args['type'], 'ip':args['ip'], 'community':args['community']}, 201

class Device(Resource):
    def get(self, device_ip):
            return {}

    #Invoke-WebRequest -Uri 127.0.0.1:5000/api/devices/3.3.3.4 -Method POST -Body @{'new_ip'='9.9.9.9';'community'='commu2';'new_community'='commu';'type'='switch'}
    def post(self, device_ip):
        cf = Conf_Reader()
        args = parser.parse_args()
        cf.edit_device(args['type'], args['new_ip'], device_ip, args['new_community'], args['community'])

        return {'type':args['type'], 'ip':args['new_ip'], 'community':args['new_community']}, 200

    def delete(self, device_ip): #TODO
        cf = Conf_Reader()
        cf.delete_device(device_ip)

        return "DELETED", 200

api.add_resource(DeviceList, '/api/devices') #get=list post=create
api.add_resource(Device, '/api/devices/<device_ip>') #put/patch update delete=remove

if __name__ == '__main__':
    app.run(debug=True)