docker run -it \
  --rm \
  --hostname="$(hostname)" \
  --env="DISPLAY" \
  --volume="${XAUTHORITY:-${HOME}/.Xauthority}:/root/.Xauthority:ro" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:ro" \
  --volume="/home/karl/docker/chansort
  /channel_list:/data" \
  chansort:latest
