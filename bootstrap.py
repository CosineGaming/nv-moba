#!/usr/bin/env python

import os

if os.path.exists("project.godot"):
	# Update
	os.system("git pull")
	os.system("godot")
else:
	# Initial download
	os.system("git clone --depth 1 https://github.com/CosineGaming/nv-moba .")
	os.system("godot")
