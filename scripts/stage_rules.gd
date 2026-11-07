class_name StageRules
extends RefCounted
## The rules of one stage, with no graphics, so they can be tested on their own.

enum Phase { COLLECT, QUIZ, SEEK, PASSED, FAILED }

const MAX_LIVES := 3
const PASS_SCORE := 10

var goal: int
var total_questions: int
var collected := 0
var lives := MAX_LIVES
var phase := Phase.COLLECT
var question_index := 0
var score := 0
var first_try := true


func _init(collect_goal: int, question_count: int) -> void:
	goal = collect_goal
	total_questions = question_count


## Picking up an object either counts toward the goal or, after a wrong
## answer, unlocks another attempt at the same question.
func collect() -> void:
	match phase:
		Phase.COLLECT:
			collected += 1
			if collected >= goal:
				phase = Phase.QUIZ
		Phase.SEEK:
			phase = Phase.QUIZ


func enemy_hit() -> void:
	if phase != Phase.COLLECT and phase != Phase.SEEK:
		return
	_lose_life()


## A question only adds to the score when it is right on the first try.
## Clearing it refills the life savers, so each question gets three attempts.
func answer(correct: bool) -> void:
	if phase != Phase.QUIZ:
		return
	if not correct:
		first_try = false
		_lose_life()
		if phase != Phase.FAILED:
			phase = Phase.SEEK
		return
	if first_try:
		score += 1
	question_index += 1
	first_try = true
	lives = MAX_LIVES
	if question_index >= total_questions:
		phase = Phase.PASSED if score >= PASS_SCORE else Phase.FAILED


func _lose_life() -> void:
	lives -= 1
	if lives <= 0:
		lives = 0
		phase = Phase.FAILED
