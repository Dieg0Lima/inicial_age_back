import sys
import paramiko
import time
import re
import json

def execute_ssh_command(host, username, password, command):
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(host, username=username, password=password, look_for_keys=False, allow_agent=False)
        
        shell = client.invoke_shell()
        time.sleep(1)
        shell.send(command + "\n")
        time.sleep(2)

        output = ''
        while True:
            if shell.recv_ready():
                data = shell.recv(1024).decode('utf-8')
                output += data
                if data.endswith('> ') or data.endswith('# '):  
                    break
            else:
                time.sleep(1)

        client.close()
        return output
    except Exception as e:
        print(f"Error executing SSH command: {e}", file=sys.stderr)
        return None

def check_pon_availability(host, username, password, slot, pon):
    command = f"show equipment ont status pon 1/1/{slot}/{pon}"
    output = execute_ssh_command(host, username, password, command)
    if output is None:
        print("Failed to retrieve data from OLT.", file=sys.stderr)
        return

    used_slots_data = re.findall(r'(1/1/(\d+)/(\d+)/(\d+))\s+ALCL:[A-F0-9]+', output)
    used_slots = [entry[0] for entry in used_slots_data]

    available_slots = []
    for port in range(1, 129):
        slot_path = f"1/1/{slot}/{pon}/{port}"
        if slot_path not in used_slots:
            available_slots.append({
                'slot': slot,
                'pon': pon,
                'port': str(port),
                'status': 'Disponivel'
            })

    return available_slots

if __name__ == "__main__":
    if len(sys.argv) < 6:
        print("Usage: python script.py <username> <password> <host> <slot> <pon>", file=sys.stderr)
        sys.exit(1)

    username = sys.argv[1]
    password = sys.argv[2]
    host = sys.argv[3]
    slot = sys.argv[4]
    pon = sys.argv[5]

    available_slots = check_pon_availability(host, username, password, slot, pon)
    if available_slots:
        print(json.dumps({"success": True, "response": available_slots}, indent=4))
    else:
        print("No available slots found or error in command execution.")
