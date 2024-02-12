class OltValidListController < ApplicationController
    def valid_olts
        valid_olts = AuthenticationAccessPoint
                       .select('id, title AS olt_name')
                       .where("title LIKE ?", "BSA%")
                       .where.not(title: ["BSA.SAMB.OLT.01-TESTE", "BSA.ASUL.OLT.02 - TESTE ZTE", "BSA.ASUL.RTC.01 - PPPoE (Temporário)"])
                       .order("title")

        if valid_olts.exists?
          render json: valid_olts
        else
          render json: { error: "Nenhum título de OLT encontrado." }, status: :not_found
        end
    end
end
