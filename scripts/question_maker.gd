class_name QuestionMaker
extends RefCounted
## Makes quiz questions, practice questions and example facts with new
## numbers every time, so no two runs of a stage are the same.
##
## Numbers are kept as exact fractions (Vector2i: x = top, y = bottom), so
## decimals such as 0.1 + 0.2 never pick up rounding errors.
## Each question is {q, a, check} plus "choices" for multiple choice.
## "check" is a separate math expression the tests use to confirm "a".

const NAMES := ["Ana", "Ben", "Mia", "Leo", "Kim", "Vince", "Lia", "Carlo"]
const WORDS := ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
const PLACES := ["", "tenths", "hundredths", "thousandths"]
const PLACE := ["", "tenth", "hundredth", "thousandth"]
## Fractions with these bottoms always end as decimals (2, 4, 5, 8 ...).
const CLEAN_BOTTOMS := [2, 4, 5, 8, 10, 20]

var rng: RandomNumberGenerator


func _init(random: RandomNumberGenerator = null) -> void:
	rng = random
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()


## A full quiz for one stage. Each kind of question appears once before any
## kind repeats, and no question text appears twice.
func quiz(stage: int, count: int) -> Array:
	var kinds := _kinds(stage)
	var order: Array = []
	var out: Array = []
	var seen := {}
	var guard := 0
	while out.size() < count and guard < count * 50:
		guard += 1
		if order.is_empty():
			order = kinds.duplicate()
			_shuffle(order)
		var question: Dictionary = (order.pop_back() as Callable).call()
		if seen.has(question["q"]):
			continue
		seen[question["q"]] = true
		out.append(question)
	return out


## An easy warm-up question for the lesson.
func practice(stage: int) -> Dictionary:
	var question: Dictionary
	match stage:
		1:
			question = _d_add()
		2:
			question = _f_add_like()
		_:
			question = _t_to_decimal()
	question["q"] = "Practice: " + question["q"]
	return question


## A worked example with fresh numbers, shown when Kim picks up an object.
func example_fact(stage: int) -> String:
	match stage:
		1:
			match rng.randi_range(0, 3):
				0:
					var number := _distinct_digit_decimal()
					var place := rng.randi_range(1, 3)
					return "In %s, the %s is in the %s place." % [_dec(number), _digit_at(number, place), PLACE[place]]
				1:
					var a := _rand_dec(0, 9, rng.randi_range(1, 2))
					return "Multiplying by 10 moves the point one place right: %s × 10 = %s." % [_dec(a), _dec(_mul(a, _n(10)))]
				2:
					var a := _rand_dec(0, 99, rng.randi_range(1, 2))
					return "Dividing by 10 moves the point one place left: %s ÷ 10 = %s." % [_dec(a), _dec(_div(a, _n(10)))]
				_:
					var tenths := rng.randi_range(2, 9)
					var other := Vector2i((tenths - 1) * 10 + rng.randi_range(1, 9), 100)
					return "%s is greater than %s, because %d tenths beats %d tenths." % [_dec(Vector2i(tenths, 10)), _dec(other), tenths, tenths - 1]
		2:
			match rng.randi_range(0, 2):
				0:
					var f := _rand_frac(6)
					return "%s, %d/%d and %d/%d are equivalent fractions." % [_frac(f), f.x * 2, f.y * 2, f.x * 3, f.y * 3]
				1:
					var f := _improper()
					return "%s is the same as the mixed number %s." % [_frac(f), _mixed(f)]
				_:
					var f := _rand_frac(6)
					var k := rng.randi_range(2, 5)
					return "%d/%d simplifies to %s: divide the top and bottom by %d." % [f.x * k, f.y * k, _frac(f), k]
		_:
			var f := _clean_frac()
			if rng.randf() < 0.5:
				return "%s = %s, because %d ÷ %d = %s." % [_frac(f), _dec(f), f.x, f.y, _dec(f)]
			return "%s written as a fraction in lowest terms is %s." % [_dec(f), _frac(f)]


func _kinds(stage: int) -> Array:
	match stage:
		1:
			return [_d_add, _d_sub, _d_mul_whole, _d_mul_dec, _d_div_whole, _d_greatest, _d_least,
				_d_round_tenth, _d_round_whole, _d_digit, _d_words, _d_money_total, _d_money_change,
				_d_distance, _d_share]
		2:
			return [_f_add_like, _f_add_unlike, _f_sub_like, _f_sub_unlike, _f_mul, _f_mul_whole,
				_f_div, _f_div_whole, _f_simplify, _f_equivalent, _f_to_mixed, _f_to_improper,
				_f_greatest, _f_least, _f_pizza, _f_left, _f_part_of]
		_:
			return [_t_to_decimal, _t_to_fraction, _t_add, _t_subtract, _t_multiply, _t_divide,
				_t_halve, _t_greater, _t_less, _t_mixed_add, _t_juice, _t_rope]


