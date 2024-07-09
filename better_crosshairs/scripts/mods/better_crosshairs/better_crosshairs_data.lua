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
				range           = {0.01, 8},
				decimals_number = 2,
			},
		},
	},
}
