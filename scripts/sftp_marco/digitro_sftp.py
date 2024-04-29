import paramiko

hostname = "10.25.3.155"
username = "rpa"
password = "!@Systemof@down"
remote_file_path = "/var/digitro/2039_30602.txt"
local_file_path = "2039_30602.txt"

transport = paramiko.Transport((hostname, 22))

try:
    transport.connect(username=username, password=password)

    sftp = paramiko.SFTPClient.from_transport(transport)

    sftp.get(remote_file_path, local_file_path)
    print(f"Arquivo baixado com sucesso para {local_file_path}")

except paramiko.SSHException as e:
    print(f"Erro de conexão SSH: {e}")
except FileNotFoundError as e:
    print(f"Erro de arquivo não encontrado: {e}")
except Exception as e:
    print(f"Ocorreu um erro: {e}")
finally:
    if sftp: sftp.close()
    if transport: transport.close()
