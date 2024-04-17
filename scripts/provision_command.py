import sys
import paramiko
import time
import re
import json

def execute_ssh_commands(host, username, password, commands):
    outputs = []
    try:
        print(f"Connecting to {host} via SSH...", file=sys.stderr)
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(host, username=username, password=password, look_for_keys=False, allow_agent=False)
        
        shell = client.invoke_shell()
        time.sleep(1)
        
        for command in commands:
            if shell.recv_ready():
                shell.recv(10000)
            
            print(f"Executing command: {command}", file=sys.stderr)
            shell.send(command + "\n")
            output = ''
            end_pattern = re.compile(r'-{80,}\s*\n(optics count : \d+\n)?-{80,}', re.MULTILINE)
            while True:
                if shell.recv_ready():
                    new_data = shell.recv(4096).decode('utf-8')
                    output += new_data
                    if end_pattern.search(output):
                        break
                else:
                    time.sleep(5)
                    if not shell.recv_ready():
                        break
            
            outputs.append(output)
        
        client.close()
        return True, outputs, ''
    except Exception as e:
        return False, [], str(e)

def configure_onu_commands(slot, pon, port, contract, sernum, vlan_id):
    commands = [
        f'configure equipment ont interface 1/1/{slot}/{pon}/{port} desc1 "{contract}" desc2 "-" sernum ALCL:{sernum} subslocid WILDCARD sw-ver-pland auto sw-dnload-version disabled',
        f'configure equipment ont interface 1/1/{slot}/{pon}/{port} admin-state up optics-hist enable pland-cfgfile1 auto pland-cfgfile2 auto dnload-cfgfile1 auto dnload-cfgfile2 auto',
        f'configure equipment ont slot 1/1/{slot}/{pon}/{port}/14 planned-card-type veip plndnumdataports 1 plndnumvoiceports 0',
        f'configure interface port uni:1/1/{slot}/{pon}/{port}/14/1 admin-up',
        f'configure qos interface 1/1/{slot}/{pon}/{port}/14/1 upstream-queue 0 bandwidth-profile name:HSI_1G_UP',
        f'configure bridge port 1/1/{slot}/{pon}/{port}/14/1 max-unicast-mac 4 max-committed-mac 1',
        f'configure bridge port 1/1/{slot}/{pon}/{port}/14/1 vlan-id 41 tag single-tagged l2fwder-vlan {vlan_id} vlan-scope local',
        f'configure bridge port 1/1/{slot}/{pon}/{port}/14/1 vlan-id {vlan_id} tag single-tagged'
    ]
    return commands

if __name__ == "__main__":
    if len(sys.argv) < 5:
        sys.stderr.write("Usage: python script.py <host> <username> <password> <slot> <pon> <port> <contract> <sernum> <vlan_id>\n")
        sys.exit(1)

    host = sys.argv[1]
    username = sys.argv[2]
    password = sys.argv[3]
    slot = sys.argv[4]
    pon = sys.argv[5]
    port = sys.argv[6]
    contract = sys.argv[7]
    sernum = sys.argv[8]
    vlan_id = sys.argv[9]

    commands = configure_onu_commands(slot, pon, port, contract, sernum, vlan_id)
    success, outputs, error = execute_ssh_commands(host, username, password, commands)

    if success:
        print("ONU configuration successful.")
    else:
        print(f"Failed to execute ONU configuration commands on {host}:", file=sys.stderr)
        print(error, file=sys.stderr)
