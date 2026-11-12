--[=[
    written by forka42
    ---
    https://github.com/forka42
]=]

local function applyGunMod(t)
    if type(t) == 'table' and rawget(t, 'RoundsPerMinute') then
		rawset(t, 'RoundsPerMinute', 5e3)
		rawset(t, 'ReservedAmmo', 1e7)
		rawset(t, 'MagCapacity', 1e7)
		rawset(t, 'GunType', 1)
	end
end

for _, t in pairs(debug.getregistry()) do
	applyGunMod(t)
end

for _, m in pairs(getloadedmodules()) do
	if m:FindFirstAncestor('GunConfigs') then
		local c = require(m)
		
		for _, t in pairs(c) do
			applyGunMod(t)
		end
	end
end