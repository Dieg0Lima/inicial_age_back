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
            shell.settimeout(5.0)
            
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

def parse_optics_data(output):
    data = []
    pattern = re.compile(r'(?P<ont_idx>\d+/\d+/\d+/\d+/\d+)\s+(?P<rx_signal_level>-?\d*\.?\d+|unknown)\s+(?P<tx_signal_level>-?\d*\.?\d+|unknown)\s+(?P<temperature>-?\d*\.?\d+|unknown)\s+(?P<ont_voltage>-?\d*\.?\d+|unknown)\s+(?P<bias_current>-?\d*\.?\d+|unknown)\s+(?P<olt_rx_sig_level>-?\d*\.?\d+|invalid)')
    for match in pattern.finditer(output):
        data.append(match.groupdict())
    return data

def parse_pon_data(output):
    data = []
    pattern = re.compile(
        r'^\d+/\d+/\d+/\d+\s+'  
        r'(?P<ont_idx>\d+/\d+/\d+/\d+/\d+)\s+'  
        r'(?P<sernum>ALCL:[A-Z0-9]+)\s+'
        r'(?P<admin_status>\w+)\s+'
        r'(?P<oper_status>\w+)\s+'
        r'(?P<olt_rx_sig_level>-?\d*\.?\d+|invalid)\s+'
        r'(?P<ont_olt_distance>-?\d*\.?\d+|unknown)\s+'
        r'(?P<desc1>\S*)\s+'  
        r'(?P<desc2>\S*)\s+'  
        r'(?P<hostname>\S+)', 
        re.MULTILINE)
    for match in pattern.finditer(output):
        data.append(match.groupdict())
    return data

def merge_data(optics_data, pon_data):
    pon_dict = {item['ont_idx']: item for item in pon_data}
    
    merged_data = []
    for entry in optics_data:
        ont_idx = entry['ont_idx']
        if ont_idx in pon_dict:
            merged_entry = {**entry, **pon_dict[ont_idx]}
            merged_data.append(merged_entry)
        else:
            merged_data.append(entry)
    
    optics_idx_set = set(item['ont_idx'] for item in optics_data)
    for ont_idx, pon_entry in pon_dict.items():
        if ont_idx not in optics_idx_set:
            merged_data.append(pon_entry)
    
    return merged_data

def save_to_json_file(data, file_path):
    with open(file_path, 'w') as json_file:
        json.dump(data, json_file, indent=4)

if __name__ == "__main__":
    if len(sys.argv) < 5:
        sys.stderr.write("Usage: python script.py <username> <password> <host1> <host2> ...\n")
        sys.exit(1)

    username = sys.argv[1]
    password = sys.argv[2]
    hosts = sys.argv[3:]
    all_data_by_ip = {}  

    for host in hosts:
        commands = ["environment inhibit-alarms", "show equipment ont optics", "show equipment ont status pon"]
        success, outputs, error = execute_ssh_commands(host, username, password, commands)

        if success:
            optics_data = parse_optics_data(outputs[1])
            pon_data = parse_pon_data(outputs[2])
            merged_data = merge_data(optics_data, pon_data)
            all_data_by_ip[host] = merged_data 
        else:
            print(f"Failed to execute commands on {host}:", file=sys.stderr)
            print(error, file=sys.stderr)

    save_to_json_file(all_data_by_ip, 'output.json')  
    print("Dados de todas as OLTs salvos em output.json, organizados por IP")
