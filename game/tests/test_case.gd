class_name TestCase
extends RefCounted
## Basisklasse für Tests. Fehler werden gesammelt, nicht geworfen.

var failures: Array[String] = []


func assert_eq(a, b, msg := "") -> void:
	if a is StringName:
		a = String(a)
	if b is StringName:
		b = String(b)
	if typeof(a) != typeof(b) and not ((a is int or a is float) and (b is int or b is float)):
		failures.append("erwartet %s (%s), bekam %s (%s) %s" % [str(b), type_string(typeof(b)), str(a), type_string(typeof(a)), msg])
	elif a != b:
		failures.append("erwartet %s, bekam %s %s" % [str(b), str(a), msg])


func assert_true(c, msg := "") -> void:
	if not c:
		failures.append("erwartet wahr %s" % msg)


func assert_false(c, msg := "") -> void:
	if c:
		failures.append("erwartet falsch %s" % msg)


func assert_almost(a: float, b: float, eps := 0.001) -> void:
	if absf(a - b) > eps:
		failures.append("erwartet ~%s, bekam %s" % [b, a])
