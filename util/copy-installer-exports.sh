echo "Make sure you've run util/export-installers.sh; it's not run by this script."
# mac: already zipped ("app")
cp release/installer/mac/vanagloria.zip ~/src/cosine-gaming/static/vanagloria/vanagloria-mac.zip
# Zip and move at the same time
# However zip will update instead of replace if allowed to. -FS prevents that (We want fresh af)
# We also specify -j because we want the files as immediate as possible
# x11
zip -FSrj ~/src/cosine-gaming/static/vanagloria/vanagloria-x11.zip release/installer/x11/
# windows
zip -FSrj ~/src/cosine-gaming/static/vanagloria/vanagloria-win.zip release/installer/win/

