class_name AdsConfig
extends Resource
## Switches and IDs for the ads layer. v1 ships with enabled = false and
## provider = "none": no ad SDK, no network calls, nothing collected.
## See docs/ADS_PLAN.md before turning anything on.

@export var enabled := false
## "none" | "debug" (fake ad screens, for testing flows) | "admob"
@export var provider := "none"
@export_group("AdMob IDs (Google's public test IDs until you have real ones)")
@export var admob_app_id_android := "ca-app-pub-3940256099942544~3347511713"
@export var rewarded_unit_android := "ca-app-pub-3940256099942544/5224354917"
@export var interstitial_unit_android := "ca-app-pub-3940256099942544/1033173712"
@export_group("Placements")
## Rewarded: player chooses to watch for a bonus.
@export var rewarded_placements := PackedStringArray(["double_credits", "free_item"])
## Interstitial only between cup races, never mid-race.
@export var interstitial_between_cup_races := true
@export_group("Frequency caps")
@export var min_sessions_before_interstitial := 2
@export var min_races_before_interstitial := 5
@export var races_between_interstitials := 3
@export_group("Audience & privacy")
## Set true if the game is listed for children under 13 (Families policy).
@export var child_directed := false
@export var max_ad_content_rating := "G"
@export var require_consent := true
