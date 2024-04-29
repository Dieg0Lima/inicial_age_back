require "net/ssh"

module AttendantActions
  class ManagementService
    def management_onu(sernum)
      ip = fetch_management_ip(sernum)
      if ip
        { success: true, ip: ip }
      else
        { success: false, error: "Equipamento não encontrado." }
      end
    end

    private

    def fetch_management_ip(sernum)
      mikrotik_ips = ENV["MIKROTIK_IPS"]&.split(",") || []
      return nil if mikrotik_ips.empty?

      ssh_username = ENV["SSH_USERNAME"]
      ssh_password = ENV["SSH_PASSWORD"]
      command = "/ip dhcp-server lease print where agent-circuit-id=#{sernum}"

      queue = Queue.new
      threads = []

      mikrotik_ips.each do |ip|
        threads << Thread.new do
          begin
            Net::SSH.start(ip, ssh_username, password: ssh_password) do |ssh|
              output = ssh.exec!(command)
              ip_match = output.match(/\d+ D (\d+\.\d+\.\d+\.\d+)/)
              queue.push(ip_match[1]) if ip_match
            end
          rescue StandardError => e
            puts "Erro ao conectar ou executar o comando no equipamento #{ip}: #{e.message}"
          end
        end
      end

      threads.each(&:join)
      queue.empty? ? nil : queue.pop
    end
  end
end
