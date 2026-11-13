--[=[
    written by forka42
    ---
    https://github.com/forka42
    https://www.roblox.com/games/18286009370
]=]

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService('RunService')

local fenv = getfenv()
local getreg = fenv.getreg or fenv.debug.getregistry
local getupvalues = fenv.debug.getupvalues
local getloadedmodules = fenv.getloadedmodules
local iscclosure = fenv.iscclosure
local isexecutorclosure = fenv.isexecutorclosure
local setreadonly = fenv.setreadonly

local target_mag = 9999
local target_ammo = 9999
local target_fire_rate = 0.005

local state_tables = {}
local patch_tables = {}

local function unlock(t)
	pcall(setreadonly, t, false)
end

local function is_state_table(t)
	if type(t) ~= 'table' then return false end
	return type(rawget(t, 'Mag')) == 'number'
		and type(rawget(t, 'Ammo')) == 'number'
		and type(rawget(t, 'Heat')) == 'number'
end

local function is_patchable(t)
	if type(t) ~= 'table' then return false end
	return rawget(t, 'AmmoPerMag') ~= nil
		or rawget(t, 'BaseDamage') ~= nil
		or rawget(t, 'FireRate') ~= nil
		or rawget(t, 'BurstRate') ~= nil
		or rawget(t, 'Auto') ~= nil
		or rawget(t, 'MaxAmmo') ~= nil
		or rawget(t, 'Ammo') ~= nil
		or rawget(t, 'FireRates') ~= nil
		or rawget(t, 'BurstRates') ~= nil
		or rawget(t, 'CurrentFireRate') ~= nil
end

local function patch_rates(t)
	unlock(t)

	if type(rawget(t, 'FireRate')) == 'number' then
		rawset(t, 'FireRate', target_fire_rate)
	end
	if type(rawget(t, 'BurstRate')) == 'number' then
		rawset(t, 'BurstRate', target_fire_rate)
	end
	if type(rawget(t, 'LockOnScanBurstRate')) == 'number' then
		rawset(t, 'LockOnScanBurstRate', target_fire_rate)
	end
	if type(rawget(t, 'MaximumFireRate')) == 'number' then
		rawset(t, 'MaximumFireRate', target_fire_rate)
	end
	if type(rawget(t, 'CurrentFireRate')) == 'number' then
		rawset(t, 'CurrentFireRate', target_fire_rate)
	end
	if type(rawget(t, 'FireRateIncrement')) == 'number' then
		rawset(t, 'FireRateIncrement', 0)
	end

	local firerates = rawget(t, 'FireRates')
	if type(firerates) == 'table' then
		unlock(firerates)
		for k in pairs(firerates) do
			rawset(firerates, k, target_fire_rate)
		end
	end

	local burstrates = rawget(t, 'BurstRates')
	if type(burstrates) == 'table' then
		unlock(burstrates)
		for k in pairs(burstrates) do
			rawset(burstrates, k, target_fire_rate)
		end
	end
end

local function patch_ammo_limits(t)
	unlock(t)

	if type(rawget(t, 'AmmoPerMag')) == 'number' then
		rawset(t, 'AmmoPerMag', target_mag)
	end
	if type(rawget(t, 'MaxAmmo')) == 'number' then
		rawset(t, 'MaxAmmo', target_ammo)
	end
	if type(rawget(t, 'Ammo')) == 'number' and rawget(t, 'Mag') == nil then
		rawset(t, 'Ammo', target_ammo)
	end
	if type(rawget(t, 'MaxHeat')) == 'number' then
		rawset(t, 'MaxHeat', 9999)
	end
end

local function scan_n_apply_tables() 
    if type(getloadedmodules) == 'function' then
        for _, mod in pairs(getloadedmodules()) do
            local ok, result = pcall(require, mod)
            if ok and type(result) == 'table' then
                if is_patchable(result) then
                    patch_tables[result] = true
                end
                if is_state_table(result) then
                    state_tables[result] = true
                end
            end
        end
    end

    for _, f in pairs(getreg()) do
        if type(f) == 'function'
            and not (iscclosure and iscclosure(f))
            and not (isexecutorclosure and isexecutorclosure(f))
        then
            local ok, ups = pcall(getupvalues, f)
            if ok and type(ups) == 'table' then
                for _, uv in pairs(ups) do
                    if is_state_table(uv) then
                        state_tables[uv] = true
                    end
                    if is_patchable(uv) then
                        patch_tables[uv] = true
                    end
                    if type(uv) == 'table' then
                        for _, entry in pairs(uv) do
                            if is_state_table(entry) then
                                state_tables[entry] = true
                            end
                            if is_patchable(entry) then
                                patch_tables[entry] = true
                            end
                        end
                    end
                end
            end
        end
    end

    local state_count, patch_count = 0, 0
    for _ in pairs(state_tables) do state_count += 1 end
    for _ in pairs(patch_tables) do patch_count += 1 end

    if state_count == 0 and patch_count == 0 then
        return
    end

    for t in pairs(patch_tables) do
        patch_ammo_limits(t)
        patch_rates(t)
    end

    for t in pairs(state_tables) do
        unlock(t)
    end
end

local already_scanned = {}

ContextActionService.LocalToolEquipped:Connect(function(tool)
    if already_scanned[tool] ~= true then
        scan_n_apply_tables()
        already_scanned[tool] = true
    end
end)

RunService.Heartbeat:Connect(function()
	for t in pairs(state_tables) do
		unlock(t)
		rawset(t, 'Mag', target_mag)
		rawset(t, 'Ammo', target_ammo)
		if type(rawget(t, 'Heat')) == 'number' then
			rawset(t, 'Heat', 0)
		end
		if type(rawget(t, 'MaxAmmo')) == 'number' then
			rawset(t, 'MaxAmmo', target_ammo)
		end
		if type(rawget(t, 'CurrentFireRate')) == 'number' then
			rawset(t, 'CurrentFireRate', target_fire_rate)
		end
	end

	for t in pairs(patch_tables) do
		if type(rawget(t, 'CurrentFireRate')) == 'number' then
			unlock(t)
			rawset(t, 'CurrentFireRate', target_fire_rate)
		end
	end
end)

print('go crazy aaaaa go stupid aaaaa')