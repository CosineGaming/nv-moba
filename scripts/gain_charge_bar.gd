extends ProgressBar

signal done

export var factor = 1

var tracking_player = null setget set_track_player
# Always stores total time internally, but getter gives time_left
var time = null setget set_time, get_time
var row = 0 setget set_row

var _last_charge = -1
var _timer = null

export (NodePath) var _player

func _ready():
	_player = get_node("../../..")

func set_time(val):
	time = val
	_timer = Timer.new()
	add_child(_timer)
	_timer.wait_time = val
	_timer.one_shot = true
	_timer.connect("timeout", self, "_done") # TODO: Propagate to parent
	_timer.start()

func get_time():
	return _timer.time_left

func set_track_player(to):
	tracking_player = to
	_last_charge = tracking_player.charge

func build_charge(amount):
	var x = _player.build_charge(amount)
	# We want a smooth curve that:
	# * lim f = 100
	# * f(0) = 0
	# To map absolute values to percents
	var smoothing = 10
	var f = (100 * x + smoothing) / (x + smoothing) - 1
	value = f

func set_row(i):
	var padding = -15
	row = i
	rect_position.y = (row + 1) * padding

func _process(delta):
	if tracking_player:
		_follow_player()
	if time:
		_update_time()

func _follow_player():
	_player.charge -= _last_charge * factor
	_player.charge += tracking_player.charge * factor
	_last_charge = tracking_player.charge

func _update_time():
	value = 100 * _timer.time_left / time

func _done():
	emit_signal("done")
	queue_free()

