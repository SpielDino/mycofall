class_name PlayerKeybindResource
extends Resource

const MOVE_FORWARD: String = "move_forward";
const MOVE_LEFT: String = "move_left";
const MOVE_RIGHT: String = "move_right";
const MOVE_BACKWARD: String = "move_backward";

const DODGE: String = "dodge"
const SNEAK: String = "sneak"

const ATTACK: String = "attack"
const BLOCK: String = "block"
const HEAVY_ATTACK: String = "heavy_attack"
const SWAP_WEAPON: String = "swap_weapon"

const INTERACT: String = "interact"
const PAUSE: String = "pause"

# you cannot export constants, these are NOT to be changed in code
@export var DEFAULT_MOVE_FORWARD_KEY: InputEvent = InputEventKey.new();
@export var DEFAULT_MOVE_LEFT_KEY: InputEvent = InputEventKey.new();
@export var DEFAULT_MOVE_RIGHT_KEY: InputEvent = InputEventKey.new();
@export var DEFAULT_MOVE_BACKWARD_KEY: InputEvent = InputEventKey.new();

@export var DEFAULT_DODGE_KEY: InputEvent = InputEventKey.new()
@export var DEFAULT_SNEAK_KEY: InputEvent = InputEventKey.new();

@export var DEFAULT_ATTACK_KEY: InputEvent = InputEventMouseButton.new();
@export var DEFAULT_BLOCK_KEY: InputEvent = InputEventMouseButton.new();
@export var DEFAULT_HEAVY_ATTACK_KEY: InputEvent = InputEventMouseButton.new();
@export var DEFAULT_SWAP_WEAPON_KEY: InputEvent = InputEventKey.new();

@export var DEFAULT_INTERACT_KEY: InputEvent = InputEventKey.new();
@export var DEFAULT_PAUSE_KEY: InputEvent = InputEventKey.new()

var move_forward_key = InputEventKey.new();
var move_left_key = InputEventKey.new();
var move_right_key = InputEventKey.new();
var move_backward_key = InputEventKey.new();

var dodge_key = InputEventKey.new();
var sneak_key = InputEventKey.new();

var attack_key = InputEventMouseButton.new()
var block_key = InputEventMouseButton.new();
var heavy_attack_key = InputEventMouseButton.new();
var swap_weapon_key = InputEventKey.new();

var interact_key = InputEventKey.new();
var pause_key = InputEventKey.new();
