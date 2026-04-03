%include "/etc/liquidsoap/common.liq"

let navidrome_url  = "https://music.jgray.me"
let navidrome_user = environment.get("ND_USER")
let navidrome_pass = environment.get("ND_PASS")
let icecast_pass = "supersecretpw"

album_queue = ref([])

def fetch_album_tracks() =
  auth = make_auth(navidrome_user, navidrome_pass)

  album_resp = http.get("#{navidrome_url}/rest/getAlbumList2.view?type=random&size=1#{auth}")

  album_id = parse_id_from_xml(album_resp, "album")

  if album_id == "" then
    log("music: failed to parse album id from response")
    []
  else
    log("music: fetched album id=#{album_id}")

    album_detail_resp = http.get("#{navidrome_url}/rest/getAlbum.view?id=#{album_id}#{auth}")

    song_ids = parse_all_ids_from_xml(album_detail_resp, "song")

    log("music: album has #{list.length(song_ids)} tracks")

    auth2 = make_auth(navidrome_user, navidrome_pass)

    def make_stream_url(id) =
      "#{navidrome_url}/rest/stream.view?id=#{id}#{auth2}"
    end

    list.map(make_stream_url, song_ids)
  end
end

def next_request() =
  queue = album_queue()

  if list.length(queue) == 0 then
    log("music: queue empty, fetching new album")
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
  mount="/music",
  name="Music Radio",
  description="Random albums from music.jgray.me",
  radio
)
