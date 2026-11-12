local sourceContainer

for _, v in pairs(getloadedmodules()) do
	if not v.Parent and v.Name == 'ReplicationInterface' then
		sourceContainer = v
		break
	end
end

if sourceContainer then
	setclipboard(decompile(sourceContainer))
end