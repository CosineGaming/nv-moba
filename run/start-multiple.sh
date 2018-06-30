#!/bin/sh

count=$1
if [ ! -z "$count" ]; then
  shift # Only do this if arg exists (fixes error)
  count=`expr "$count" - 1` # We reserve one for that final one
else
  count=1 # Default 2, minus one for the final -start-game
fi

run/open-multiple.sh $count "$@"
sleep 1
godot -client -start-game "$@" &

