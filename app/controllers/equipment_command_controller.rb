class EquipmentCommandController < ApplicationController
  include HTTParty
  base_uri 'http://192.168.69.80:3000'

  def execute_command
    command = params[:command]
    case command
    when 'unprovision_list'
      unprovision_list
    when 'availability_pon'
      availability_pon
    when 'provision_onu'
      provision_onu
    when 'comando2'
      comando2
    else
      render json: { error: "Comando não reconhecido: #{command}" }, status: :bad_request
    end
  end

  private

  def unprovision_list
    ip = fetch_ip_from_olt_id(params[:id])
    return unless ip

    post_response = post_olt_command(ip, "show pon unprovision-onu")
    handle_post_response(post_response) do |body|
      data = body.scan(/(\d+)\s+1\/1\/(\d+)\/(\d+)\s+([A-Z0-9]+)/).reject { |match| match.empty? }
      structured_data = data.map do |alarm_idx, slot, pon, serial|
        {
          path: "1/1/#{slot}/#{pon}",
          slot: slot,
          pon: pon,
          serial: serial,
          status: 'Unprovisioned'
        }
      end
      render json: { success: true, response: structured_data }
    end
  end

  def availability_pon
    ip = fetch_ip_from_olt_id(params[:id])
    return unless ip

    slot = params[:slot]
    pon = params[:pon]
    post_response = post_olt_command(ip, "show equipment ont status pon 1/1/#{slot}/#{pon}")
    handle_post_response(post_response) do |body|
      used_slots_data = body.scan(/(1\/1\/(\d+)\/(\d+)\/(\d+))\s+ALCL:[A-F0-9]+/)
      used_slots = used_slots_data.map { |entry| entry[0] }

      available_slots = (1..128).map do |port|
        slot_path = "1/1/#{slot}/#{pon}/#{port}"
        unless used_slots.include?(slot_path)
          {
            slot: slot,
            pon: pon,
            port: port.to_s,
            status: 'Disponivel'
          }
        end
      end.compact

      render json: { success: true, response: available_slots }
    end
  end

  def provision_onu
    ip = fetch_ip_from_olt_id(params[:id])
    return unless ip

    vlan_id = fetch_vlan_id(ip)
    return render_error("Nenhuma VLAN IPoE correspondente encontrada.", :not_found) if vlan_id.nil?

    adjusted_sernum = params[:sernum]&.sub(/^ALCL/, '')

    if configure_onu(ip, params.slice(:slot, :pon, :port, :contract, :vlan_id).merge(sernum: adjusted_sernum, vlan_id: vlan_id))
      render json: { success: true }, status: :ok
    else
      render_error("Erro ao executar o comando na OLT.", :bad_request)
    end
  end


  def fetch_ip_from_olt_id(olt_id)
    response = self.class.get("/equipamento/#{olt_id}")
    if response.success?
      JSON.parse(response.body)['ip']
    else
      render json: { error: "Erro ao obter o IP do equipamento." }, status: :bad_request
      nil
    end
  end

  def post_olt_command(ip, command)
    self.class.post("/olt_command/", body: { ip: ip, command: command })
  end

  def handle_post_response(response)
    if response.success?
      yield(response.body)
    else
      render json: { error: "Erro ao executar o comando na OLT." }, status: :bad_request
    end
  end

  def fetch_vlan_id(ip)
    get_vlan = post_olt_command(ip, "configure vlan\ninfo")
    if get_vlan.success?
      vlan_info = get_vlan.body
      extract_vlan_id(vlan_info)
    else
      nil
    end
  end

  def extract_vlan_id(vlan_info)
    vlan_info.each_line do |line|
      next unless line.include?('name IPoE')
      vlan_id_match = line.match(/id (\d{4}) mode residential-bridge/)
      return vlan_id_match[1] if vlan_id_match
    end
    nil
  end

  def configure_onu(ip, params)
    slot, pon, port, contract, sernum, vlan_id = params.values_at(:slot, :pon, :port, :contract, :sernum, :vlan_id)
    command = <<-COMMAND
  configure equipment ont interface 1/1/#{slot}/#{pon}/#{port} desc1 "#{contract}" desc2 "-" sernum ALCL:#{sernum} subslocid WILDCARD sw-ver-pland auto sw-dnload-version disabled
  configure equipment ont interface 1/1/#{slot}/#{pon}/#{port} admin-state up optics-hist enable pland-cfgfile1 auto pland-cfgfile2 auto dnload-cfgfile1 auto dnload-cfgfile2 auto
  configure equipment ont slot 1/1/#{slot}/#{pon}/#{port}/14 planned-card-type veip plndnumdataports 1 plndnumvoiceports 0
  configure interface port uni:1/1/#{slot}/#{pon}/#{port}/14/1 admin-up
  configure qos interface 1/1/#{slot}/#{pon}/#{port}/14/1 upstream-queue 0 bandwidth-profile name:HSI_1G_UP
  configure bridge port 1/1/#{slot}/#{pon}/#{port}/14/1 max-unicast-mac 4 max-committed-mac 1
  configure bridge port 1/1/#{slot}/#{pon}/#{port}/14/1 vlan-id 41 tag single-tagged l2fwder-vlan #{vlan_id} vlan-scope local
  configure bridge port 1/1/#{slot}/#{pon}/#{port}/14/1 vlan-id #{vlan_id} tag single-tagged
    COMMAND
    post_response = post_olt_command(ip, command)
    post_response.success?
  end

  def render_error(message, status = :internal_server_error)
    render json: { error: message }, status: status
  end
end
