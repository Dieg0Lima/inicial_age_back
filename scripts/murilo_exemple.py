import paramiko
import getpass
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
    print("OLT SSH Command Executor")
    host = input("Enter OLT IP Address: ")
    username = input("Enter username (isadmin): ") or "isadmin"
    password = getpass.getpass("Enter password: ")
    command = input("Enter command to execute: ") or "echo 'Test'"

    success, output, error = execute_ssh_command(host, username, password, command)

    if success:
        print("Command executed successfully:\n")
        print(output)
    else:
        print("Failed to execute command:")
        print(error)
