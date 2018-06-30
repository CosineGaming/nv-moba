#!/bin/sh

count=$1
if [ ! -z "$count" ]; then
  shift # Only do this if arg exists (fixes error)
else
  count=2 # Default 2
fi

godot -server "$@" &
for i in `seq 2 $count` # 3, for 1 + the server + the starter
do
  godot -client "$@" &
done