# ---------- stage 1: decimals ----------

func _d_add() -> Dictionary:
	var a := _rand_dec(0, 20, rng.randi_range(1, 2))
	var b := _rand_dec(0, 20, rng.randi_range(1, 2))
	var sum := _add(a, b)
	return _choice("What is %s + %s?" % [_dec(a), _dec(b)], _dec(sum), _ed(a) + "+" + _ed(b),
		[_dec(_misaligned(a, b)), _dec(_add(sum, _n(1))), _dec(_add(sum, Vector2i(1, 10))), _dec(_sub(sum, Vector2i(1, 10)))])


func _d_sub() -> Dictionary:
	var a := _rand_dec(5, 30, rng.randi_range(1, 2))
	var b := _rand_dec(0, 4, rng.randi_range(1, 2))
	var difference := _sub(a, b)
	return _choice("What is %s − %s?" % [_dec(a), _dec(b)], _dec(difference), _ed(a) + "-" + _ed(b),
		[_dec(_add(difference, _n(1))), _dec(_sub(difference, Vector2i(1, 10))), _dec(_add(difference, Vector2i(1, 10))), _dec(_add(a, b))])


func _d_mul_whole() -> Dictionary:
	var a := _rand_dec(0, 9, rng.randi_range(1, 2))
	var w := rng.randi_range(2, 9)
	var product := _mul(a, _n(w))
	return _choice("What is %s × %d?" % [_dec(a), w], _dec(product), "%s*%d.0" % [_ed(a), w],
		[_dec(_mul(product, _n(10))), _dec(_div(product, _n(10))), _dec(_add(product, _n(1))), _dec(_mul(a, _n(w - 1)))])


func _d_mul_dec() -> Dictionary:
	var a := _rand_dec(0, 5, 1)
	var b := _rand_dec(0, 2, 1)
	var product := _mul(a, b)
	return _choice("What is %s × %s?" % [_dec(a), _dec(b)], _dec(product), _ed(a) + "*" + _ed(b),
		[_dec(_mul(product, _n(10))), _dec(_div(product, _n(10))), _dec(_add(a, b))])


func _d_div_whole() -> Dictionary:
	var answer := _rand_dec(0, 9, rng.randi_range(1, 2))
	var w := rng.randi_range(2, 9)
	var total := _mul(answer, _n(w))
	return _choice("What is %s ÷ %d?" % [_dec(total), w], _dec(answer), "%s/%d.0" % [_ed(total), w],
		[_dec(_mul(answer, _n(10))), _dec(_div(answer, _n(10))), _dec(_add(answer, _n(1)))])


func _d_greatest() -> Dictionary:
	return _d_order(true)


func _d_least() -> Dictionary:
	return _d_order(false)


## Four decimals with different lengths, so the longest is not always biggest.
func _d_order(greatest: bool) -> Dictionary:
	var whole := rng.randi_range(0, 9)
	var values: Array[Vector2i] = []
	for places in [1, 2, 3, 2]:
		var value := _add(_n(whole), _rand_dec(0, 0, places))
		while _has_value(values, value):
			value = _add(_n(whole), _rand_dec(0, 0, places))
		values.append(value)
	var best := values[0]
	for value in values:
		if (_less(best, value) if greatest else _less(value, best)):
			best = value
	var texts: Array = values.map(func(v: Vector2i) -> String: return _dec(v))
	var word := "greatest" if greatest else "least"
	return _choice("Which decimal is the %s?" % word, _dec(best),
		"%s(%s)" % ["max" if greatest else "min", ",".join(texts)], texts)


func _d_round_tenth() -> Dictionary:
	var x := _rand_dec(0, 20, 2)
	var hundredths := _scaled(x, 100)
	var answer := Vector2i(int((hundredths + 5) / 10.0), 10)
	return _choice("Round %s to the nearest tenth." % _dec(x), _dec(_reduce(answer)),
		"floor(%s*10+0.5+0.000001)/10" % _ed(x),
		[_dec(_reduce(Vector2i(hundredths / 10, 10))), _dec(_reduce(Vector2i(hundredths / 10 + 1, 10))),
			_dec(_n(int((hundredths + 50) / 100.0))), _dec(x)])


