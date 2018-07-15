#!/usr/bin/env python3

from threading import Thread

from godot import exposed
from godot.bindings import Control, Vector2, Input

import pyaudio
import pymumble_py3 as pymumble
from pymumble_py3 import Mumble

RATE = 48000
CHUNK = 1024

@exposed
class VoiceChat(Control):

	# Audio setup
	p = pyaudio.PyAudio()
	record = p.open(
			format=pyaudio.paInt16,
			channels=1,
			rate=RATE,
			input=True,
			frames_per_buffer=CHUNK)
	play = p.open(
			format=pyaudio.paInt16,
			channels=1,
			rate=RATE,
			output=True,
			frames_per_buffer=CHUNK)
	# Mumble setup
	mumble = Mumble(
			"192.168.1.13",
			"luna-nv-moba")

	_speaking = []

	def _ready(self):
		# TODO: Get name in parameter and use it
		# Mumble setup
		self.mumble.set_application_string("Godot voice-chat")
		# You have to enable receiving sound fsr
		self.mumble.set_receive_sound(True)
		self.mumble.callbacks.set_callback(
				pymumble.constants.PYMUMBLE_CLBK_SOUNDRECEIVED,
				self._sound_received)
		self._loop()
		# Actually waits until ready, despite name
		self.mumble.is_ready()

	def _loop(self):
		self.mumble.start()

	def _process(self, delta):
		# We have to get the data out of the buffer either way
		data = self.record.read(CHUNK)
		# But only add it to mumble if we're pushing
		if Input.is_action_pressed("push_to_talk"):
			self.mumble.sound_output.add_sound(data)

	def _sound_received(self, user, sound_chunk):
		print(user.get_property("name"))
		self.play.write(sound_chunk.pcm)

	def _exit_tree(self):
		# Close down all the PyAudio stuff
		self.record.stop_stream()
		self.record.close()
		self.play.stop_stream()
		self.play.close()
		self.p.terminate()

