local mod = get_mod("better_crosshairs")
local fov = require("scripts/utilities/camera/fov")
local Crosshair = require("scripts/ui/utilities/crosshair")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local HudElementCrosshair = require("scripts/ui/hud/elements/crosshair/hud_element_crosshair")
local SPREAD_DISTANCE = 10
local RIGHT_ANGLE = math.rad(90)
local SCALAR = mod:get("crosshair_scalar")
local COLOR = {
	mod:get("crosshair_alpha"),
	mod:get("crosshair_red"),
	mod:get("crosshair_green"),
	mod:get("crosshair_blue"),
}

mod.on_setting_changed = function(status, state_name)
    SCALAR = mod:get("crosshair_scalar")
	COLOR = {
		mod:get("crosshair_alpha"),
		mod:get("crosshair_red"),
		mod:get("crosshair_green"),
		mod:get("crosshair_blue"),
	}
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
mod:hook(fov, "apply_fov_to_crosshair", function(func, pitch, yaw) -- the fov conversion actually gets applied before "crosshair_settings.spread_scalar" but it's basically always 1 as far as I can tell. If this changes I'll need to fix it.
	pitch, yaw = func(pitch, yaw)

	local correction = 54/37
	pitch = pitch * correction
	yaw = yaw * correction

	return pitch, yaw
end)

--these 3 crosshairs act very similarly so I'm able to group them
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

--these 3 crosshairs work just like the previous 3 but their textures need to be rotated an extra 90°
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
				styles[i].angle = math.rad(-180+90*i) --subtract 90 here
			end
		end
		return widget
	end)

	mod:hook_origin(rotated_crosshair_templates[i], "update_function", function (parent, ui_renderer, widget, template, crosshair_settings, dt, t, draw_hit_indicator)
		local style = widget.style
		local hit_progress, hit_color, hit_weakspot = parent:hit_indicator()
		local yaw, pitch = parent:_spread_yaw_pitch(dt)
	
		if yaw and pitch then
			local scalar = SPREAD_DISTANCE * (crosshair_settings.spread_scalar or 1)
			local spread_offset_y = pitch * scalar
			local spread_offset_x = yaw * scalar
			for k, v in pairs(style) do
				local angle = v.angle
				if not string.find(k, "hit_") and angle then
					v.offset[1], v.offset[2] = mod.crosshair_rotation(spread_offset_x, spread_offset_y, angle, v.size[2]/2, v.size[1]/2, RIGHT_ANGLE) -- add 90 here
				end
			end
		end
	
		Crosshair.update_hit_indicator(style, hit_progress, hit_color, hit_weakspot, draw_hit_indicator)
	end)
end

-- flamer is kind of a mess. I mostly just locked "spread" to 6° because _spread_yaw_pitch doesn't function correctly with flamer. Textures appear to be slightly asymmetrical?
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

-- charge_up templates store values globally so they don't reset on level load. I had to hook_origin both of them to prevent this. Maybe I should hook_require the entire file.
local charge_up_templates = {
	"scripts/ui/hud/elements/crosshair/templates/crosshair_template_charge_up_ads_new",
	"scripts/ui/hud/elements/crosshair/templates/crosshair_template_charge_up_new"
}
for i=1, #charge_up_templates do
	charge_up_templates[i] = require(charge_up_templates[i])