func _d_round_whole() -> Dictionary:
	var x := _rand_dec(0, 30, rng.randi_range(1, 2))
	var hundredths := _scaled(x, 100)
	var answer := int((hundredths + 50) / 100.0)
	return _choice("Round %s to the nearest whole number." % _dec(x), str(answer),
		"floor(%s+0.5+0.000001)" % _ed(x),
		[str(hundredths / 100), str(hundredths / 100 + 1), _dec(_reduce(Vector2i(int((hundredths + 5) / 10.0), 10)))])


func _d_digit() -> Dictionary:
	var number := _distinct_digit_decimal()
	var place := rng.randi_range(1, 3)
	var answer := _digit_at(number, place)
	var others: Array = []
	for ch in _dec(number).replace(".", ""):
		if ch != answer:
			others.append(ch)
	return _choice("What digit is in the %s place of %s?" % [PLACE[place], _dec(number)], answer,
		"fmod(floor(%s*%d+0.001),10)" % [_ed(number), int(pow(10, place))], others)


func _d_words() -> Dictionary:
	var whole := rng.randi_range(0, 9)
	var digit := rng.randi_range(1, 9)
	var place := rng.randi_range(1, 2)
	var unit: String = PLACE[place] if digit == 1 else PLACES[place]
	var words := "%s %s" % [WORDS[digit], unit]
	if whole > 0:
		words = "%s and %s" % [WORDS[whole], words]
	var bottom := int(pow(10, place))
	var answer := _add(_n(whole), Vector2i(digit, bottom))
	return _choice("Write “%s” as a decimal." % words, _dec(answer), "%d.0+%d.0/%d" % [whole, digit, bottom],
		[_dec(_add(_n(whole), Vector2i(digit, bottom * 10))), _dec(_add(_n(whole), Vector2i(digit, maxi(bottom / 10, 1) * (10 if place == 1 else 1)))),
			str(whole * 10 + digit), _dec(Vector2i(digit, bottom))])


func _d_money_total() -> Dictionary:
	var items: Array = _pick_two(["notebook", "pen", "ruler", "eraser", "bag of chips", "bottle of juice"])
	var a := _rand_dec(5, 60, 2)
	var b := _rand_dec(1, 30, 2)
	var sum := _add(a, b)
	return _choice("A %s costs %s pesos and a %s costs %s pesos. How much are they together?" % [items[0], _money(a), items[1], _money(b)],
		_money(sum), _expr_text(_money(a)) + "+" + _expr_text(_money(b)),
		[_money(_add(sum, _n(1))), _money(_sub(sum, _n(1))), _money(_add(sum, Vector2i(1, 2))), _money(_sub(sum, Vector2i(1, 10)))],
		_money)


func _d_money_change() -> Dictionary:
	var paid: int = [20, 50, 100][rng.randi_range(0, 2)]
	var cost := _rand_dec(1, paid - 1, 2)
	var change := _sub(_n(paid), cost)
	return _choice("%s has %d pesos and spends %s pesos. How much is left?" % [_name(), paid, _money(cost)],
		_money(change), "%d.0-%s" % [paid, _expr_text(_money(cost))],
		[_money(_add(change, _n(1))), _money(_sub(change, Vector2i(1, 10))), _money(_add(change, Vector2i(1, 10))), _money(_sub(change, _n(1)))],
		_money)


func _d_distance() -> Dictionary:
	var a := _rand_dec(1, 9, rng.randi_range(1, 2))
	var b := _rand_dec(1, 9, rng.randi_range(1, 2))
	var sum := _add(a, b)
	return _choice("%s ran %s km on Monday and %s km on Tuesday. How far did they run in all?" % [_name(), _dec(a), _dec(b)],
		_dec(sum), _ed(a) + "+" + _ed(b),
		[_dec(_misaligned(a, b)), _dec(_add(sum, _n(1))), _dec(_sub(sum, Vector2i(1, 10)))])


func _d_share() -> Dictionary:
	var parts := rng.randi_range(2, 6)
	var each := _rand_dec(0, 4, rng.randi_range(1, 2))
	var length := _mul(each, _n(parts))
	return _choice("A %s m ribbon is cut into %d equal parts. How long is each part, in meters?" % [_dec(length), parts],
		_dec(each), "%s/%d.0" % [_ed(length), parts],
		[_dec(_mul(each, _n(10))), _dec(_div(each, _n(10))), _dec(_mul(length, _n(parts)))])


# ---------- stage 2: fractions ----------

func _f_add_like() -> Dictionary:
	var d := rng.randi_range(3, 12)
	var a := rng.randi_range(1, d - 2)
	var b := rng.randi_range(1, d - 1 - a)
	var sum := _reduce(Vector2i(a + b, d))
	return _choice("What is %d/%d + %d/%d?" % [a, d, b, d], _frac(sum), "%d.0/%d+%d.0/%d" % [a, d, b, d],
		[_frac(_reduce(Vector2i(a + b, d * 2))), _frac(_reduce(Vector2i(a * b, d))), _frac(_reduce(Vector2i(absi(a - b), d)))])


