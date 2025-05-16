let
  jamesgray = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCUTk867B3q6XHs07I/C5UdhhR58GF6hyq3QtKTSAOn3k3LO6F4F6DNgbBm1NO2pKb2V39UBq0AokYlHAOsMzasA3jg98blsX4uqqx3K/8s3Q7Lbpga5nX04ThC4b1V5AW0hjUwPtU5g//2/3GEc6y2ToocmzwZbS/AhFPe0zgAbvvizRXylrnwIfF/h0XHiHhoXi3TXP/3+1scnRST0s+h+K+ZeSTx0j16kxWHEvuGYkmc9Am3MgisCrhIqMfsdQ0L+7ggnvo5Ggmfez24ifnrlx4QVzjvm9nMyLIp1Xw/IZJHylHJJPgApE8bASJHXX6XSifHLgL6NbK3oK5x4AX9pJdtvYbEiOQhYvorFCv6TbEs5rbQpcQoKDyk3AqEGs7p+akalj0XMOMXYNLcj9E6Uht1r/OuYMFz23qCrBT/e+58ThG1fu0QpbBQvBTtWP5cnuNUphkYygdUbOokelYU6QLN6MFi/A7GFJV3AX0PRmB57JEZcNoBUpx6doGNeyxSMQUbtw+Ekcd/f0JFi66wmfH97iiKhOYebKQjUq8+OvFzeZ8b5FQD6y+2/N180pMt0otEjGVWZ8lGo9wGUzDN7ph4P+EOrYgi550ppemaOTOUTGVUi0NSBiqMnF/N/kiqVuvInmdAbKkQq+XK2h7XGOKVc9EGdomjDJvd3zdbhw== james.matthew.gray@gmail.com";
  hal9000 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDbgRmAE0rmaBz2eZWxRi4fOS72jgrf9hgmbDa2Bj8W7 james.matthew.gray@gmail.com";
  jgrnix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBSe31pyRwS8gvH1XYjAkYKP2iu1+FIGHKQy8CcvSlPL james.matthew.gray@gmail.com";

  users = [ jamesgray hal9000 jgrnix ];

  root_ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIORhyHMsVzphimUJfIuysIiiZRfwsaDzyUlYQg9nYrBp root@nixos";
  root_rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCi9e4mwjNmPP36IwSCyBRNUd2TDmXTP5IqvbDJFtN8iDKmbB++JeRDse7it7RQ2cqvcwL/McFYD9di0nXCx/lk6bptLzIVcOTOTwkS6MU/5lsK4cFr7ITPK6b/XPkQA9rt1um0cPX2SoYnSeDcC7nurWbAXF8oa3IFs/QGN/4wIREmUB53j3FHA33VTbxzsAseXvIVb7RdhP8K5SEh5/+6am1GyJmrhLQW0WmMZWsYc1jHhY4KN8oRhpDzoGNAAivW8nqDLNZFmLa18cZdP0tuJLbWQ0MtIf5h591hS7vAXLL6J3D2yyW5SEwpsYVyp2tDyLm31hrHgMx7uNgoBVM0Kt0x1+VWXtNmvddQdJEV9+U3E5T2aipqQI4VN+jxthT3e6v2nEZwRpWx8gYeTYQRnCe2MRvrvhX7uwHlpBDg+M5tQ9MWKuyoTeDd6tKJPOuDqKlna7O5xLsM+H4AzUUS/St3puajva6shj6uPycL5+0GFGXQt6fKsnqXo/7jWf2wVP1e7g+dAMYX93zSM9vtj1RsxUHKzV4FhMEhf7eo3Y6C5P7wINXCPXtZHMB9pmc4wL1Sy+Sag/kxExI0oPubMyLAK5HlrmitwqFnpvkdk562YGy4KAJPFwo5ze5P1rXa16Cpc44BhXBpo1HN7qjL7pAKwNtlDw0wMVCce/HRoQ== root@nixos";
  jgrnix_root_ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsITdTpZuajuMW8PyVDrjtBV5zXtNnAkh63RIr/qPBi";
  jgrnix_root_rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLc3W1A+FmUf5hDUAqINvkV9jalAbgBtZphy8CTYJ6p8fqaGoFOYSWLVBmqkMGWVu+nN7ilH5CiNMK5psvCBMiBSNoi4dFMhZLZpMNTN7w/AQJEB7M0BQ7hPV+Jp/xQnNH7oEhZGdv642zicY52I1EqC6iiIUj1c+vedoh52EGr+8meNXJwRsoI11dDqcBJ0wRlGrOm9O/5MWE36EHUhuZpTKihaEk/sUTmbNMCL/77RQrPz9YrfMM08m4vE7Ss/qeDcaCGge/CWZ/fCQL8MyxTZyhCvpIkOOwT0gVGYx3xy51ATenLRmz5M2PQ6SVGJdUXMyTH21XGxcbFvaWqreggiwoqXSAqgUWAm1RnIYabqBtNRTpZGIDGDztUopYgGnCyidXWZFjsZ2zPuhGmaQ6H17lgaDo3Tx9Uqd3I4ifJqHFQL7LQJSjNtxAPBCrPjo2Pj0iba+IQTTpKUWO09lbssnT49nwojPCQSNvhxl27qlTofVAHH9bkWciBdJRjPtwow7i+PEItqT2vhEPq3CkcfhEx4ErgorPLjVyNO0TU6YpoTTN7u2y6YxG6AoHiF2byObMYXZ1EheXfuXRpTBONIrSwVjkGlK5ZluYmd+LD2kxqmdvQlnpLCFZ2/5G729zcAfsDquldirrbeV23O0Y5ZuNqMXLKwzSTAYXA1sg2w==";

  systems = [ root_ed25519 root_rsa jgrnix_root_ed25519 jgrnix_root_rsa ];

in
{
  "bandcamp-env.age".publicKeys = users ++ systems;
  "bb-env.age".publicKeys = users ++ systems;
  "ipod-env.age".publicKeys = users ++ systems;
  "lubelogger-env.age".publicKeys = users ++ systems;
  "vw-env.age".publicKeys = users ++ systems;
  "mealie-env.age".publicKeys = users ++ systems;
  "miniflux-env.age".publicKeys = users ++ systems;
  "miniflux-db-env.age".publicKeys = users ++ systems;
  "music-env.age".publicKeys = users ++ systems;
  "backup-b2-env.age".publicKeys = users ++ systems;
  "frigate-env.age".publicKeys = users ++ systems;
  "wordpress-env.age".publicKeys = users ++ systems;
  "scrutiny-config.age".publicKeys = users ++ systems;
  "wifi-password.age".publicKeys = users ++ systems;
}
