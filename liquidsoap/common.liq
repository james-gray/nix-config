# Common functions shared across all radio streams

def make_auth(user, pass) =
  salt  = string(int_of_float(time()))
  token = string.digest(pass ^ salt)
  "&u=#{user}&t=#{token}&s=#{salt}&v=1.16.1&c=liquidsoap"
end

def parse_id_from_xml(xml, tag_name) =
  parts = string.split(separator='<#{tag_name} id="', xml)
  id_raw = list.nth(default="", parts, 1)
  parts2 = string.split(separator='"', id_raw)
  list.nth(default="", parts2, 0)
end

def parse_all_ids_from_xml(xml, tag_name) =
  parts = string.split(separator='<#{tag_name} id="', xml)
  parts_tail = list.tl(parts)

  def extract_id(s) =
    parts_s = string.split(separator='"', s)
    list.nth(default="", parts_s, 0)
  end

  list.map(extract_id, parts_tail)
end