func _f_add_unlike() -> Dictionary:
	var pair := _two_fractions(true)
	var sum := _add(pair[0], pair[1])
	return _choice("What is %s + %s?" % [_frac(pair[0]), _frac(pair[1])], _frac(sum), _ef(pair[0]) + "+" + _ef(pair[1]),
		[_frac(_reduce(Vector2i(pair[0].x + pair[1].x, pair[0].y + pair[1].y))), _frac(_reduce(Vector2i(pair[0].x + pair[1].x, pair[0].y * pair[1].y))),
			_frac(_add(sum, Vector2i(1, sum.y)))])


func _f_sub_like() -> Dictionary:
	var d := rng.randi_range(3, 12)
	var a := rng.randi_range(2, d - 1)
	var b := rng.randi_range(1, a - 1)
	var difference := _reduce(Vector2i(a - b, d))
	return _choice("What is %d/%d − %d/%d?" % [a, d, b, d], _frac(difference), "%d.0/%d-%d.0/%d" % [a, d, b, d],
		[_frac(_reduce(Vector2i(a + b, d))), _frac(_reduce(Vector2i(a - b, d * 2))), _frac(_reduce(Vector2i(b, d)))])


func _f_sub_unlike() -> Dictionary:
	var pair := _two_fractions(false)
	var big: Vector2i = pair[0] if _less(pair[1], pair[0]) else pair[1]
	var small: Vector2i = pair[1] if big == pair[0] else pair[0]
	var difference := _sub(big, small)
	return _choice("What is %s − %s?" % [_frac(big), _frac(small)], _frac(difference), _ef(big) + "-" + _ef(small),
		[_frac(_add(big, small)), _frac(_reduce(Vector2i(absi(big.x - small.x), absi(big.y - small.y)))), _frac(_add(difference, Vector2i(1, difference.y)))])


func _f_mul() -> Dictionary:
	var a := _rand_frac(6)
	var b := _rand_frac(6)
	var product := _mul(a, b)
	return _choice("What is %s × %s?" % [_frac(a), _frac(b)], _frac(product), _ef(a) + "*" + _ef(b),
		[_frac(_reduce(Vector2i(a.x + b.x, a.y + b.y))), _frac(_div(a, b)), _frac(_reduce(Vector2i(a.x * b.x, a.y + b.y)))])


func _f_mul_whole() -> Dictionary:
	var f := _rand_frac(8)
	var w := f.y * rng.randi_range(1, 3)
	var product := _mul(f, _n(w))
	return _choice("What is %s × %d?" % [_frac(f), w], _frac(product), "%s*%d.0" % [_ef(f), w],
		[str(f.x * w), _frac(_reduce(Vector2i(f.x, f.y * w))), str(w)])


func _f_div() -> Dictionary:
	var a := _rand_frac(6)
	var b := _rand_frac(6)
	var quotient := _div(a, b)
	return _choice("What is %s ÷ %s?" % [_frac(a), _frac(b)], _frac(quotient), "(%s)/(%s)" % [_ef(a), _ef(b)],
		[_frac(_mul(a, b)), _frac(_div(b, a)), _frac(_reduce(Vector2i(a.x * b.y + 1, a.y * b.x)))])


func _f_div_whole() -> Dictionary:
	var f := _rand_frac(6)
	var w := rng.randi_range(2, 5)
	var quotient := _div(f, _n(w))
	return _choice("What is %s ÷ %d?" % [_frac(f), w], _frac(quotient), "(%s)/%d.0" % [_ef(f), w],
		[_frac(_mul(f, _n(w))), _frac(f), _frac(_reduce(Vector2i(f.x, f.y + w)))])


func _f_simplify() -> Dictionary:
	var f := _rand_frac(9)
	var k := rng.randi_range(2, 6)
	return _choice("Simplify %d/%d." % [f.x * k, f.y * k], _frac(f), "%d.0/%d" % [f.x * k, f.y * k],
		[_frac(_reduce(Vector2i(f.x, f.y * k))), _frac(_reduce(Vector2i(f.x * k, f.y))), _frac(_reduce(Vector2i(f.y, f.x)))])


func _f_equivalent() -> Dictionary:
	var f := _rand_frac(6)
	var k := rng.randi_range(2, 5)
	var answer := "%d/%d" % [f.x * k, f.y * k]
	return _choice("Which fraction is equal to %s?" % _frac(f), answer, _ef(f),
		["%d/%d" % [f.x * k, f.y], "%d/%d" % [f.x, f.y * k], "%d/%d" % [f.x * k + 1, f.y * k], "%d/%d" % [f.y, f.x]],
		_raw_frac)


