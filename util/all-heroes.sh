#!/bin/sh

count=$1
if [ ! -z "$count" ]; then
  shift # Only do this if arg exists (fixes error)
  count=`expr "$count" - 1` # We reserve one for that final one
else
  count=1 # Default 2, minus one for the final -start-game
fi

godot -server -hero=0 "$@" &
for i in `seq 2 $count` # 3, for 1 + the server + the starter
do
  godot -client -hero=$i "$@" &
done

sleep 1
godot -start-game -hero=1 "$@" &

