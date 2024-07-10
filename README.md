# Darktide Better Crosshairs

Includes fixes from [Crosshairs Fix](https://github.com/Skwuruhl/darktide-crosshairs-fix). I initially intended for this to just be a customization mod but the scope necessitated combining the mods. Darktide 1.4 fixed most issues with crosshairs being inaccurate but a few critical issues remain. Mod fixes remaining issues. Better Crosshairs adds sliders for crosshair size and color. Painstaking effort has gone into ensuring that spread remains accurate even while crosshair size and FOV changes. Additionally the mod has a function that custom crosshairs and/or other mods can utilize to easily generate crosshair segments with accurate spread, especially for diagonal segments.

[Nexus Mods](https://www.nexusmods.com/warhammer40kdarktide/mods/338)

# Installation

Drop the better_crosshairs folder into your mods folder. Add "better_crosshairs" to your mod_load_order.txt before any other crosshair mods (unless instructed otherwise by another mod.)

# Crosshairs Fix Math

Original crosshairs equation:

    370 * tan(spread) / tan(current_vertical_fov / 2)

Result is the number of pixels your crosshair is placed from the center of the screen, scaled from 1080p as baseline. Assault is 555 instead of 370.

New equation:

    540 * tan(spread) / tan(current_vertical_fov / 2)

Also applied to assault crosshair.

# For Modders

Custom crosshairs (from Crosshair Remap or similar) should use a SPREAD_DISTANCE value of 10 and, as vanilla crosshairs have been updated to do, use horizontal_alignment and vertical_alignment of "center". If your crosshair has no diagonal segments you do not need to use crosshair_rotation(). You can still use the function for non-diagonal crosshairs to do things with a for loop instead of manually doing each segment of the crosshair. See this mod for examples of what I mean.

If you want diagonal crosshairs then use the crosshair_rotation function to get x, y coordinates.

To make your custom crosshairs capable of getting scaled and recolored by this mod... idk reach out to me or look through this mod to try and figure it out. I'm not entirely sure how this should be done. Compatibility might need to be done on your end. You could try inserting your template into "scripts/ui/hud/elements/crosshair/hud_element_crosshair_settings.lua" though I don't know if this'll break things.

Feel free to reach out in the Darktide Modders discord if you have questions.

## crosshair_rotation(x, y, angle, half_crosshair_size, minimum_offset, texture_rotation)

* supplied with spread_offset_x and spread_offset_y and the angle of a crosshair segment, returns x and y coordinates adjusted for the rotation. If you're making a custom crosshair make sure you're passing yaw to x and pitch to y from \_spread\_yaw\_pitch(), plus any other scalars.

* half_crosshair_size is what it says. Be sure to use the correct dimension. Not optional.

* minimum_offset is an optional parameter that defines the mininum number of 1080 pixels the returned x, y should be from center. e.g. a value of 1 at an angle of 45° would set a minumum x and y value of 0.707. It can be a good idea to make this the other half dimension of half_crosshair_size but you might not want this. Defaults to 0 if omitted.

* texture_rotation is an optional parameter in case the crosshair texture needs additional rotation. Be sure to also adjust the crosshair segment angle by negative of this value. Defaults to 0 if omitted.

* As usual for lua all angles should be supplied in radians.
 