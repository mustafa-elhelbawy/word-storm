extends Node

signal ad_reward_granted
signal ad_unavailable


func _ready() -> void:
	pass


func load_rewarded() -> void:
	pass


func show_rewarded() -> void:
	emit_signal("ad_unavailable")
