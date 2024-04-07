require "axlsx"

module OltAnalytics
  class OltAnalyticsService
    def self.fetch_data_to_xlsx(file_name = "output.json")
      output_path = Rails.root.join("scripts", file_name)
      file_content = File.read(output_path)
      data = JSON.parse(file_content)

      ips = data.keys
      authentication_ips = AuthenticationIp.includes(:authentication_access_points).where(ip: ips).index_by(&:ip)

      p = Axlsx::Package.new
      wb = p.workbook

      wb.add_worksheet(name: "Dados OLT") do |sheet|
        sheet.add_row ["Título da OLT", "ont_idx", "rx_signal_level", "tx_signal_level", "temperature", "ont_voltage", "bias_current", "olt_rx_sig_level", "sernum", "admin_status", "oper_status", "ont_olt_distance", "desc1", "desc2", "hostname"]

        data.each do |ip, entries|
          title = authentication_ips[ip]&.authentication_access_points&.first&.title || "Desconhecido"

          entries.each do |entry|
            sheet.add_row [title, *entry.values]
          end
        end
      end

      xlsx_file_path = Rails.root.join("scripts", "dados_olt.xlsx")
      p.serialize(xlsx_file_path.to_s)

      { success: true, file_path: xlsx_file_path.to_s }
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end
end
