local mod = get_mod("better_crosshairs")
local fov = require("scripts/utilities/camera/fov")
local assault_new = require("scripts/ui/hud/elements/crosshair/templates/crosshair_template_assault_new")
local Crosshair = require("scripts/ui/utilities/crosshair")
local HudElementCrosshairSettings = require("scripts/ui/hud/elements/crosshair/hud_element_crosshair_settings")

local SCALAR = mod:get("crosshair_scalar")
mod.on_setting_changed = function(status, state_name)
    SCALAR = mod:get("crosshair_scalar")
end

--supplied with spread_offset_x and spread_offset_y and the angle of a crosshair segment, returns x and y coordinates adjusted for the rotation.
--minimum_offset is the mininum number of 1080 pixels the returned x, y should be from center. e.g. a value of 1 at an angle of 45° would set a minumum x and y value of 0.707. optional
--texture_rotation is an optional parameter in case the crosshair texture needs additional rotation. Be sure to also adjust the crosshair segment angles as needed. optional.
--As usual for lua all angles should be supplied in radians.
mod.crosshair_rotation = function(x, y, angle, half_crosshair_size, minimum_offset, texture_rotation)
	minimum_offset = minimum_offset or 0
	texture_rotation = texture_rotation or 0
	x = math.cos(angle + texture_rotation) * math.max(x + half_crosshair_size, minimum_offset)
	y = -math.sin(angle + texture_rotation) * math.max(y + half_crosshair_size, minimum_offset)
	return x, y
end

--most templates multiply pitch and yaw by 10, and apply_fov_to_crosshair by 37. The result is 370 but needs to be 540, the number of pixels from center of crosshair to top of screen with a 1080p monitor.
mod:hook(fov, "apply_fov_to_crosshair", function(func, pitch, yaw)
	pitch, yaw = func(pitch, yaw)

	local correction = 54/37
	pitch = pitch * correction
	yaw = yaw * correction

	return pitch, yaw
end)

--assault is the only template that has a multiplier of 15 instead of 10.
--I tried to fix this without hook_origin but I couldn't get it to work. Only thing this hook changes is SPREAD_DISTANCE 15 to 10
-- mod:hook_origin(assault_new, "update_function", function(parent, ui_renderer, widget, template, crosshair_settings, dt, t, draw_hit_indicator)
-- 	local style = widget.style
-- 	local hit_progress, hit_color, hit_weakspot = parent:hit_indicator()
-- 	local yaw, pitch = parent:_spread_yaw_pitch(dt)

-- 	if yaw and pitch then
-- 		local scalar = SPREAD_DISTANCE * (crosshair_settings.spread_scalar or 1)
-- 		local spread_offset_y = pitch * scalar
-- 		local spread_offset_x = yaw * scalar

-- 		local top_style = style.top
-- 		local top_size = top_style.size[1]

-- 		top_style.offset[1] = 0
-- 		top_style.offset[2] = math.min(-spread_offset_y - top_size/2, -top_size/2-2)

-- 		local bottom_style = style.bottom
-- 		local bottom_size = bottom_style.size[1]

-- 		bottom_style.offset[1] = 0
-- 		bottom_style.offset[2] = math.max(spread_offset_y + bottom_size/2, bottom_size/2+2)

-- 		local left_style = style.left
-- 		local left_size = left_style.size[1]

-- 		left_style.offset[1] = math.min(-spread_offset_x - left_size/2, -left_size/2-2)
-- 		left_style.offset[2] = 0

-- 		local right_style = style.right
-- 		local right_size = right_style.size[1]

-- 		right_style.offset[1] = math.max(spread_offset_x + right_size/2, right_size/2+2)
-- 		right_style.offset[2] = 0
-- 	end

-- 	Crosshair.update_hit_indicator(style, hit_progress, hit_color, hit_weakspot, draw_hit_indicator)
-- end)


local SPREAD_DISTANCE = 10
local HALF_SIZE_X = 4
local MIN_OFFSET = 6
local RIGHT_ANGLE = math.rad(90)
local crosshair_templates = Script.new_array(#HudElementCrosshairSettings.templates)
for i=1, #HudElementCrosshairSettings.templates do
	crosshair_templates[i] = require(HudElementCrosshairSettings.templates[i])
	mod:hook_origin(crosshair_templates[i], "update_function", function (parent, ui_renderer, widget, template, crosshair_settings, dt, t, draw_hit_indicator)
		local style = widget.style
		local hit_progress, hit_color, hit_weakspot = parent:hit_indicator()
		local yaw, pitch = parent:_spread_yaw_pitch(dt)
		local name = template.name
	
		if yaw and pitch then
			local scalar = SPREAD_DISTANCE * (crosshair_settings.spread_scalar or 1)
			local spread_offset_y = pitch * scalar
			local spread_offset_x = yaw * scalar
			for k, v in pairs(style) do
				local angle = v.angle
				if not string.find(k, "hit_") and angle then
					if name == "bfg" or name == "shotgun" or name == "spray_n_pray" then
						v.offset[1], v.offset[2] = mod.crosshair_rotation(spread_offset_x, spread_offset_y, angle, v.size[2]/2, 0, RIGHT_ANGLE)
					else
						v.offset[1], v.offset[2] = mod.crosshair_rotation(spread_offset_x, spread_offset_y, angle, v.size[1]/2, 0)
					end
				end
			end
		end
	
		Crosshair.update_hit_indicator(style, hit_progress, hit_color, hit_weakspot, draw_hit_indicator)
	end)
end

mod:command("set_crosshair_scalar", mod:localize("crosshair_scalar_description"), function(s, ...)
    s = tonumber(s)
    if s == nil or s < 0.01 or s > 8 then
        mod:error("Invalid")
        return
    end
    mod:set("crosshair_scalar", s, true)
end)