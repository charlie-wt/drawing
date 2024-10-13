-- turn the table `prototype` into a basic class; `prototype` may only contain static
-- members. can either provide a `constructor` function to set instance members, or
-- define a `prototype:new` to do the same. instances will have a `.class` member
-- refering back to `prototype`. doesn't support inheritance.
function class(prototype, constructor)
	if constructor ~= nil then
		prototype.new = constructor
	end
	local mt = getmetatable(prototype)
	if mt == nil then
		mt = setmetatable(prototype, {})
	else
		assert(mt.__call == nil)
	end
	mt.__call = function(cls, ...)
		local instance = setmetatable({}, {__index = cls})
		instance.class = cls
		if cls.new ~= nil then
			cls.new(instance, ...)
		end
		return instance
	end
	return setmetatable(prototype, mt)
end

function min(list)
	if #list == 0 then
		return nil
	end

	local res = list[1]

	for i=2,#list do
		if list[i] < res then
			res = list[i]
		end
	end

	return res
end

function max(list)
	if #list == 0 then
		return nil
	end

	local res = list[1]

	for i=2,#list do
		if list[i] > res then
			res = list[i]
		end
	end

	return res
end

function mean(list)
	local res = 0
	for _, item in ipairs(list) do
		res = res + item
	end
	return res / #list
end

function profile(fn, repetitions, ...)
	local res = nil

	local durations = {}

	for i=1,repetitions do
		local start = love.timer.getTime()
		res = fn(...)
		table.insert(durations, love.timer.getTime() - start)
	end

	print("average time over "..repetitions.." repeats: "..mean(durations).." seconds")
	return res
end

-- get the last element in `list`
function last(list)
	return list[#list]
end

-- update `table1` with values from `table2`, in-place
function update(table1, table2)
	for k,v in pairs(table2) do
		table1[k] = v
	end
	return table1
end

-- ternary statement (though won't short-circuit)
function ternary(cond, true_case, false_case)
	if cond then
		return true_case
	else
		return false_case
	end
end

-- out-of-place map
function foreach(list, fn)
	local res = {}
	for i=1,#list do
		table.insert(res, fn(i, list[i]))
	end
	return res
end
-- in-place map
function foreach_(list, fn)
	for i=1,#list do
		list[i] = fn(i, list[i])
	end
	return list
end
