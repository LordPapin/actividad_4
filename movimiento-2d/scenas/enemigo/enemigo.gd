extends CharacterBody2D

# --- VARIABLES DEL INSPECTOR ---
@export var speed_patrol: float = 100.0
@export var speed_chase: float = 200.0
@export var damage_amount: int = 1

#  DEFINIR LOS ESTADOS DEL ENEMIGO
enum State { PATROL, CHASE, ATTACK }
var current_state = State.PATROL

# Variables de control
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = 1 # 1 para moverse a la derecha, -1 para la izquierda
var player_target = null # Aquí guardaremos al jugador cuando lo veamos

# Referencia al detector de bordes (precipicios)
@onready var ledge_check = $LedgeCheck

func _physics_process(delta):
	# Aplicar gravedad siempre
	if not is_on_floor():
		velocity.y += gravity * delta

	#  LA MÁQUINA DE ESTADOS DEL ENEMIGO
	match current_state:
		State.PATROL:
			patrol_state()
		State.CHASE:
			chase_state()
		State.ATTACK:
			attack_state()

	#  APLICAR FÍSICAS
	move_and_slide()


# --- LÓGICA DE CADA ESTADO ---

func patrol_state():
	# Si choca con una pared o el RayCast ya no toca el suelo (hay un precipicio)
	if is_on_wall() or not ledge_check.is_colliding():
		flip_direction() # Se da la vuelta

	velocity.x = direction * speed_patrol

func chase_state():
	if player_target:
		# Calculamos en qué dirección está el jugador respecto al enemigo
		var dir_to_player = sign(player_target.global_position.x - global_position.x)
		
		# Si el jugador está detrás del enemigo, se da la vuelta
		if dir_to_player != 0 and dir_to_player != direction:
			flip_direction()
		
		velocity.x = direction * speed_chase
	else:
		# Si por alguna razón perdemos la referencia, vuelve a patrullar
		current_state = State.PATROL

func attack_state():
	# Al atacar/hacer daño, el enemigo se detiene momentáneamente
	velocity.x = 0
	


# --- FUNCIONES AUXILIARES ---

func flip_direction():
	direction *= -1 # Invertimos la dirección matemática
	
	# Movemos el detector de precipicios al otro lado
	ledge_check.position.x *= -1 
	
	# Volteamos el dibujo del enemigo (si usas Sprite2D)
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = direction < 0


# --- SEÑALES DE DETECCIÓN (Conectar desde el editor) ---

#  Cuando algo entra en su rango de visión
func _on_vision_area_body_entered(body):
	# Verificamos que sea el jugador usando "Grupos"
	if body.is_in_group("player"):
		player_target = body
		current_state = State.CHASE

#  Cuando el jugador sale de su rango de visión
func _on_vision_area_body_exited(body):
	if body == player_target:
		player_target = null
		current_state = State.PATROL # Lo perdió de vista, vuelve a patrullar

#  Cuando toca físicamente al jugador (Daño)
func _on_hitbox_body_entered(body):
	if body.is_in_group("player"):
		current_state = State.ATTACK
		print("¡El enemigo ha tocado al jugador! Haciendo daño...")
		
