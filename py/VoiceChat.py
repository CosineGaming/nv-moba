#!/usr/bin/env python3

from threading import Thread

from godot import exposed
from godot.bindings import Node2D, Vector2

import pyaudio
import pymumble_py3 as pymumble
from pymumble_py3 import Mumble

RATE = 48000
CHUNK = 1024

@exposed
class VoiceChat(Node2D):

	# Audio setup
	p = pyaudio.PyAudio()
	stream = p.open(
			format=pyaudio.paInt16,
			channels=1,
			rate=RATE,
			input=True,
			frames_per_buffer=CHUNK)
	mumble = Mumble(
			"192.168.1.13",
			"luna-nv-moba",
			debug=True)

	def _ready(self):
		# TODO: Get name in parameter and use it
		# Mumble setup
		self.set_position(Vector2(100, 15))
		self.mumble.set_application_string("Godot voice-chat")
		self.mumble.callbacks.set_callback(
				pymumble.constants.PYMUMBLE_CLBK_CONNECTED,
				self._success)
		self._loop()
		self.mumble.set_bandwidth(200000)
		# run_mumble = Thread(target=self._loop)
		# run_mumble.start()
		# self.mumble.is_ready()

	def _loop(self):
		self.mumble.start()
	
	def _success(self):
		print("succeeedededd")
	
	def _process(self, delta):
		data = self.stream.read(CHUNK)
		# self.mumble.sound_output.add_sound(data)
	
	def _exit_tree(self):
		self.stream.stop_stream()
		self.stream.close()
		self.p.terminate()

