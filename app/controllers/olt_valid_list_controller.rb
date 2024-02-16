class OltValidListController < ApplicationController
  def valid_olts
    if params[:id].present?
      valid_olt_by_id = AuthenticationAccessPoint
                        .where(id: params[:id])
                        .where("title LIKE ?", "BSA%")
                        .where.not(title: ["BSA.SAMB.OLT.01-TESTE", "BSA.ASUL.OLT.02 - TESTE ZTE", "BSA.ASUL.RTC.01 - PPPoE (Temporário)"])
                        .select('id, title AS olt_name')
                        .first

      if valid_olt_by_id
        render json: valid_olt_by_id
      else
        render json: { error: "Nenhuma OLT válida encontrada com o ID fornecido." }, status: :not_found
      end
    else
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
end
