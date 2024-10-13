require "maths"


function print_path(path)
	for _,p in ipairs(path) do
		print(p.x..", "..p.y)
	end
	print()
end

function read_paths(filename)
	local contents, size_or_error = love.filesystem.read(filename)

	if contents == nil then
		print("error reading paths file "..filename..": "..size_or_error)
		return {}
	end

	local paths = {}
	local idx = 1

	for line in contents:gmatch("(.-)\n\n") do
		local path = {}
		for x, y in line:gmatch("(%d+), (%d+)") do
			table.insert(path, vec(tonumber(x), tonumber(y)))
		end
		if #path > 0 then
			table.insert(paths, path)
		end
	end

	return paths
end
