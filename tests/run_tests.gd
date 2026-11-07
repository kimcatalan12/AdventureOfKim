extends SceneTree
## Run: godot --headless --path . -s tests/run_tests.gd
## Checks the game rules, answer reading, question banks and maps.

var _failures := 0
var _checks := 0


func _init() -> void:
	_test_rules()
	_test_answers()
	for stage in [1, 2, 3]:
		_test_stage_data(stage)
	print("%d checks, %d failed" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _ok(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)


func _test_rules() -> void:
	var rules := StageRules.new(10, 20)
	for i in 9:
		rules.collect()
	_ok(rules.phase == StageRules.Phase.COLLECT, "still collecting at 9 of 10")
	rules.collect()
	_ok(rules.phase == StageRules.Phase.QUIZ, "quiz starts at 10 of 10")

	rules.answer(false)
	_ok(rules.lives == 2 and rules.phase == StageRules.Phase.SEEK, "wrong answer costs a life and sends player to seek")
	rules.answer(true)
	_ok(rules.score == 0, "cannot answer while seeking")
	rules.collect()
	_ok(rules.phase == StageRules.Phase.QUIZ, "object reopens the question")
	_ok(rules.collected == 10, "review object does not change the collect count")
	rules.answer(true)
	_ok(rules.score == 0 and rules.question_index == 1, "retry clears the question but earns no score")
	_ok(rules.lives == 3, "clearing a question refills life savers")
	rules.answer(true)
	_ok(rules.score == 1, "first-try answer scores")

	var enemies := StageRules.new(5, 20)
	enemies.enemy_hit()
	enemies.enemy_hit()
	_ok(enemies.phase == StageRules.Phase.COLLECT and enemies.lives == 1, "two hits leave one life")
	enemies.enemy_hit()
	_ok(enemies.phase == StageRules.Phase.FAILED, "third hit fails the stage")

	var attempts := StageRules.new(0, 20)
	attempts.phase = StageRules.Phase.QUIZ
	for i in 3:
		attempts.answer(false)
		if attempts.phase == StageRules.Phase.SEEK:
			attempts.collect()
	_ok(attempts.phase == StageRules.Phase.FAILED, "three wrong answers on one question fail the stage")

	_ok(_finish_with_score(10) == StageRules.Phase.PASSED, "10 of 20 passes")
	_ok(_finish_with_score(20) == StageRules.Phase.PASSED, "20 of 20 passes")
	_ok(_finish_with_score(9) == StageRules.Phase.FAILED, "9 of 20 fails")


func _finish_with_score(target: int) -> StageRules.Phase:
	var rules := StageRules.new(0, 20)
	rules.phase = StageRules.Phase.QUIZ
	for i in 20:
		if i >= target:
			rules.answer(false)
			rules.collect()
		rules.answer(true)
	return rules.phase


func _test_answers() -> void:
	_ok(MathAnswer.same_value("3/4", "0.75"), "fraction equals decimal")
	_ok(MathAnswer.same_value("1 3/4", "7/4"), "mixed number equals improper")
	_ok(MathAnswer.same_value(" 2 ", "2"), "spaces are ignored")
	_ok(MathAnswer.same_value(".5", "1/2"), "leading point works")
	_ok(not MathAnswer.same_value("3/0", "0"), "dividing by zero is rejected")
	_ok(not MathAnswer.same_value("abc", "1"), "text is rejected")
	_ok(not MathAnswer.same_value("1 2", "3"), "two whole numbers are rejected")
	_ok(not MathAnswer.same_value("", "0"), "empty is rejected")
	_ok(not MathAnswer.same_value("0.7", "0.75"), "different values do not match")


func _test_stage_data(stage: int) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/stage%d.json" % stage))
	var questions: Array = data["questions"]
	_ok(questions.size() == 20, "stage %d has 20 questions" % stage)
	var seen := {}
	for question: Dictionary in questions:
		_ok(not seen.has(question["q"]), "duplicate question: " + question["q"])
		seen[question["q"]] = true
		_test_question(stage, question)
	_test_question(stage, data["trial"])
	_ok(data["facts"].size() >= 12, "stage %d has enough facts" % stage)
	_ok((questions[0].has("choices")) != data.get("typed", false), "stage %d question type" % stage)
	_test_map(stage, data)


func _test_question(stage: int, question: Dictionary) -> void:
	var label := "stage %d: %s" % [stage, question["q"]]
	var expression := Expression.new()
	var parse_error := expression.parse(question["check"])
	_ok(parse_error == OK, label + " check parses")
	if parse_error != OK:
		return
	var expected: float = float(expression.execute())
	var answer := MathAnswer.parse(question["a"])
	_ok(not expression.has_execute_failed() and absf(expected - answer) < 0.000001,
		"%s: answer %s but check gives %s" % [label, question["a"], expected])
	if question.has("choices"):
		var choices: Array = question["choices"]
		_ok(choices.size() == 4, label + " has 4 choices")
		_ok(question["a"] in choices, label + " includes the answer")
		for choice: String in choices:
			if choice != question["a"]:
				_ok(not MathAnswer.same_value(choice, question["a"]), "%s: wrong choice %s equals the answer" % [label, choice])
			_ok(not is_nan(MathAnswer.parse(choice)), label + " choice is readable: " + choice)
		var unique := {}
		for choice: String in choices:
			unique[choice] = true
		_ok(unique.size() == 4, label + " choices are different")


func _test_map(stage: int, data: Dictionary) -> void:
	var map: Array = data["map"]
	var width: int = map[0].length()
	var start := Vector2i(-1, -1)
	var open := 0
	for y in map.size():
		var row: String = map[y]
		_ok(row.length() == width, "stage %d row %d width" % [stage, y])
		_ok(row[0] == "#" and row[width - 1] == "#", "stage %d row %d has side walls" % [stage, y])
		for x in width:
			if row[x] == "P":
				start = Vector2i(x, y)
			if row[x] == "." or row[x] == "P":
				open += 1
	_ok(start.x >= 0, "stage %d has a start" % stage)
	var reached := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if reached.has(next) or next.y < 0 or next.y >= map.size() or next.x < 0 or next.x >= width:
				continue
			var tile: String = map[next.y][next.x]
			if tile == "." or tile == "P":
				reached[next] = true
				queue.append(next)
	_ok(reached.size() == open, "stage %d: every open tile is reachable (%d of %d)" % [stage, reached.size(), open])
