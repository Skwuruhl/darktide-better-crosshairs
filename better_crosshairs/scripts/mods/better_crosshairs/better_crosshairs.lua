local mod = get_mod("better_crosshairs")
local fov = require("scripts/utilities/camera/fov")
local Crosshair = require("scripts/ui/utilities/crosshair")
local HudElementCrosshair = require("scripts/ui/hud/elements/crosshair/hud_element_crosshair")
local SPREAD_DISTANCE = 10
local RIGHT_ANGLE = math.rad(90)
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

local crosshair_templates = {
	"scripts/ui/hud/elements/crosshair/templates/crosshair_template_assault_new",
	"scripts/ui/hud/elements/crosshair/templates/crosshair_template_cross_new",
	"scripts/ui/hud/elements/crosshair/templates/crosshair_template_projectile_drop_new"
}
for i=1, #crosshair_templates do
	crosshair_templates[i] = require(crosshair_templates[i])
end

for i=1, #crosshair_templates do
	mod:hook(crosshair_templates[i], "create_widget_defintion", function (func, template, scenegraph_id)
		local widget = func(template, scenegraph_id)
		local style = widget.style
		local styles = {style.right, style.top, style.left, style.bottom}
		for i=1, #styles do
			if styles[i] then
				styles[i].angle = math.rad(-90+90*i)
			end
		end
		return widget
	end)

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
					v.offset[1], v.offset[2] = mod.crosshair_rotation(spread_offset_x, spread_offset_y, angle, v.size[1]/2, v.size[2]/2)
				end
			end
		end
	
		Crosshair.update_hit_indicator(style, hit_progress, hit_color, hit_weakspot, draw_hit_indicator)
	end)
end

local rotated_crosshair_templates = {
	"scripts/ui/hud/elements/crosshair/templates/crosshair_template_bfg_new",
	"scripts/ui/hud/elements/crosshair/templates/crosshair_template_shotgun_new",
	"scripts/ui/hud/elements/crosshair/templates/crosshair_template_spray_n_pray_new"
}
for i=1, #rotated_crosshair_templates do
	rotated_crosshair_templates[i] = require(rotated_crosshair_templates[i])
end

for i=1, #rotated_crosshair_templates do
	mod:hook(rotated_crosshair_templates[i], "create_widget_defintion", function (func, template, scenegraph_id)
		local widget = func(template, scenegraph_id)
		local style = widget.style
		local styles = {style.right, style.top, style.left, style.bottom}
		for i=1, #styles do
			if styles[i] then
				styles[i].angle = math.rad(-180+90*i)
			end
		end
		return widget
	end)

	mod:hook_origin(rotated_crosshair_templates[i], "update_function", function (parent, ui_renderer, widget, template, crosshair_settings, dt, t, draw_hit_indicator)
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
					v.offset[1], v.offset[2] = mod.crosshair_rotation(spread_offset_x, spread_offset_y, angle, v.size[2]/2, v.size[1]/2, RIGHT_ANGLE)
				end
			end
		end
	
		Crosshair.update_hit_indicator(style, hit_progress, hit_color, hit_weakspot, draw_hit_indicator)
	end)
end

local flamer = require("scripts/ui/hud/elements/crosshair/templates/crosshair_template_flamer")
mod:hook(flamer, "create_widget_defintion", function (func, template, scenegraph_id)
	local widget = func(template, scenegraph_id)
	local style = widget.style
	style.right.angle = math.rad(0) - RIGHT_ANGLE
	style.left.angle = math.rad(180) - RIGHT_ANGLE
	return widget
end)
mod:hook_origin(flamer, "update_function", function (parent, ui_renderer, widget, template, crosshair_settings, dt, t, draw_hit_indicator)
	local style = widget.style
	local hit_progress, hit_color, hit_weakspot = parent:hit_indicator()
	local yaw, pitch = fov.apply_fov_to_crosshair(6, 6)

	if yaw and pitch then
		local scalar = SPREAD_DISTANCE * (crosshair_settings.spread_scalar or 1)
		local spread_offset_y = pitch * scalar
		local spread_offset_x = yaw * scalar
		local styles = {style.right, style.left}
		for i=1, #styles do
			styles[i].offset[1], styles[i].offset[2] = mod.crosshair_rotation(spread_offset_x, spread_offset_y, styles[i].angle, styles[i].size[2]/2, styles[i].size[1]/2, RIGHT_ANGLE)
		end
	end

	Crosshair.update_hit_indicator(style, hit_progress, hit_color, hit_weakspot, draw_hit_indicator)
end)

-- local charge_up_templates = {
-- 	"scripts/ui/hud/elements/crosshair/templates/crosshair_template_charge_up_ads_new",
-- 	"scripts/ui/hud/elements/crosshair/templates/crosshair_template_charge_up_new"
-- }
-- for i=1, #charge_up_templates do
-- 	charge_up_templates[i] = require(charge_up_templates[i])
-- end

-- for i=1, 1 do
-- 	mod:hook(charge_up_templates[i], "create_widget_defintion", function (func, template, scenegraph_id)
-- 		local widget = func(template, scenegraph_id)
-- 		for k,v in pairs(widget.style) do
-- 			if not string.find(k, "hit_") then
-- 				v.offset[1], v.offset[2] = v.offset[1] * SCALAR, v.offset[2] * SCALAR
-- 			end
-- 		end
-- 		return widget
-- 	end)
-- end

mod:hook(Crosshair, "hit_indicator_segment", function (func, position_name)
	local widget = func(position_name)
	for k,v in pairs(widget) do
		mod:echo(k)
		mod:echo(v)
	end
	return widget
end)

mod:hook(Crosshair, "weakspot_hit_indicator_segment", function (func, position_name)
	local widget = func(position_name)
	for k,v in pairs(widget) do
		mod:echo(k)
		mod:echo(v)
	end
	return widget
end)

mod:hook(HudElementCrosshair, "init", function(func, self, parent, draw_layer, start_scale, definitions)
    func(self, parent, draw_layer, start_scale, definitions)
    local SCALAR = mod:get("crosshair_scalar")
    for k, v in pairs(self._crosshair_widget_definitions) do
		if not (k == "charge_up_ads" or k == "charge_up") then
			for i, j in pairs(v.style) do
				if j.size then
					for i = 1,2 do
						j.size[i] = j.size[i] * SCALAR
					end
				end
			end
		end
    end
end)

mod:command("set_crosshair_scalar", mod:localize("crosshair_scalar_description"), function(s, ...)
    s = tonumber(s)
    if s == nil or s < 0.01 or s > 4 then
        mod:error("Invalid")
        return
    end
    mod:set("crosshair_scalar", s, true)
end)