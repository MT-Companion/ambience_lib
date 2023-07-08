# ambience_lib

Minetest API for playing background musics

## API

### `ambience_lib.validate_SimpleSoundSpec(name: string, spec: SimpleSoundSpec) -> SimpleSoundSpec`

*INTERNAL:* Validate the contents of a SimpleSoundSpec and return the altered version.

* `name`: The name of the SimpleSoundSpec, as in [`ambience_lib.register_sound(name,spec)`](#ambience_libregister_soundname-string-spec-simplesoundspec)
* `spec`: The original SimpleSoundSpec

Note that this function does not accept empty sound filenames.

### `ambience_lib.spec_drop_custom_fields(spec: SimpleSoundSpec) -> SimpleSoundSpec`

*INTERNAL:* Drops custom fields in the given SimpleSoundSpec, and return the altered version. The original SimpleSoundSpec will be untouched.

The following fields are dropped: `title` and `artist`.

### `ambience_lib.register_sound(name: string, spec: SimpleSoundSpec)`

Register an ambience that can be used in `ambience_lib.set_ambience`.

* `name`: The name of the SimpleSoundSpec
* `spec`: The SimpleSoundSpec to be played once set

### `ambience_lib.register_on_play_ambience(func: function)`

Register a callback to be called when a ambience is set

The function should accept two parameters: `name` and `spec_name`. `name` is the target player name. `spec_name` is the name of the SimpleSoundSpec as in [`ambience_lib.register_sound(name,spec)`](#ambience_libregister_soundname-string-spec-simplesoundspec), or empty if one is stopped.

Note that the callbacks will once be called once with the new `spec_name` if one is replacing another one. Also, the callback will not be called on player leave.

### `ambience_lib.validate_parameter(param: SoundParameterTable, spec: SimpleSoundSpec, player_name: string) -> SoundParameterTable`

*INTERNAL:* Validate the fields of a sound parameter table, and return the altered version.

This function will do the following:

1. Drop the following fields if set: `loop`, `pos`, `object`, `to_player`, `exclude_player`, `max_hear_distance`
2. Set `to_player` to the given player name
3. Set `loop` to `true`
4. Validate the range of values of `gain`, `pitch` and `fade`.

### `ambience_lib.delayed_play(name: string, sound_name: string, spec: SimpleSoundSpec, param: SoundParameterTable)`

*INTERNAL:* To be used in `minetest.after` calls for delaying sound play.

### `ambience_lib.set_ambience(name: string, sound_name: string, param: SoundParameterTable, fade_step: number, delay_play: number) -> boolean, string`

Play a [registered](#ambience_libregister_soundname-string-spec-simplesoundspec) ambience for a player.

* `name`: The name of the target player
* `sound_name`: The name of the SimpleSoundSpec, as in [`ambience_lib.register_sound(name,spec)`](#ambience_libregister_soundname-string-spec-simplesoundspec)
* `param`: A SoundParameterTable, see [`ambience_lib.validate_parameter`](#ambience_libvalidate_parameterparam-soundparametertable-spec-simplesoundspec-player_name-string---soundparametertable) for the valid format of it
* `fade_step`: If present and not `0`, the old sound's gain will be reduced by this value each second
* `delay_play`: Seconds of delays before the sound is played

### `ambience_lib.stop_ambience(name:string, fade_step:number)`

Stop or fade out the ambience of a player

* `name`: The name of the target player
* `fade_step`: If present and not `0`, the old sound's gain will be reduced by this value each second
