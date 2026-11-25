class_name Ranks
extends RefCounted
## Ränge als Zahlen: D=1, C=2, B=3, A=4, S=5, SS=6.

const LETTERS := ["D", "C", "B", "A", "S", "SS"]


static func from_letter(s: String) -> int:
	return LETTERS.find(s) + 1


static func to_letter(r: int) -> String:
	return LETTERS[clampi(r, 1, 6) - 1]
