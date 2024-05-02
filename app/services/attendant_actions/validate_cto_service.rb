module AttendantActions
  class ValidateCtoService
    include HTTParty
    base_uri "https://agetelecom.ozmap.com.br:9994/api/v2/"

    def self.validate_cto(cto)
      options = {
        headers: {
          "Authorization" => "Bearer #{ENV["API_OZMAP_TOKEN"]}",
          "Content-Type" => "application/json",
        },
        query: {
          filter: '[{"property":"name","value":"' + cto + '","operator":"="}]',
          select: "name",
        },
      }

      response = get("/boxes", options)
      if response.success?
        data = response.parsed_response
        if data["total"] > 0
          { success: true, message: "CTO validada com sucesso.", isValid: true, data: data["rows"].first }
        else
          { success: false, error: "CTO não encontrada.", isValid: false, cto: cto }
        end
      else
        { success: false, error: "Erro ao validar CTO: #{response.message}", isValid: false, cto: cto }
      end
    rescue HTTParty::Error => e
      { success: false, error: "Erro na requisição: #{e.message}", isValid: false, cto: cto }
    rescue StandardError => e
      { success: false, error: "Erro desconhecido: #{e.message}", isValid: false, cto: cto }
    end
  end
end
