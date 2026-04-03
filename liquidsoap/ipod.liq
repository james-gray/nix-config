%include "/etc/liquidsoap/common.liq"

let navidrome_url  = "https://ipod.jgray.me"
let navidrome_user = environment.get("ND_USER")
let navidrome_pass = environment.get("ND_PASS")
let icecast_pass = "supersecretpw"

def fetch_random_song() =
  auth = make_auth(navidrome_user, navidrome_pass)

  resp = http.get("#{navidrome_url}/rest/getRandomSongs.view?size=1#{auth}")

  song_id = parse_id_from_xml(resp, "song")

  if song_id == "" then
    log("ipod: failed to get random song")
    ""
  else
    log("ipod: fetched song id=#{song_id}")
    auth2 = make_auth(navidrome_user, navidrome_pass)
    "#{navidrome_url}/rest/stream.view?id=#{song_id}#{auth2}"
  end
end

def next_request() =
  url = fetch_random_song()
  if url == "" then
    null()
  else
    request.create(url)
  end
end

radio = request.dynamic(next_request)
radio = mksafe(radio)

output.icecast(
  %mp3(bitrate=192),
  host="icecast",
  port=8000,
  password=icecast_pass,
  mount="/ipod",
  name="iPod Radio",
  description="Random tracks from ipod.jgray.me",
  radio
)
