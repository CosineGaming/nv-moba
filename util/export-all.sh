set -v

wait() {
  echo "Fix any merge conflicts / etc then resume by entering here: "
  read _
}

echo "This may go very wrong. Enter at your own risk."

git checkout config-qwerty
git merge master
wait

util/export-universal.sh

git checkout config-installer
git merge master
wait

util/export-installers.sh

echo "Done???"

