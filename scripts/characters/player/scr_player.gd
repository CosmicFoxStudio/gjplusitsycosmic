class_name Player extends Character

# enum ePlayerState { ACTIVE, INACTIVE, TALKING, MENU, WARPING }

# Get input dynamically (read-only)
var direction: float:
	get:
		return Input.get_axis("move_left", "move_right") * properties.speed
var jump: float:
	get: return Input.is_action_pressed("jump")
var attack: bool:
	get: return Input.is_action_just_pressed("basic_attack")

# Keyboard Pressure Variables
var minPressure: float = 0.8
var maxPressure: float = 8.0
var pressureThreshold: float = 8.0
var pressure: float = 0.0

func _ready() -> void:
	super()
	type = eType.PLAYER
	
	# Get player properties
	if Global.playerResource != null:
		properties = Global.playerResource

func _process(delta: float) -> void:
	super(delta)
	
	if (Global.pause):
		ChangeState(eState.IDLE)

	## Handle pressure logic only when jump is pressed
	#if jump:
		#pressure += delta * 10.0
	#else:
		#pressure -= delta * 15.0
#
	## Clamp pressure between min and max
	#pressure = clamp(pressure, minPressure, maxPressure)

func EnablePlayerMovement() -> void:
	if direction:
		velocity.x = direction * properties.speed
	else:
		velocity.x = move_toward(velocity.x, 0, properties.speed)

# State Overrides
func StateIdle() -> void:
	if dead: return
	
	PlayAnimation("idle")
	StopMovement()
	
	if direction: ChangeState(eState.WALK)
	if jump: ChangeState(eState.JUMP)
	if attack: ChangeState(eState.ATTACK1)

func StateWalk() -> void:
	if dead: return
	
	PlayAnimation("walk")
	EnablePlayerMovement()
	Flip()
	
	if not direction: ChangeState(eState.IDLE)
	if jump: ChangeState(eState.JUMP)
	if attack: ChangeState(eState.ATTACK1)

# Handle input for jumping
func StateJump() -> void:
	if dead: return
	
	PlayAnimation("jump")
	EnablePlayerMovement()
	
	if is_on_floor():
		# Ensure pressure starts at minimum when jump is triggered
		if pressure <= minPressure:
			pressure = minPressure
		
		# Build pressure while the jump key is held
		if Input.is_action_pressed("jump"):
			pressure += get_process_delta_time() * 20.0  # Faster pressure accumulation
			pressure = clamp(pressure, minPressure, maxPressure)
		else:
			# Apply jump velocity when jump key is released
			var default_jump_strength = 0.5  # Default jump strength (50% of max)
			var jump_strength = max(default_jump_strength, pressure / maxPressure)
			velocity.y = -properties.jump_velocity * jump_strength
			print("Jumping with strength:", jump_strength, "Velocity:", velocity.y)
			
			# Reset pressure for the next jump
			pressure = 0
	
	# Transition to falling state if airborne
	if velocity.y > 0:
		ChangeState(eState.FALL)

func StateFall() -> void:
	PlayAnimation("fall")
	EnablePlayerMovement()

	# Transition to idle when landing
	if is_on_floor():
		print("Is on floor")
		ChangeState(eState.IDLE)

func _debug() -> void:
	Global.debug.UpdateDebugVariable(0, "Velocity X: " + str(velocity.x))
	Global.debug.UpdateDebugVariable(1, "Velocity Y: " + str(velocity.y))
	Global.debug.UpdateDebugVariable(2, "State: " + str(eState.keys()[state]))
	Global.debug.UpdateDebugVariable(3, "Direction: " + str(direction))
	Global.debug.UpdateDebugVariable(4, "Jump: " + str(jump))
	Global.debug.UpdateDebugVariable(5, "Attack: " + str(attack))