func _f_to_mixed() -> Dictionary:
	var f := _improper()
	var whole := f.x / f.y
	var rest := f.x % f.y
	return _choice("Change %s to a mixed number." % _frac(f), _mixed(f), _ef(f),
		["%d %d/%d" % [whole + 1, rest, f.y], "%d %d/%d" % [rest, whole, f.y] if whole < f.y else "%d %d/%d" % [whole - 1, rest, f.y],
			"%d %d/%d" % [whole, f.y - rest, f.y]],
		_mixed)


func _f_to_improper() -> Dictionary:
	var f := _improper()
	var whole := f.x / f.y
	var rest := f.x % f.y
	return _choice("Change %s to an improper fraction." % _mixed(f), _frac(f), _expr_text(_mixed(f)),
		["%d/%d" % [whole + rest, f.y], "%d/%d" % [whole * f.y - rest, f.y], "%d/%d" % [f.y, f.x], "%d/%d" % [whole * rest + f.y, f.y]],
		_raw_frac)


func _f_greatest() -> Dictionary:
	return _f_order(true)


func _f_least() -> Dictionary:
	return _f_order(false)


func _f_order(greatest: bool) -> Dictionary:
	var values: Array[Vector2i] = []
	while values.size() < 4:
		var value := _rand_frac(10)
		if not _has_value(values, value):
			values.append(value)
	var best := values[0]
	for value in values:
		if (_less(best, value) if greatest else _less(value, best)):
			best = value
	var texts: Array = values.map(func(v: Vector2i) -> String: return _frac(v))
	var exprs: Array = values.map(func(v: Vector2i) -> String: return _ef(v))
	return _choice("Which fraction is the %s?" % ("greatest" if greatest else "least"), _frac(best),
		"%s(%s)" % ["max" if greatest else "min", ",".join(exprs)], texts)


func _f_pizza() -> Dictionary:
	var names: Array = _pick_two(NAMES)
	var d := rng.randi_range(4, 12)
	var a := rng.randi_range(1, d - 2)
	var b := rng.randi_range(1, d - 1 - a)
	var sum := _reduce(Vector2i(a + b, d))
	return _choice("%s ate %d/%d of a pizza and %s ate %d/%d of the same pizza. How much did they eat together?" % [names[0], a, d, names[1], b, d],
		_frac(sum), "%d.0/%d+%d.0/%d" % [a, d, b, d],
		[_frac(_reduce(Vector2i(a + b, d * 2))), _frac(_reduce(Vector2i(absi(a - b), d))), _frac(_reduce(Vector2i(d - a - b, d)))])


func _f_left() -> Dictionary:
	var d := rng.randi_range(3, 10)
	var have := rng.randi_range(2, d)
	var use := rng.randi_range(1, have - 1)
	var left := _reduce(Vector2i(have - use, d))
	var thing: String = ["cup of sugar", "liter of milk", "kilo of rice"][rng.randi_range(0, 2)]
	var unit: String = thing.split(" ")[0]
	return _choice("A jar has %s %s. You use %d/%d %s. How much is left?" % [_frac(_reduce(Vector2i(have, d))), thing, use, d, unit],
		_frac(left), "%d.0/%d-%d.0/%d" % [have, d, use, d],
		[_frac(_reduce(Vector2i(have + use, d))), _frac(_reduce(Vector2i(use, d))), _frac(_reduce(Vector2i(have - use, d * 2)))])


func _f_part_of() -> Dictionary:
	var f := _rand_frac(6)
	var group := f.y * rng.randi_range(2, 6)
	var answer := group / f.y * f.x
	var thing: String = ["marbles", "stickers", "pencils", "candies"][rng.randi_range(0, 3)]
	return _choice("%s has %d %s and gives away %s of them. How many %s is that?" % [_name(), group, thing, _frac(f), thing],
		str(answer), "%d.0*%s" % [group, _ef(f)],
		[str(group / f.y), str(group - answer), str(answer + f.x)])


# ---------- stage 3: fractions and decimals, typed ----------

func _t_to_decimal() -> Dictionary:
	var f := _clean_frac()
	return _typed("Write %s as a decimal." % _frac(f), _dec(f), _ef(f))


func _t_to_fraction() -> Dictionary:
	var f := _clean_frac()
	return _typed("Write %s as a fraction in lowest terms." % _dec(f), _frac(f), _ef(f))


