extends VBoxContainer

@onready var lotanlabel: Label = $Lotans


func _on_game_lotan_change(amount) -> void:
	lotanlabel.text = str(amount) + " Lotans"
	
