extends Node

signal ad_reward_granted
signal ad_unavailable

# Flip to false and set PROD_REWARDED_ID before Play Store submission
const TEST_MODE: bool = true
const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"
const PROD_REWARDED_ID := ""  # TODO: set via env var in release build

var _admob: Object = null
var _rewarded_loaded: bool = false


func _ready() -> void:
	if not Engine.has_singleton("AdMob"):
		return
	_admob = Engine.get_singleton("AdMob")
	_admob.connect("rewarded_ad_loaded",         _on_rewarded_loaded)
	_admob.connect("rewarded_ad_failed_to_load", _on_rewarded_failed)
	_admob.connect("rewarded_ad_dismissed",      _on_rewarded_dismissed)
	_admob.connect("user_earned_reward",         _on_user_earned_reward)


func load_rewarded() -> void:
	if _admob == null:
		ad_unavailable.emit()
		return
	var ad_unit_id := TEST_REWARDED_ID if TEST_MODE else PROD_REWARDED_ID
	_admob.load_rewarded_ad(ad_unit_id)


func show_rewarded() -> void:
	if not _rewarded_loaded or _admob == null:
		ad_unavailable.emit()
		return
	_admob.show_rewarded_ad()


func _on_rewarded_loaded() -> void:
	_rewarded_loaded = true


func _on_rewarded_failed(_error_code: int) -> void:
	_rewarded_loaded = false
	ad_unavailable.emit()


func _on_rewarded_dismissed() -> void:
	_rewarded_loaded = false


func _on_user_earned_reward(_type: String, _amount: int) -> void:
	_rewarded_loaded = false
	ad_reward_granted.emit()
