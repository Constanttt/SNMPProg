import xml.etree.ElementTree as ET
from xml.etree.ElementTree import Element

class Conf_Reader:

    def __init__(self):
        self.tree = ET.parse('config.xml')
        self.config = self.tree.getroot()

    def get_all(self):
        devices = []
        for config_type in self.config:
            for device in config_type:
                d = device.attrib
                d.update({'type':config_type.tag})
                devices.append(d)
        return devices

    def get_one(self, ip):
        device_to_return = []
        for config_type in self.config:
            for device in config_type:
                d = device.attrib
                d.update({'type':config_type.tag})
                if d['ip'] == ip:
                    device_to_return.append(d)
        return device_to_return

    def get_switch(self):
        for switch in self.config.findall("switch"):
            for device in switch:
                print(device.attrib)

    def get_router(self):
        for router in self.config.findall("router"):
            for device in router:
                print(device.attrib)

    def create_device_v2(self, device_type, device_ip, device_community, version):
        for t in self.config.findall(device_type):
            new_device = ET.Element("device")
            
            new_device.set("ip", device_ip)
            new_device.set("community", device_community)
            new_device.set("version", version)
            t.append(new_device)
            #ET.indent(t, space="    ", level=2)

        self.tree.write('config.xml')

    def create_device_v3(self, device_type, device_ip, version, username, password, protocol, protocolprivacy, passwordprivacy):
        for t in self.config.findall(device_type):
            new_device = ET.Element("device")
            
            new_device.set("ip", device_ip)
            new_device.set("version", version)
            new_device.set("username", username)
            new_device.set("password", password)
            new_device.set("protocol", protocol)
            new_device.set("protocolprivacy", protocolprivacy)
            new_device.set("passwordprivacy", passwordprivacy)
            t.append(new_device)
            #ET.indent(t, space="    ", level=2)

        self.tree.write('config.xml')

    def delete_device(self, device_ip):
        for config_type in self.config:
            for device in config_type:
                if device.attrib['ip'] == device_ip:
                    config_type.remove(device)
        self.tree.write('config.xml')

    def edit_device_v2(self, device_type, new_device_ip, old_device_ip, new_device_community):
        for t in self.config.findall(device_type):
            for device in t.findall('device'):
                if device.attrib['ip'] == old_device_ip:
                    device.set('ip', new_device_ip)
                    device.set('community', new_device_community)
        self.tree.write('config.xml')

    def edit_device_v3(self, device_type, new_device_ip, old_device_ip, username, password, protocol, protocolprivacy, passwordprivacy):
        for t in self.config.findall(device_type):
            for device in t.findall('device'):
                if device.attrib['ip'] == old_device_ip:
                    device.set('ip', new_device_ip)
                    device.set('username', username)
                    device.set('password', password)
                    device.set('protocol', protocol)
                    device.set('protocolprivacy', protocolprivacy)
                    device.set('passwordprivacy', passwordprivacy)
        self.tree.write('config.xml')
