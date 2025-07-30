extends Label3D

var score: int = 0

# Make this node globally accessible via the autoload singleton (optional)
static var instance: Label3D = null

func _ready():
	instance = self
	update_score_display()

func add_score(amount: int):
	score += amount
	update_score_display()

func update_score_display():
	text = "Score: %d" % score

# Static helper so other scripts can do:
# ScoreLabel3D.instance.add_score(100)
