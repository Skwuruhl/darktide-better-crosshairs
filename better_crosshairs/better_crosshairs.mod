return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`better_crosshairs` encountered an error loading the Darktide Mod Framework.")

		new_mod("better_crosshairs", {
			mod_script       = "better_crosshairs/scripts/mods/better_crosshairs/better_crosshairs",
			mod_data         = "better_crosshairs/scripts/mods/better_crosshairs/better_crosshairs_data",
			mod_localization = "better_crosshairs/scripts/mods/better_crosshairs/better_crosshairs_localization",
		})
	end,
	packages = {},
}