func _t_add() -> Dictionary:
	var f := _clean_frac()
	var x := _rand_dec(0, 3, rng.randi_range(1, 2))
	var parts := [_frac(f), _dec(x)]
	_shuffle(parts)
	return _typed("What is %s + %s?" % parts, _dec(_add(f, x)), _expr_text(parts[0]) + "+" + _expr_text(parts[1]))


func _t_subtract() -> Dictionary:
	var f := _clean_frac()
	var x := _add(f, _rand_dec(0, 3, rng.randi_range(1, 2)))
	if rng.randf() < 0.5 and _less(Vector2i(1, 10), f):
		var small := _rand_dec(0, 0, 1)
		while not _less(small, f):
			small = _rand_dec(0, 0, 1)
		return _typed("What is %s − %s?" % [_frac(f), _dec(small)], _dec(_sub(f, small)), _ef(f) + "-" + _ed(small))
	return _typed("What is %s − %s?" % [_dec(x), _frac(f)], _dec(_sub(x, f)), _ed(x) + "-" + _ef(f))


func _t_multiply() -> Dictionary:
	var f := _clean_frac()
	var x := _rand_dec(0, 4, 1)
	return _typed("What is %s × %s?" % [_frac(f), _dec(x)], _dec(_mul(f, x)), _ef(f) + "*" + _ed(x))


func _t_divide() -> Dictionary:
	var w := rng.randi_range(2, 5)
	var answer := _rand_dec(0, 2, 2)
	var total := _mul(answer, _n(w))
	return _typed("What is %s ÷ %d?" % [_dec(total), w], _dec(answer), "%s/%d.0" % [_ed(total), w])


func _t_halve() -> Dictionary:
	var f := _clean_frac()
	return _typed("What is %s ÷ 0.5?" % _frac(f), _dec(_mul(f, _n(2))), "(%s)/0.5" % _ef(f))


func _t_greater() -> Dictionary:
	return _t_compare(true)


func _t_less() -> Dictionary:
	return _t_compare(false)


func _t_compare(greater: bool) -> Dictionary:
	var f := _clean_frac()
	var x := _rand_dec(0, 0, rng.randi_range(1, 2))
	while x == f:
		x = _rand_dec(0, 0, rng.randi_range(1, 2))
	var pick: Vector2i = f if _less(x, f) == greater else x
	var answer := _frac(f) if pick == f else _dec(x)
	var parts := [_dec(x), _frac(f)]
	_shuffle(parts)
	var word := "greater" if greater else "less"
	return _typed("Which is %s: %s or %s? Type the %s one." % [word, parts[0], parts[1], "greater" if greater else "lesser"],
		answer, "%s(%s,%s)" % ["max" if greater else "min", _ed(x), _ef(f)])


func _t_mixed_add() -> Dictionary:
	var whole := rng.randi_range(1, 4)
	var f := _clean_frac()
	var mixed := _add(_n(whole), f)
	var x := _rand_dec(0, 2, 2)
	return _typed("What is %s + %s?" % [_mixed(mixed), _dec(x)], _dec(_add(mixed, x)), _expr_text(_mixed(mixed)) + "+" + _ed(x))


func _t_juice() -> Dictionary:
	var drink := _clean_frac()
	var have := _add(drink, _rand_dec(0, 2, 1))
	return _typed("%s has %s liters of juice and drinks %s liter. How many liters are left?" % [_name(), _dec(have), _frac(drink)],
		_dec(_sub(have, drink)), _ed(have) + "-" + _ef(drink))


func _t_rope() -> Dictionary:
	var a := _add(_n(rng.randi_range(1, 4)), _clean_frac())
	var b := _rand_dec(0, 3, 2)
	return _typed("A %s m rope is tied to a %s m rope. How long are they in all, in meters?" % [_mixed(a), _dec(b)],
		_dec(_add(a, b)), _expr_text(_mixed(a)) + "+" + _ed(b))


# ---------- building questions ----------

func _typed(text: String, answer: String, check: String) -> Dictionary:
	return {"q": text, "a": answer, "check": check}


## Keeps three wrong choices that differ from the answer and from each other,
## then tops up with nearby numbers if some were too alike.
func _choice(text: String, answer: String, check: String, wrong: Array, style := Callable()) -> Dictionary:
	var choices: Array = [answer]
	var candidates := wrong.duplicate()
	_shuffle(candidates)
	for candidate: String in candidates:
		if choices.size() < 4 and _usable(candidate, choices):
			choices.append(candidate)
	var target := MathAnswer.parse(answer)
	var guard := 0
	while choices.size() < 4 and guard < 200:
		guard += 1
		var candidate := _nearby(answer, target, style)
		if _usable(candidate, choices):
			choices.append(candidate)
	return {"q": text, "a": answer, "choices": choices, "check": check}


