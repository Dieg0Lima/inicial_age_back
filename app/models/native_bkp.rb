class NativeBkp < NativeDataBase
  self.table_name = "native.native_bkp"
end

results = NativeBkp.select(:start, :clid, :src, :dst, :uniqueid)
