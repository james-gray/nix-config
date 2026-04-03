let navidrome_url  = environment.get("ND_URL")
let navidrome_user = environment.get("ND_USER")
let navidrome_pass = environment.get("ND_PASS")
let icecast_pass = "supersecretpw"

album_queue = ref([])

def make_auth() =
  salt  = string(int_of_float(time()))
  token = string.digest(navidrome_pass ^ salt)
  "&u=#{navidrome_user}&t=#{token}&s=#{salt}&v=1.16.1&c=liquidsoap"
end

def fetch_album_tracks() =
  auth = make_auth()

  album_resp = http.get("#{navidrome_url}/rest/getAlbumList2.view?type=random&size=1#{auth}")

  parts = string.split(separator='<album id="', album_resp)
  album_id_raw = list.nth(default="", parts, 1)
  parts2 = string.split(separator='"', album_id_raw)
  album_id = list.nth(default="", parts2, 0)

  if album_id == "" then
    log("radio: failed to parse album id from response")
    []
  else
    log("radio: fetched album id=#{album_id}")

    album_detail_resp = http.get("#{navidrome_url}/rest/getAlbum.view?id=#{album_id}#{auth}")

    parts = string.split(separator='<song id="', album_detail_resp)
    parts_tail = list.tl(parts)

    def extract_id(s) =
      parts_s = string.split(separator='"', s)
      list.nth(default="", parts_s, 0)
    end

    song_ids = list.map(extract_id, parts_tail)

    log("radio: album has #{list.length(song_ids)} tracks")

    auth2 = make_auth()

    def make_stream_url(id) =
      "#{navidrome_url}/rest/stream.view?id=#{id}#{auth2}"
    end

    list.map(make_stream_url, song_ids)
  end
end

def next_request() =
  queue = album_queue()

  if list.length(queue) == 0 then
    log("radio: queue empty, fetching new album")
    tracks = fetch_album_tracks()
    album_queue := tracks
    queue = tracks
  end

  if list.length(queue) > 0 then
    track = list.hd(default="", queue)
    album_queue := list.tl(queue)
    request.create(track)
  else
    null()
  end
end

radio = request.dynamic(next_request)
radio = mksafe(radio)

output.icecast(
  %mp3(bitrate=192),
  host="icecast",
  port=8000,
  password=icecast_pass,
  mount="/stream",
  name="jgray radio",
  description="Random albums from music.jgray.me",
  radio
)
