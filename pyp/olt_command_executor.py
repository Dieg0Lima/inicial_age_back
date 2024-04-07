import sys
import paramiko
import time

def execute_ssh_command(host, username, password, command):
    try:
        print(f"Connecting to {host} via SSH...")
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(host, username=username, password=password, look_for_keys=False, allow_agent=False)
        
        print("SSH connection established. Executing command...")
        shell = client.invoke_shell()
        shell.send(command + "\n")
        shell.send("exit\n")
        
        time.sleep(2)
        output = shell.recv(10000).decode('utf-8')
        
        client.close()
        return True, output, ''
    except Exception as e:
        return False, '', str(e)

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: python olt_command_executor.py <host> <username> <password> <command>")
        sys.exit(1)

    host = sys.argv[1]
    username = sys.argv[2]
    password = sys.argv[3]
    command = sys.argv[4]

    success, output, error = execute_ssh_command(host, username, password, command)

    if success:
        print("Command executed successfully:\n")
        print(output)
    else:
        print("Failed to execute command:")
        print(error)
