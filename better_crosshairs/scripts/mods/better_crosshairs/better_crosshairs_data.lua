local mod = get_mod("better_crosshairs")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id      = "crosshair_scalar",
				type            = "numeric",
				default_value   = 1,
				range           = {0.01, 4},
				decimals_number = 2,
			},
			{
				setting_id      = "crosshair_alpha",
				type            = "numeric",
				default_value   = 255,
				range           = {0, 255},
				decimals_number = 0,
			},
			{
				setting_id      = "crosshair_red",
				type            = "numeric",
				default_value   = 255,
				range           = {0, 255},
				decimals_number = 0,
			},
			{
				setting_id      = "crosshair_green",
				type            = "numeric",
				default_value   = 255,
				range           = {0, 255},
				decimals_number = 0,
			},
			{
				setting_id      = "crosshair_blue",
				type            = "numeric",
				default_value   = 255,
				range           = {0, 255},
				decimals_number = 0,
			},
		},
	},
}
