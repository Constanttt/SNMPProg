from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import json

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///bdd.db'
db = SQLAlchemy(app)

class SNMPData(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    ip = db.Column(db.String(255), unique=False, nullable=False)
    name = db.Column(db.String(255), unique=False, nullable=False)
    deviceType = db.Column(db.String(255), nullable=True)
    data = db.Column(db.String, nullable = False)
    timestamp = db.Column(db.String, nullable = False)

    def __repr__(self):
        single_data = str(self.id) + ',' + str(self.ip) + ',' + str(self.name) + ',' + str(self.deviceType) + ',' + str(self.data) + ',' + str(self.timestamp)
        return single_data

class Logs(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    logType = db.Column(db.String(255), nullable=False)
    logData = db.Column(db.String, nullable=False)
    logIP = db.Column(db.String(255), nullable=False)

    def __repr__(self):
        #log = { "id" : self.id, "logType" : self.logType, "logData" : self.logData, "logIP" : self.logIP }
        log = str(self.id) + ',' + str(self.logType) + ',' + str(self.logData) + ',' + str(self.logIP)
        return log

#db.create_all()