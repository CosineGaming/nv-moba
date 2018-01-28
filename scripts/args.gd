# Adapted from: https://gist.github.com/bitwes/fe1e2aef8da0940104c8
# Example of a script that can be run from the command line and parses out options.  This is adapted
# from the Gut command line interface.  The first 2 classes are not to be used directly, they are used
# by the Options class and can be ignored.  Start reading after the Options class to get a feel for
# how it is used, then work backwards.
#
# This could be easily extracted out into a class itself, but in the interest of how it is being used
# I wanted it all in one file.  It is yours to do with what you please, but if you make something out
# of it, I'd love to hear about it.  I'm bitwes on godot forums, github, and bitbucket.
extends Control

#-------------------------------------------------------------------------------
# Parses the command line arguments supplied into an array that can then be
# examined and parsed based on how the gut options work.
#-------------------------------------------------------------------------------
class CmdLineParser:
	var _opts = []
	
	func _init():
		for i in range(OS.get_cmdline_args().size()):
			_opts.append(OS.get_cmdline_args()[i])
			
	# Search _opts for an element that starts with the option name
	# specified.
	func find_option(name):
		var found = false
		var idx = 0
		
		while(idx < _opts.size() and !found):
			if(_opts[idx].find(name) == 0):
				found = true
			else:
				idx += 1
				
		if(found):
			return idx
		else:
			return -1

	# Parse out the value of an option.  Values are seperated from
	# the option name with "="
	func get_option_value(full_option):
		var split = full_option.split('=')
	
		if(split.size() > 1):
			return split[1]
		else:
			return null
	
	# Parse out multiple comma delimited values from a command line
	# option.  Values are separated from option name with "=" and 
	# additional values are comma separated.
	func get_option_array_value(full_option):
		var value = get_option_value(full_option)
		var split = value.split(',')
		return split
	
	func get_array_value(option):
		var to_return = []
		var opt_loc = find_option(option)
		if(opt_loc != -1):
			to_return = get_option_array_value(_opts[opt_loc])
			_opts.remove(opt_loc)
	
		return to_return
	
	# returns the value of an option if it was specfied, otherwise
	# it returns the default.
	func get_value(option, default):
		var to_return = default
		var opt_loc = find_option(option)
		if(opt_loc != -1):
			to_return = get_option_value(_opts[opt_loc])
			_opts.remove(opt_loc)
	
		return to_return
	
	# returns true if it finds the option, false if not.
	func was_specified(option):
		var opt_loc = find_option(option)
		if(opt_loc != -1):
			_opts.remove(opt_loc)
		
		return opt_loc != -1	

#-------------------------------------------------------------------------------
# Simple class to hold a command line option
#-------------------------------------------------------------------------------
class Option:
	var value = null
	var option_name = ''
	var default = null
	var description = ''
	
	func _init(name, default_value, desc=''):
		option_name = name
		default = default_value
		description = desc
		value = default_value
	
	func pad(value, size, pad_with=' '):
		var to_return = value
		for i in range(value.length(), size):
			to_return += pad_with
		
		return to_return
		
	func to_s(min_space=0):
		var subbed_desc = description
		if(subbed_desc.find('[default]') != -1):
			subbed_desc = subbed_desc.replace('[default]', str(default))
		return pad(option_name, min_space) + subbed_desc
		
		
#-------------------------------------------------------------------------------
# The high level interface between this script and the command line options 
# supplied.  Uses Option class and CmdLineParser to extract information from
# the command line and make it easily accessible.
#-------------------------------------------------------------------------------
class Options:
	var options = []
	var _opts = []
	var _banner = ''
	
	func add(name, default, desc):
		options.append(Option.new(name, default, desc))
	
	func get_value(name):
		var found = false
		var idx = 0
		
		while(idx < options.size() and !found):
			if(options[idx].option_name == name):
				found = true
			else:
				idx += 1
		
		if(found):
			return options[idx].value
		else:
			print("COULD NOT FIND OPTION " + name)
			return null
	
	func set_banner(banner):
		_banner = banner
		
	func print_help():
		var longest = 0
		for i in range(options.size()):
			if(options[i].option_name.length() > longest):
				longest = options[i].option_name.length()
	
		print('---------------------------------------------------------')
		print(_banner)
		
		print("\nOptions\n-------")
		for i in range(options.size()):
			print('  ' + options[i].to_s(longest + 2))
		print('---------------------------------------------------------')
	
	func print_options():
		for i in range(options.size()):
			print(options[i].option_name + '=' + str(options[i].value))

	func parse():
		var parser = CmdLineParser.new()
		
		for i in range(options.size()):
			var t = typeof(options[i].default)
			if(t == TYPE_INT):
				options[i].value = int(parser.get_value(options[i].option_name, options[i].default))
			elif(t == TYPE_STRING):
				options[i].value = parser.get_value(options[i].option_name, options[i].default)
			elif(t == TYPE_ARRAY):
				options[i].value = parser.get_array_value(options[i].option_name)
			elif(t == TYPE_BOOL):
				options[i].value = parser.was_specified(options[i].option_name)
			elif(t == TYPE_NIL):
				print(options[i].option_name + ' cannot be processed, it has a nil datatype')
			else:
				print(options[i].option_name + ' cannot be processsed, it has unknown datatype:' + str(t))
