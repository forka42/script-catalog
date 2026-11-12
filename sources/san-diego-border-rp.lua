--[=[
    written by forka42
    ---
    https://github.com/forka42
]=]

local contextActionService = game:GetService('ContextActionService')
local firstRefresh = true

local function refreshState()
	if not firstRefresh then
    	task.wait(0.5)
	else
		firstRefresh = false
	end

    for _, e in pairs(debug.getregistry()) do
        if type(e) == 'table' then
            if type(rawget(e, 'Impulse')) == 'function' then
                rawset(e, 'Impulse', function() end)
            end

            if type(rawget(e, 'ImpulsePitch')) == 'function' then
                rawset(e, 'ImpulsePitch', function() end)
            end

			if type(rawget(e, 'Flashbang')) == 'table' and type(rawget(e, 'SmokeGrenade')) == 'table' then
				for i, v in pairs(e) do
					if not rawget(v, 'Throwable') then
						local statistics = rawget(v, 'Stats')
						if type(statistics) == 'table' then
							rawset(statistics, 'MagSize', 1e7)
							rawset(statistics, 'RPM', 2000)
							rawset(statistics, 'MagCount', 1e7)
							rawset(statistics, 'BulletSpreadDegrees', 0)
							rawset(statistics, 'FireMode', 'Automatic')
							rawset(statistics, 'InfiniteStoredAmmo', true)
							rawset(statistics, 'Damage', 1e7)
						end
					end
				end
			end

			if type(rawget(e, 'CurrentAmmo')) == 'number' then
				print(e)
			end
        elseif type(e) == 'function' then
            local environment = getfenv(e)
            local s = rawget(environment, 'script')

			if s then
				if s.Name == 'GunController' then
					local s_environment = getsenv(s)

					for name, f in pairs(s_environment) do
						if name == 'TryShoot' then
							for i, v in pairs(debug.getupvalues(f)) do
								if type(v) == 'function' then
									local n = debug.info(v, 'n')
									if n == 'GetSpreadDirection' then
										debug.setupvalue(f, i, function(aimpoint)
											return aimpoint
										end)
									end
								elseif type(v) == 'table' then
									for _, t in pairs(v) do
										if type(t) == 'table' then
											if type(rawget(t, 'CurrentAmmo')) == 'number' then
												rawset(t, 'CurrentAmmo', 1e7)
												rawset(t, 'StoredAmmo', 1e7)
											end
										end
									end
								end
							end
						end
					end
				end
			end
        end
    end
end

contextActionService.LocalToolEquipped:Connect(refreshState)
contextActionService.LocalToolUnequipped:Connect(refreshState)
refreshState()