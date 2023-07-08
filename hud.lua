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

local S = minetest.get_translator("ambience_lib")

local Z_INDEX = -1
local NO_AMBIENCE = "-- " .. S("no ambience") .. " --"

local hud_ids = {}

minetest.register_on_joinplayer(function(player, last_login)
    local name = player:get_player_name()
    local image_id = player:hud_add({
        name = "ambience_lib:hud_image",
        position = {x=1,y=1},
		scale = {x=2,y=2},
		offset = {x=-400,y=-32},

        z_index = Z_INDEX,
        hud_elem_type = "image",
        text = "ambience_lib_hud_icon.png",
    })
    local title_id = player:hud_add({
        name = "ambience_lib:hud_title",
        alignment = {x=1,y=-1},
        position = {x=1,y=1},
        offset = {x=(-400 + (16 * 2)),y=-32},
        z_index = Z_INDEX,
        hud_elem_type = "text",
        text = NO_AMBIENCE,
        number = 0xFFFFFF,
    })
    local artist_id = player:hud_add({
        name = "ambience_lib:hud_artist",
        alignment = {x=1,y=1},
        position = {x=1,y=1},
        offset = {x=(-400 + (16 * 2)),y=-32},
        z_index = Z_INDEX,
        hud_elem_type = "text",
        text = "",
        number = 0xFFFFFF,
        style = 2, -- Italic
    })

    if type(image_id)  ~= "number"
    or type(title_id)  ~= "number"
    or type(artist_id) ~= "number" then
        minetest.chat_send_player(name, S("[ambience_lib] Failed to create HUD."))
        return
    end

    hud_ids[name] = {image_id,title_id,artist_id}
end)

minetest.register_on_leaveplayer(function(player, timed_out)
    local name = player:get_player_name()
    hud_ids[name] = nil
end)

ambience_lib.register_on_play_ambience(function(name,spec_name)
    local player = minetest.get_player_by_name(name)
    if not player then return end
    if spec_name == "" then
        player:hud_change(hud_ids[name][2],"text",NO_AMBIENCE)
        player:hud_change(hud_ids[name][3],"text","")
    else
        local spec = ambience_lib.registered_sounds[spec_name]
        player:hud_change(hud_ids[name][2],"text",spec.title)
        player:hud_change(hud_ids[name][3],"text",S("by @1",spec.artist))
    end
end)
