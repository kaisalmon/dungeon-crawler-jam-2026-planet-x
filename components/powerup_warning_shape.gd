extends Area3D

var triggered = false
func _ready():
    connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
    if triggered:
        return
    if not body.get_parent().is_in_group("player"):
        return
    var player: Player = Globals.getPlayer()

    if player.max_shields == 0 and player.max_health < 5 and player.has_gun_upgrade:
        triggered = true
        player.in_cutscene = true
        Globals.say("\"I can tell the Master AI is close...\"")
        Globals.say("\"...I might not be ready for this fight.\"")
        Globals.say("\"Maybe I should try to find some more upgrades.\"")
        await get_tree().create_timer(11.0).timeout
        Analytics.track("powerup_warning_seen", {
            "max_health": player.max_health,
        })
        player.in_cutscene = false
