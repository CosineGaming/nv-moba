#!/bin/sh

set -m

GODOT=${GODOT:-godot}

count=$1
if [ ! -z "$count" ]; then
  shift # Only do this if arg exists (fixes error)
else
  count=2 # Default 2
fi

for i in `seq 1 $count` # 3, for 1 + the server + the starter
do
  $GODOT -quick-play "$@" &
done

# Wait for all parallel jobs to finish
while [ 1 ]; do fg 2> /dev/null; [ $? == 1 ] && break; done

