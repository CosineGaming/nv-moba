#!/usr/bin/env python3

from threading import Thread

from godot import exposed
from godot.bindings import Node, Vector2, Input, Array

import pyaudio
import pymumble_py3 as pymumble
from pymumble_py3 import Mumble

RATE = 48000
CHUNK = 1024

# Plays audio and exposes who's speaking, does no UI
@exposed
class VoiceChat(Node):

	# To be initialized on connect
	mumble = None
	record = None
	play = None

	_speaking = {}

	def connect(self, channel, name):
		# Mumble setup
		self.mumble = Mumble(
				"192.168.1.13",
				name)
		self.mumble.set_application_string("Godot voice-chat")
		# You have to enable receiving sound fsr
		self.mumble.set_receive_sound(True)
		self.mumble.callbacks.set_callback(
				pymumble.constants.PYMUMBLE_CLBK_SOUNDRECEIVED,
				self._sound_received)
		self.mumble.start()
		# Actually waits until ready, despite name
		self.mumble.is_ready()
		# Move into the channel for the server we're on
		# These are created prior because pymumble doesn't support dynamically creating them
		self.mumble.channels.find_by_name(channel).move_in()

		self._init_audio()

	def get_speaking(self):
		return Array(self._speaking.keys())

	def _init_audio(self):
		# Audio setup
		self.p = pyaudio.PyAudio()
		self.record = self.p.open(
				format=pyaudio.paInt16,
				channels=1,
				rate=RATE,
				input=True,
				frames_per_buffer=CHUNK)
		self.play = self.p.open(
				format=pyaudio.paInt16,
				channels=1,
				rate=RATE,
				output=True,
				frames_per_buffer=CHUNK)

	def _process(self, delta):
		if self.mumble and self.record:
			# We have to get the data out of the buffer either way
			data = self.record.read(CHUNK)
			# But only add it to mumble if we're pushing
			if Input.is_action_pressed("push_to_talk"):
				self.mumble.sound_output.add_sound(data)

			# Remove people who were speaking but aren't
			for key in list(self._speaking.keys()):
				self._speaking[key] -= delta
				if self._speaking[key] < 0:
					del self._speaking[key]

	def _sound_received(self, user, sound_chunk):
		if self.play:
			name = user.get_property("name")
			self.play.write(sound_chunk.pcm)
			SPEAK_TIMEOUT = 0.1 # In seconds
			self._speaking[name] = SPEAK_TIMEOUT

	def _exit_tree(self):
		# Close down all the PyAudio stuff
		self.record.stop_stream()
		self.record.close()
		self.play.stop_stream()
		self.play.close()
		self.p.terminate()

