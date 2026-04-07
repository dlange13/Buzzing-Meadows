class_name SaveData
extends Resource

## SaveData — Serializable container for all game state.
## Written to and read from disk by GameManager.save_game() / load_game()
## using Godot's ResourceSaver / ResourceLoader.
##
## All sub-resources (HiveData, TreatmentData) are serialized inline by
## ResourceSaver.FLAG_CHANGE_PATH, so a single .tres file holds everything.

@export var player_name: String = "Keeper"
@export var current_day: int = 1
@export var total_days_elapsed: int = 0
@export var honey_coins: int = 50

## Season state — which season index and day within that season at save time.
@export var current_season_index: int = 0
@export var day_in_season: int = 1

## All player-owned hives at time of save, including their treatment state.
@export var hives: Array[HiveData] = []
