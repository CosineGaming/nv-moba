#!/usr/bin/env python3

import pyaudio
import pymumble_py3 as pymumble
from pymumble_py3 import Mumble
from time import sleep

RATE = 48000
CHUNK = 1024

class VoiceChat():

	# Audio setup
	p = pyaudio.PyAudio()
	stream = p.open(
			format=pyaudio.paInt16,
			channels=1,
			rate=RATE,
			input=True,
			frames_per_buffer=CHUNK)
	mumble = Mumble(
			"192.168.1.133",
			"luna-nv-moba",
			debug=True)
			# )

	def _ready(self):
		# TODO: Get name in parameter and use it
		# Mumble setup
		self.mumble.set_application_string("Godot voice-chat")
		self.mumble.callbacks.set_callback(
				pymumble.constants.PYMUMBLE_CLBK_CONNECTED,
				self._success)
		self.mumble.start()
		self.mumble.is_ready()
		print("Done")

	def _success(self):
		print("succeeedededd")
	
	def _process(self, delta):
		data = self.stream.read(CHUNK)
		# self.mumble.sound_output.add_sound(data)
	
	def _exit_tree(self):
		stream.stop_stream()
		stream.close()
		p.terminate()

vc = VoiceChat()
vc._ready()
while True:
	vc._process(5)
sleep(10)