end
for i=1, #charge_up_templates do
	local offset_charge = {120, 30}
	local SIZE = {
		24,
		56
	}
	local MASK_SIZE = {
		24,
		52
	}
	mod:hook_origin(charge_up_templates[i], "create_widget_defintion", function (template, scenegraph_id)
		local center_half_width = 2 -- center_size[1] * 0.5
		local offset_charge_right = {
			SCALAR * (offset_charge[i] + center_half_width),
			0,
			1,
		}
		local offset_charge_mask_right = {
			SCALAR * (offset_charge[i] + center_half_width),
			0,
			2,
		}
		local offset_charge_left = {
			-SCALAR * (offset_charge[i] + center_half_width),
			0,
			1,
		}
		local offset_charge_mask_left = {
			-SCALAR * (offset_charge[i] + center_half_width),
			0,
			2,
		}
	
		return UIWidget.create_definition({
			Crosshair.hit_indicator_segment("top_left"),
			Crosshair.hit_indicator_segment("bottom_left"),
			Crosshair.hit_indicator_segment("top_right"),
			Crosshair.hit_indicator_segment("bottom_right"),
			Crosshair.weakspot_hit_indicator_segment("top_left"),
			Crosshair.weakspot_hit_indicator_segment("bottom_left"),
			Crosshair.weakspot_hit_indicator_segment("top_right"),
			Crosshair.weakspot_hit_indicator_segment("bottom_right"),
			{
				pass_type = "texture_uv",
				style_id = "charge_left",
				value = "content/ui/materials/hud/crosshairs/charge_up",
				style = {
					horizontal_alignment = "center",
					vertical_alignment = "center",
					uvs = {
						{
							1,
							0,
						},
						{
							0,
							1,
						},
					},
					offset = offset_charge_left,
					size = {
						SIZE[1],
						SIZE[2],
					},
					color = UIHudSettings.color_tint_main_1,
				},
			},
			{
				pass_type = "texture",
				style_id = "charge_right",
				value = "content/ui/materials/hud/crosshairs/charge_up",
				style = {
					horizontal_alignment = "center",
					vertical_alignment = "center",
					offset = offset_charge_right,
					size = {
						SIZE[1],
						SIZE[2],
					},
					color = UIHudSettings.color_tint_main_1,
				},
			},
			{
				pass_type = "texture_uv",
				style_id = "charge_mask_left",
				value = "content/ui/materials/hud/crosshairs/charge_up_mask",
				style = {
					horizontal_alignment = "center",
					vertical_alignment = "center",
					uvs = {
						{
							1,
							0,
						},
						{
							0,
							1,
						},
					},
					offset = offset_charge_mask_left,
					size = {
						MASK_SIZE[1],
						MASK_SIZE[2],
					},
					color = UIHudSettings.color_tint_main_1,
				},
			},
			{
				pass_type = "texture_uv",
				style_id = "charge_mask_right",
				value = "content/ui/materials/hud/crosshairs/charge_up_mask",
				style = {
					horizontal_alignment = "center",
					vertical_alignment = "center",
					uvs = {
						{
							0,
							1,
						},
						{
							1,
							0,
						},
					},
					offset = offset_charge_mask_right,
					size = {
						MASK_SIZE[1],
						MASK_SIZE[2],
					},
					color = UIHudSettings.color_tint_main_1,
				},
			},
		}, scenegraph_id)
	end)

	mod:hook_origin(charge_up_templates[i], "update_function", function (parent, ui_renderer, widget, template, crosshair_settings, dt, t, draw_hit_indicator)
		local style = widget.style
		local hit_progress, hit_color, hit_weakspot = parent:hit_indicator()
		-- local yaw, pitch = parent:_spread_yaw_pitch(dt)
		local charge_level = parent:_get_current_charge_level() or 0
	
		-- if yaw and pitch then
		-- 	local scalar = SPREAD_DISTANCE * (crosshair_settings.spread_scalar or 1)
		-- 	local spread_offset_y = pitch * scalar
		-- 	local spread_offset_x = yaw * scalar
		-- 	local charge_left_style = style.charge_left
		-- 	local charge_mask_left_style = style.charge_mask_left
		-- 	local charge_right_style = style.charge_right
		-- 	local charge_mask_right_style = style.charge_mask_right
		-- end
	
		local mask_height = MASK_SIZE[2] * SCALAR -- man charge_up templates are weird.
		local mask_height_charged = mask_height * charge_level
		local mask_height_offset_charged = mask_height * (1 - charge_level) * 0.5
		local charge_mask_right_style = style.charge_mask_right
	
		charge_mask_right_style.uvs[1][2] = charge_level
		charge_mask_right_style.size[2] = mask_height_charged
		charge_mask_right_style.offset[2] = mask_height_offset_charged
	
		local charge_mask_left_style = style.charge_mask_left
	
		charge_mask_left_style.uvs[1][2] = 1 - charge_level
		charge_mask_left_style.size[2] = mask_height_charged
		charge_mask_left_style.offset[2] = mask_height_offset_charged
	
		Crosshair.update_hit_indicator(style, hit_progress, hit_color, hit_weakspot, draw_hit_indicator)
	end)
end

--I mostly overwrite the vanilla functions but don't need to hook_origin to do so. I generate segments similar to normal crosshairs but with a fixed baseline of 10 pixels before being scalared.
local hit_indicator_segments = {
	"hit_indicator_segment",
	"weakspot_hit_indicator_segment"
}
for i=1, #hit_indicator_segments do
	mod:hook(Crosshair, hit_indicator_segments[i], function (func, position_name)
		local widget = func(position_name)
		local style = widget.style
		if style.pivot then
			style.pivot = nil -- I still don't know what pivot does. seems to just break everything.
		end
		local offset = style.offset
		offset[1], offset[2] = mod.crosshair_rotation(10, 10, style.angle, style.size[1]/2, style.size[2]/2)
		offset[1], offset[2] = offset[1] * SCALAR, offset[2] * SCALAR
		return widget
	end)
end

mod:hook(HudElementCrosshair, "init", function(func, self, parent, draw_layer, start_scale, definitions)
    func(self, parent, draw_layer, start_scale, definitions)
    local SCALAR = mod:get("crosshair_scalar")
    for k, v in pairs(self._crosshair_widget_definitions) do
		for i, j in pairs(v.style) do
			if j.size then
				for i = 1,2 do
					j.size[i] = j.size[i] * SCALAR
				end
			end
			if j.color then
				j.color = COLOR
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

mod:command("set_crosshair_argb", mod:localize("crosshair_argb_description"), function(a, r, g, b, ...)
	argb = { a, r, g, b}
	for i=1, #argb do
		argb[i] = tonumber(argb[i])
		if argb[i] == nil or argb[i] < 0 or argb[i] > 255 then
			mod:error("Invalid")
			return
		end
	end
	mod:set("crosshair_alpha", argb[1], false)
	mod:set("crosshair_red", argb[2], false)
	mod:set("crosshair_green", argb[3], false)
	mod:set("crosshair_blue", argb[4], true)
end)