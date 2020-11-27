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


@app.route('/monitor/<ip>')
def monitor_ip(ip):
    r0 = requests.get(APISERVER+"/api/database/snmpdata/nameip/ifTable/"+ip)
    ifTable = json.loads(r0.text)
    
    displayed_data={}
    graph_data = {}
    graph_labels = []
    graph_max = 10

    old_inOctets = 0
    old_outOctets = 0
    old_speed = 0

    count = 0

    first = ""

    for elem in ifTable:
        data_array = elem['data'].split('_')

        try:
            inOctets = int(data_array[9])
            outOctets = int(data_array[15])
            speed = int(data_array[4])

            s = get_network_speed(old_inOctets, inOctets)

            if first != "":
                first = data_array[0]

            if data_array[0] in graph_data:
                graph_data[data_array[0]].append(s)
            else:
                graph_data[data_array[0]] = [s]

            if first == data_array[0]:
                graph_labels.append(count)
            
            if s > graph_max:
                graph_max = s*1.10

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

    return render_template('monitored_device.html', displayed_data=displayed_data, graph_data=graph_data, graph_labels=graph_labels, graph_max=graph_max)

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