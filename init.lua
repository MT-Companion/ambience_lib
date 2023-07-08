--[[
    ambience_lib: Minetest API for playing background musics
    Copyright (C) 2023  1F616EMO

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

ambience_lib = {}
local S = minetest.get_translator("ambience_lib")

-- Validate SimpleSoundSpec
-- ambience_lib does not accept empty sounds
-- Additional parameters:
--  title: Name of the track
--  artist: Artist of the track
function ambience_lib.validate_SimpleSoundSpec(name,spec)
    if type(spec) == "string" then
        -- Change it into table form
        spec = {name = spec}
    end
    assert(type(spec) == "table","[ambience_lib] Invalid spec data type")
    assert(type(spec.name) == "string","[ambience_lib] Invalid name data type")

    if spec.gain then
        assert(type(spec.gain) == "number" and spec.gain >= 0,"[ambience_lib] Invalid gain value")
    end

    if spec.pitch then
        assert(type(spec.pitch) == "number" and spec.pitch >= 0,"[ambience_lib] Invalid pitch value")
    end

    if spec.fade then
        assert(type(spec.fade) == "number" and spec.fade >= 0,"[ambience_lib] Invalid fade value")
        spec.fade = math.min(spec.fade,spec.gain)
    end

    if not spec.title then
        spec.title = name
    end
    if not spec.artist then
        spec.artist = S("Unknown Artist")
    end
    
    return spec
end

function ambience_lib.spec_drop_custom_fields(spec)
    ---@diagnostic disable-next-line: undefined-field
    spec = table.copy(spec)
    spec.title = nil
    spec.artist = nil
    return spec
end

ambience_lib.registered_sounds = {} -- Table of SimpleSoundSpec
function ambience_lib.register_sound(name,spec)
    spec = ambience_lib.validate_SimpleSoundSpec(name,spec)
    ambience_lib.registered_sounds[name] = spec
end

-- func(name,spec_name)
ambience_lib.registered_on_play_ambience = {}
function ambience_lib.register_on_play_ambience(func)
    ambience_lib.registered_on_play_ambience[#ambience_lib.registered_on_play_ambience + 1] = func
end

-- Data about ambient being played on a player
-- Key: Player name
-- Value: {<name>,<handle>,<handle_type>}
-- handle_type: sound (sound handle) or after (minetest.after handler)
ambience_lib.player_sounds = {}

function ambience_lib.validate_parameter(param,spec,player_name)
    if type(param) == "nil" then
        param = {}
    end

    -- Drop invalid parameters
    for _,k in ipairs({"loop","pos","object","to_player","exclude_player","max_hear_distance"}) do
        if param[k] ~= nil then
            minetest.log("warning",string.format("[ambience_lib] Key %s found in params, dropped.",k))
            param[k] = nil
        end
    end

    -- Only that player can hear
    param.to_player = player_name

    -- loop is always true for ambience
    param.loop = true

    if param.gain then
        assert(type(param.gain) == "number" and spec.gain >= 0,"[ambience_lib] Invalid gain value in param")
    end

    if param.pitch then
        assert(type(param.pitch) == "number" and spec.pitch >= 0,"[ambience_lib] Invalid pitch value in param")
    end

    if param.fade then
        assert(type(param.fade) == "number" and spec.fade >= 0,"[ambience_lib] Invalid fade value in param")
        param.fade = math.min(param.fade,spec.gain)
    end

    return param
end

function ambience_lib.delayed_play(name,sound_name,spec,param)
    local handle = minetest.sound_play(spec,param,false)
    ambience_lib.player_sounds[name] = {sound_name,handle,"sound"}
end

function ambience_lib.set_ambience(name,sound_name,param,fade_step,delay_play)
    -- Check whether 
    local spec = ambience_lib.registered_sounds[sound_name]
    if not spec then
        return false, "SPEC_NOT_REGISTERED"
    end
    spec = ambience_lib.spec_drop_custom_fields(spec)

    param = ambience_lib.validate_parameter(param,spec,name)

    if ambience_lib.player_sounds[name] then
        -- Don't touch it if the same
        if ambience_lib.player_sounds[name][1] == sound_name then
            return false, "SAME"
        end

        -- Stop the previous ambience, if any
        local old_handle = ambience_lib.player_sounds[name][2]
        local handle_type = ambience_lib.player_sounds[name][3]
        if handle_type == "sound" then
            if fade_step and fade_step > 0 then
                minetest.sound_fade(old_handle,fade_step,0)
            else
                minetest.sound_stop(old_handle)
            end
        elseif handle_type == "after" then
            old_handle:cancel()
        end
    end

    for _,func in ipairs(ambience_lib.registered_on_play_ambience) do
        func(name,sound_name)
    end

    local after_handle = minetest.after(delay_play or 0,ambience_lib.delayed_play,name,sound_name,spec,param)
    ambience_lib.player_sounds[name] = {sound_name,after_handle,"after"}
    return true
end

function ambience_lib.stop_ambience(name,fade_step)
    if ambience_lib.player_sounds[name] then
        local old_handle = ambience_lib.player_sounds[name][2]
        local handle_type = ambience_lib.player_sounds[name][3]
        if handle_type == "sound" then
            if fade_step and fade_step > 0 then
                minetest.sound_fade(old_handle,fade_step,0)
            else
                minetest.sound_stop(old_handle)
            end
        elseif handle_type == "after" then
            old_handle:cancel()
        end

        for _,func in ipairs(ambience_lib.registered_on_play_ambience) do
            func(name,"")
        end

        ambience_lib.player_sounds[name] = nil
    end
end

minetest.register_on_leaveplayer(function(player, timed_out)
    local name = player:get_name()
    ambience_lib.stop_ambience(name)
end)

ambience_lib.register_sound("ambience_lib:white_noise",{
    name = "sox-white",
    title = S("White Noise"),
    artist = S("Dave Null"),
    gain = 0.05,
    fade = 0.02
})

ambience_lib.register_sound("ambience_lib:ocean_noise",{
    name = "sox-ocean",
    title = S("Ocean Noise"),
    artist = S("Byte Commander"),
    gain = 0.1,
    fade = 0.02
})

local cmd = chatcmdbuilder.register("ambience", {
	description = S("View or set the current ambience"),
    privs = {server = true},
})

cmd:sub("get",function(name)
    if ambience_lib.player_sounds[name] then
        local spec_name = ambience_lib.player_sounds[name][1]
        local spec = ambience_lib.registered_sounds[spec_name]
        return true, S("Currently playing @1 by @1",spec.title,spec.artist)
    else
        return false, S("No ambiences are playing.")
    end
end)

cmd:sub("get :username:username",function(name,username)
    if ambience_lib.player_sounds[username] then
        local spec_name = ambience_lib.player_sounds[username][1]
        local spec = ambience_lib.registered_sounds[spec_name]
        return true, S("Currently playing @1 by @2 for @3",spec.title,spec.artist,username)
    else
        return false, S("No ambiences are playing for @1.",username)
    end
end)

cmd:sub("set :specname:word",function(name,specname)
    local status, msg = ambience_lib.set_ambience(name,specname,{},nil,2)
    if status then
        return true, S("Successfully set ambience to @1.",specname)
    else
        return false, S("Failed to set ambience @1. (@2)",specname,msg)
    end
end)

cmd:sub("set :username:username :specname:word",function(name,username,specname)
    local status, msg = ambience_lib.set_ambience(username,specname,{},nil,2)
    if status then
        return true, S("Successfully set ambience to @1 for @2.",specname,username)
    else
        return false, S("Failed to set ambience @1 for @2. (@3)",specname,username,msg)
    end
end)

cmd:sub("stop",function(name)
    if ambience_lib.player_sounds[name] then
        ambience_lib.stop_ambience(name)
        return true, S("Ambience stopped.")
    else
        return false, S("No ambiences are playing.")
    end
end)

cmd:sub("stop :username:username",function(name,username)
    if ambience_lib.player_sounds[username] then
        ambience_lib.stop_ambience(username)
        return true, S("Ambience stopped for @1.",username)
    else
        return false, S("No ambiences are playing for @1.",username)
    end
end)

local MP = minetest.get_modpath("ambience_lib")
dofile(MP .. "/hud.lua")
