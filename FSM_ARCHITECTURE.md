# Finite State Machine (FSM) Architecture

This document outlines the FSM system used in the **Foxy Adventure** project. It is designed to manage character behaviors (especially enemies) through discrete states and transitions.

## Core Components

The system consists of three main scripts located in `scripts/fsm/`:

### 1. `FSM` (`scripts/fsm/fsm.gd`)
The central manager node that handles the current state, transitions, and updates.

*   **Responsibility**: Holds a registry of states, manages the current state, and calls `_enter`, `_exit`, and `_update` on states.
*   **Initialization**:
	*   Takes the target object (actor), a parent node containing state nodes, an initial state, and a debug flag.
	*   Scans the `states_parent_node` children and registers them in the `states` dictionary using their **lowercase** node names.
*   **Key Methods**:
	*   `change_state(new_state: FSMState)`: Schedules a transition to `new_state`. The transition happens during the next `_update` cycle.
	*   `_update(delta)`: Handles the actual switching of states (calling `_exit` on the old, `_enter` on the new) and runs the `current_state._update(delta)`.

### 2. `FSMState` (`scripts/fsm/state.gd`)
The base class for all states.

*   **Properties**:
	*   `fsm`: Reference to the `FSM` manager.
	*   `obj`: Reference to the `BaseCharacter` being controlled.
	*   `timer`: A utility float for time-based logic.
*   **Virtual Methods** (Override these):
	*   `_enter()`: Called when the state becomes active.
	*   `_exit()`: Called when transitioning out of this state.
	*   `_update(delta)`: Called every frame while active.
*   **Helper Methods**:
	*   `update_timer(delta) -> bool`: Decrements the internal timer and returns `true` if finished.
	*   `change_state(new_state)`: Proxy to call `fsm.change_state`.

### 3. `EnemyState` (`scripts/fsm/enemy_state.gd`)
An extension of `FSMState` specifically for enemy logic.

*   **Common logic**:
	*   `take_damage()`: Handles knockback and transitions to the `hurt` state.
	*   `control_walk()`: Handles movement and wall/ledge detection via `_should_turn_around()`.
	*   `_should_turn_around()`: Checks wall/fall flags on `obj` and flips direction.

## How to Use

### 1. Setting up the Node Structure
In your Character/Enemy scene:
1.  Add a `Node` to act as the container for all states (e.g., named `States`).
2.  Add child nodes to it, each with a script extending `FSMState` (or `EnemyState`).
	*   *Naming convention*: The node name determines the key in the dictionary (e.g., a node named "Idle" is accessed via `fsm.states.idle`).

```text
Enemy (CharacterBody2D)
├── States (Node)
│   ├── Idle (extends FSMState)
│   ├── Walk (extends FSMState)
│   └── Attack (extends FSMState)
```

### 2. Initializing the FSM
In the root script of your character (which should probably extend `BaseCharacter`), initialize the FSM in `_ready`:

```gdscript
var fsm: FSM

func _ready():
	# Arguments: target_obj (self), states_parent_node, initial_state, debug_mode
	fsm = FSM.new(self, $States, $States/Idle, true)

func _physics_process(delta):
	fsm._update(delta)
```

### 3. Creating a New State
Create a script extending `FSMState` (or `EnemyState`):

```gdscript
extends FSMState

func _enter():
	obj.animation_player.play("attack")
	timer = 0.5 # Set duration

func _update(delta):
	if update_timer(delta):
		change_state(fsm.states.idle) # Transition back to idle
```

## Conventions
*   **State Lookup**: States are stored by lowercase name. Access them via `fsm.states.state_name`.
*   **Deferred Transitions**: `change_state` does not switch immediately; it sets `_next_state`, which is applied at the start of the next `_update` call.
*   **Object Reference**: The `obj` variable in states is typed as `BaseCharacter`. Ensure your character scripts inherit from this or compatible types.