func _usable(candidate: String, choices: Array) -> bool:
	var value := MathAnswer.parse(candidate)
	if is_nan(value) or value <= 0.0 or candidate.begins_with("0 ") or candidate.contains(" 0/"):
		return false
	for choice: String in choices:
		if MathAnswer.same_value(choice, candidate):
			return false
	return true


func _nearby(answer: String, target: float, style: Callable) -> String:
	if style.is_valid():
		var value := _to_frac_value(answer)
		var step := Vector2i(rng.randi_range(1, 3), value.y)
		var near := _add(value, step) if rng.randf() < 0.6 or not _less(step, value) else _sub(value, step)
		return style.call(near)
	if answer.contains("/"):
		var value := _to_frac_value(answer)
		var options: Array[Vector2i] = [Vector2i(value.x + 1, value.y), Vector2i(maxi(value.x - 1, 1), value.y),
			Vector2i(value.x, value.y + 1), Vector2i(value.x + 1, value.y + 1)]
		return _frac(_reduce(options[rng.randi_range(0, options.size() - 1)]))
	var places := answer.get_slice(".", 1).length() if answer.contains(".") else 0
	var step := Vector2i(rng.randi_range(1, 9), int(pow(10, places)))
	if places == 0:
		step = _n(rng.randi_range(1, 3))
	var value := _to_frac_value(answer)
	var near := _add(value, step) if rng.randf() < 0.5 or not _less(step, value) else _sub(value, step)
	return _dec(near) if target != floorf(target) or places > 0 else str(near.x / near.y)


# ---------- number helpers ----------

func _n(whole: int) -> Vector2i:
	return Vector2i(whole, 1)


static func _gcd(a: int, b: int) -> int:
	a = absi(a)
	b = absi(b)
	while b != 0:
		var t := b
		b = a % b
		a = t
	return maxi(a, 1)


static func _reduce(v: Vector2i) -> Vector2i:
	var g := _gcd(v.x, v.y)
	return Vector2i(v.x / g, v.y / g)


static func _add(a: Vector2i, b: Vector2i) -> Vector2i:
	return _reduce(Vector2i(a.x * b.y + b.x * a.y, a.y * b.y))


static func _sub(a: Vector2i, b: Vector2i) -> Vector2i:
	return _reduce(Vector2i(a.x * b.y - b.x * a.y, a.y * b.y))


static func _mul(a: Vector2i, b: Vector2i) -> Vector2i:
	return _reduce(Vector2i(a.x * b.x, a.y * b.y))


static func _div(a: Vector2i, b: Vector2i) -> Vector2i:
	return _reduce(Vector2i(a.x * b.y, a.y * b.x))


static func _less(a: Vector2i, b: Vector2i) -> bool:
	return a.x * b.y < b.x * a.y


static func _has_value(values: Array[Vector2i], v: Vector2i) -> bool:
	for other in values:
		if _reduce(other) == _reduce(v):
			return true
	return false


## The value times `scale`, as a whole number (for exact rounding).
static func _scaled(v: Vector2i, scale: int) -> int:
	return v.x * scale / v.y


## A decimal between lo and hi + 1 with exactly `places` digits after the
## point (the last digit is never 0).
func _rand_dec(lo: int, hi: int, places: int) -> Vector2i:
	var bottom := int(pow(10, places))
	var digits := rng.randi_range(1, bottom - 1)
	while digits % 10 == 0:
		digits = rng.randi_range(1, bottom - 1)
	return _reduce(Vector2i(rng.randi_range(lo, hi) * bottom + digits, bottom))


## A proper fraction in lowest terms with a bottom up to `max_bottom`.
## Every such fraction is equally likely, so 1/2 doesn't come up too often.
func _rand_frac(max_bottom: int) -> Vector2i:
	return _pick_fraction(range(2, max_bottom + 1))


## A proper fraction that ends as a decimal, like 3/4 or 2/5.
func _clean_frac() -> Vector2i:
	return _pick_fraction(CLEAN_BOTTOMS)


func _pick_fraction(bottoms: Array) -> Vector2i:
	var options: Array[Vector2i] = []
	for d: int in bottoms:
		for n in range(1, d):
			if _gcd(n, d) == 1:
				options.append(Vector2i(n, d))
	return options[rng.randi_range(0, options.size() - 1)]


## An improper fraction that is not a whole number, like 7/4.
func _improper() -> Vector2i:
	while true:
		var d := rng.randi_range(2, 9)
		var n := d * rng.randi_range(1, 4) + rng.randi_range(1, d - 1)
		if _gcd(n, d) == 1:
			return Vector2i(n, d)
	return Vector2i(3, 2)


