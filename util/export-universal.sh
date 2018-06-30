set -xv

echo "Please increment the version number!"
vi scripts/util.gd

echo "What is the version number?"
read version
godot --export cross-full release/$version.pck

