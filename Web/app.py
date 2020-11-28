from flask import Flask, render_template, request

import requests, json

app = Flask(__name__)

APISERVER = 'http://127.0.0.1:5000'
INTERVAL = 15*60

@app.route('/')
def index():
    r0 = requests.get(APISERVER+"/api/devices")
    device_list = json.loads(r0.text)

    r1 = requests.get(APISERVER+"/api/database/logs/all")
    logs = json.loads(r1.text)

    return render_template('index.html',device_list=device_list, logs=logs)

@app.route('/configure')
def configure():
    r = requests.get(APISERVER+"/api/devices")
    device_list = json.loads(r.text)

    return render_template('configure.html',device_list=device_list)

@app.route('/configure/edit/<ip>')
def configure_edit(ip):
    r = requests.get(APISERVER+"/api/devices/"+ip)
    device = json.loads(r.text)

    return render_template('edit_device.html',device=device[0])

@app.route('/configure/create')
def configure_create():
    return render_template('create_device.html')

@app.route('/configure/delete/<ip>')
def configure_delete(ip):
    r = requests.delete(APISERVER+"/api/devices/"+ip)

    r = requests.get(APISERVER+"/api/devices")
    device_list = json.loads(r.text)

    return render_template('configure.html',device_list=device_list)

@app.route('/configure/creation', methods = ['POST', 'GET'])
def configure_creation():
    if request.method == 'GET':
        return "Nope"
    if request.method == 'POST':
        form_data = request.form
        if form_data['version'] == '2':
            payload = {
                'version':form_data['version'],
                'ip':form_data['ip'],
                'type':form_data['type'],
                'community':form_data['community'],
                }
            r = requests.post(APISERVER+"/api/devices", data=payload)
        if form_data['version'] == '3':
            payload = {
                'version':form_data['version'],
                'ip':form_data['ip'],
                'type':form_data['type'],
                'username':form_data['username'],
                'password':form_data['password'],
                'protocol':form_data['protocol'],
                'protocolprivacy':form_data['protocolprivacy'],
                'passwordprivacy':form_data['passwordprivacy']
                }
            r = requests.post(APISERVER+"/api/devices", data=payload)

    r = requests.get(APISERVER+"/api/devices")
    device_list = json.loads(r.text)

    return render_template('configure.html',device_list=device_list)

@app.route('/configure/edition', methods = ['POST', 'GET'])
def configure_edition():
    if request.method == 'GET':
        return "Nope"
    if request.method == 'POST':
        form_data = request.form
        if form_data['version'] == '2':
            payload = {
                'version':form_data['version'],
                'ip':form_data['ip'],
                'type':form_data['type'],
                'community':form_data['community'],
                }
            r = requests.post(APISERVER+"/api/devices/"+form_data['old_ip'], data=payload)
        if form_data['version'] == '3':
            payload = {
                'version':form_data['version'],
                'ip':form_data['ip'],
                'type':form_data['type'],
                'username':form_data['username'],
                'password':form_data['password'],
                'protocol':form_data['protocol'],
                'protocolprivacy':form_data['protocolprivacy'],
                'passwordprivacy':form_data['passwordprivacy']
                }
            r = requests.post(APISERVER+"/api/devices/"+form_data['old_ip'], data=payload)

    r = requests.get(APISERVER+"/api/devices")
    device_list = json.loads(r.text)

    return render_template('configure.html',device_list=device_list)

@app.route('/monitor/<ip>')
def monitor_ip(ip):
    r0 = requests.get(APISERVER+"/api/database/snmpdata/nameip/ifTable/"+ip)
    ifTable = json.loads(r0.text)
    
    displayed_data={}
    graph_data = {}

    old_inOctets = 0
    old_outOctets = 0
    old_speed = 0

    for elem in ifTable:
        data_array = elem['data'].split('_')

        try:
            inOctets = int(data_array[9])
            outOctets = int(data_array[15])
            speed = int(data_array[4])

            s = get_network_speed(old_inOctets, inOctets)

            if data_array[0] in graph_data:
                graph_data[data_array[0]].append(s)
            else:
                graph_data[data_array[0]] = [s]

            displayed_data[data_array[0]] = {
                'IfIndex':data_array[0],
                'OperStatus':data_array[7],
                'AdminStatus':data_array[6],
                'InOctets':inOctets,
                'InDiscards':data_array[12],
                'InErrors':data_array[13],
                'OutOctets':outOctets,
                'OutDiscards':data_array[18],
                'OutErrors':data_array[19],
                'Descr':data_array[1],
                'Type':data_array[2],
                'Mtu':data_array[3],
                'Speed':speed,
                'PhysAddress':data_array[5],
                'LastChange':data_array[8],
                'linkUsage':get_link_usage(inOctets, old_inOctets, outOctets, old_outOctets, speed),
                'timestamp':elem['timestamp']
            }

            old_inOctets = inOctets
            old_outOctets = outOctets
        except:
            print('error while parsing ifTable for display')

    return render_template('monitored_device.html', displayed_data=displayed_data, graph_data=graph_data, ip=ip)

def get_link_usage(inOctet, old_inOctets, outOctets, old_outOctets, ifSpeed):
    diff_inOctet = inOctet - old_inOctets
    diff_outOctets = outOctets - old_outOctets
    return ((diff_inOctet + diff_outOctets) * 8 * 100) / (INTERVAL * ifSpeed)

def get_network_speed(old, new):
    if old == 0:
        return 0
    
    speed = (new - old) / INTERVAL

    if speed < 0:
        speed = (old - new) / INTERVAL

    return speed

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)