func _two_fractions(small_sum: bool) -> Array:
	var bottoms := [2, 3, 4, 5, 6, 8, 10, 12]
	while true:
		var a := _pick_fraction(bottoms)
		var b := _pick_fraction(bottoms)
		if a.y == b.y or a == b:
			continue
		if small_sum and not _less(_add(a, b), _n(1)):
			continue
		return [a, b]
	return [Vector2i(1, 2), Vector2i(1, 3)]


## A decimal like 4.237 whose digits are all different.
func _distinct_digit_decimal() -> Vector2i:
	while true:
		var whole := rng.randi_range(1, 99)
		var number := _add(_n(whole), _rand_dec(0, 0, 3))
		var text := _dec(number).replace(".", "")
		var unique := {}
		for ch in text:
			unique[ch] = true
		if unique.size() == text.length() and not text.contains("0") and _dec(number).get_slice(".", 1).length() == 3:
			return number
	return Vector2i(4237, 1000)


func _digit_at(v: Vector2i, place: int) -> String:
	return str(_scaled(v, int(pow(10, place))) % 10)


## Reading the digits without lining up the points: 0.6 + 0.25 → 0.31.
func _misaligned(a: Vector2i, b: Vector2i) -> Vector2i:
	var at := _dec(a)
	var bt := _dec(b)
	var places := maxi(_places(at), _places(bt))
	return _reduce(Vector2i(int(at.replace(".", "")) + int(bt.replace(".", "")), int(pow(10, places))))


static func _places(text: String) -> int:
	return text.get_slice(".", 1).length() if text.contains(".") else 0


func _pick_two(items: Array) -> Array:
	var copy := items.duplicate()
	_shuffle(copy)
	return [copy[0], copy[1]]


func _name() -> String:
	return NAMES[rng.randi_range(0, NAMES.size() - 1)]


func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = items[i]
		items[i] = items[j]
		items[j] = t


# ---------- writing numbers ----------

## 3/4 → "0.75". Only for fractions that end as decimals.
static func _dec(v: Vector2i) -> String:
	v = _reduce(v)
	var bottom := 1
	var places := 0
	while bottom % v.y != 0 and places < 6:
		bottom *= 10
		places += 1
	var scaled := v.x * (bottom / v.y)
	var whole := scaled / bottom
	if places == 0:
		return str(whole)
	var rest := str(scaled % bottom).pad_zeros(places).rstrip("0")
	return str(whole) if rest.is_empty() else "%d.%s" % [whole, rest]


## Pesos always show two places: 24.50.
static func _money(v: Vector2i) -> String:
	var cents := v.x * 100 / v.y
	return "%d.%02d" % [cents / 100, cents % 100]


static func _frac(v: Vector2i) -> String:
	v = _reduce(v)
	return str(v.x) if v.y == 1 else "%d/%d" % [v.x, v.y]


## Writes the fraction as it is, without simplifying (for equivalent fractions).
static func _raw_frac(v: Vector2i) -> String:
	return "%d/%d" % [v.x, v.y]


static func _mixed(v: Vector2i) -> String:
	v = _reduce(v)
	if v.x < v.y or v.y == 1:
		return _frac(v)
	return "%d %d/%d" % [v.x / v.y, v.x % v.y, v.y]


## Math expressions for the tests, built from the number exactly as it is shown.
static func _ed(v: Vector2i) -> String:
	return _expr_text(_dec(v))


static func _ef(v: Vector2i) -> String:
	return _expr_text(_frac(v))


static func _expr_text(text: String) -> String:
	if text.contains(" "):
		var whole := text.get_slice(" ", 0)
		var part := text.get_slice(" ", 1)
		return "(%s.0+%s.0/%s)" % [whole, part.get_slice("/", 0), part.get_slice("/", 1)]
	if text.contains("/"):
		return "(%s.0/%s)" % [text.get_slice("/", 0), text.get_slice("/", 1)]
	return text if text.contains(".") else text + ".0"


## Reads "3/4", "1 3/4", "0.75" or "2" back into an exact fraction.
static func _to_frac_value(text: String) -> Vector2i:
	if text.contains(" "):
		var whole := int(text.get_slice(" ", 0))
		var part := _to_frac_value(text.get_slice(" ", 1))
		return _add(Vector2i(whole, 1), part)
	if text.contains("/"):
		return Vector2i(int(text.get_slice("/", 0)), int(text.get_slice("/", 1)))
	if text.contains("."):
		var places := _places(text)
		return _reduce(Vector2i(int(text.replace(".", "")), int(pow(10, places))))
	return Vector2i(int(text), 1)
