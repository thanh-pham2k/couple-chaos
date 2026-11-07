extends Node
class_name CoopQuestManager

signal changed
signal all_completed

const GOALS := {"store": 3, "clean": 4, "pillow": 2}
var completed := {"store": {}, "clean": {}, "pillow": {}}
var finished := false

func reset() -> void:
	completed = {"store": {}, "clean": {}, "pillow": {}}
	finished = false
	changed.emit()

func get_count(category: String) -> int:
	return completed.get(category, {}).size()

func get_goal(category: String) -> int:
	return GOALS.get(category, 0)

func is_all_goals_met() -> bool:
	for cat in GOALS.keys():
		if get_count(cat) < GOALS[cat]:
			return false
	return true

func complete_target(category: String, id: String) -> bool:
	if finished or not completed.has(category) or completed[category].has(id):
		return false
	if get_count(category) >= GOALS[category]:
		return false
	completed[category][id] = true
	changed.emit()
	if is_all_goals_met():
		all_completed.emit()
	return true
