require "net/sftp"

hostname = "10.25.3.155"
username = "rpa"
password = "!@Systemof@down"
remote_file_path = "/var/digitro/2039_30602.txt"  # Caminho correto do arquivo
local_file_path = "2039_30602.txt"  # Local onde o arquivo será salvo

begin
  Net::SFTP.start(hostname, username, password: password) do |sftp|
    sftp.download!(remote_file_path, local_file_path)
  end
  puts "Arquivo baixado com sucesso para #{local_file_path}"
rescue StandardError => e
  puts "Erro ao baixar o arquivo: #{e.message}"
end
