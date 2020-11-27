from flask import Flask, render_template, request

import requests, json

app = Flask(__name__)

APISERVER = 'http://127.0.0.1:5000'

@app.route('/')
def index():
    r0 = requests.get(APISERVER+"/api/devices")
    device_list = json.loads(r0.text)

    r1 = requests.get(APISERVER+"/api/database/logs/all")
    logs = json.loads(r1.text)

    return render_template('index.html',device_list=device_list, logs=logs)


@app.route('/monitor/<ip>')
def monitor_ip(ip):
    r = requests.get(APISERVER+"/api/database/snmpdata/ip/"+ip)
    data = json.loads(r.text)

    return render_template('monitored_device.html', data=data)


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)