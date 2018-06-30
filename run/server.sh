port=$1
shift
godot -level=2 -silent -server -port=$port "$@" 2>>log/$port.error 1>>log/$port.log

