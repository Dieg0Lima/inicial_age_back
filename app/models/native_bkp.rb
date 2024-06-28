class NativeBkp < NativeDataBase
  self.table_name = "native.native_bkp"

  def self.search(params)
    native_bkps = NativeBkp.all
    if params[:start].present? && params[:end].present?
      start_date = Date.parse(params[:start])
      end_date = Date.parse(params[:end])
      native_bkps = native_bkps.where(start: start_date.beginning_of_day..end_date.end_of_day)
    elsif params[:start].present?
      date = Date.parse(params[:start])
      native_bkps = native_bkps.where(start: date.all_day)
    end
    native_bkps
  end
end
