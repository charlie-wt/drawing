-- usage:
--
-- local v  = vec(1, 2, 3)
-- local v2  = vec({4, 5, 6})
--
-- v[1]  -- get first element
-- v.x   -- get first element (supports `.x`, `.y`, `.z`, `.w`)
-- v.r   -- get first element (supports `.r`, `.g`, `.b`, `.a`)
--
-- v + v2
-- v * 5
-- 10 / v
-- -v
--
-- -- (comparisons are true if condition is true for *all* elems)
-- v == vec(1, 2, 3)
-- v < v2
-- vec(true, true, false):all()
--
-- v:map(function(i, x) return x > 1 end)
-- v:bimap(v2, function(i, x, y) return x + y > 7 end)
-- v:fold(function(x, y) return math.sin(x) + y end)
--
-- v..v2  -- concatenation
--
-- for i,x in v:iter() do
-- 	print('v['..i..'] = '..x)
-- end
--
-- v:sum()           -- instance method: sum of elements
-- vec:sum({v, v2})  -- class method: sum of vecs
-- v:dot(v2)
-- v:dist(v2)

local function make_binary_func(cls, op)
	return function(lhs, rhs)
		assert(type(lhs) == 'table' or type(rhs) == 'table')
		if type(lhs) == 'number' then
			lhs = cls:full(rhs:len(), lhs)
		end
		if type(rhs) == 'number' then
			rhs = cls:full(lhs:len(), rhs)
		end

		local res_length = math.min(lhs:len(), rhs:len())

		local vals = {}
		for i=1,res_length do
			table.insert(vals, op(i, lhs[i], rhs[i]))
		end
		return cls(vals)
	end
end

local function make_unary_func(cls, op)
	return function(self)
		local vals = {}
		for i=1,self:len() do
			table.insert(vals, op(i, self[i]))
		end
		return cls(vals)
	end
end

local function make_reduction(preprocess_fn, reduction_fn)
	return function(...)
		return reduction_fn(preprocess_fn(...))
	end
end

local function index_of(list, value)
	for i,v in ipairs(list) do
		if v == value then
			return i
		end
	end
	return nil
end

local function to_numeric_index(idx)
	if type(idx) == "number" then
		return idx
	end

	local aliases = {
		{"x", "y", "z", "w"},
		{"r", "g", "b", "a"},
	}

	for _,alias in ipairs(aliases) do
		local alias_idx = index_of(alias, idx)
		if alias_idx ~= nil then
			return alias_idx
		end
	end

	return nil
end


local vec_class = {}  -- for class/static methods
-- new vec full of `length` `val`s
function vec_class:full(length, val)
	local vals = {}
	for i=1,length do
		table.insert(vals, val)
	end
	return self(vals)
end
-- sum all vecs in list `vecs` (requires a non-empty list of vecs of the same length)
function vec_class:sum(vecs)
	assert(#vecs > 0, "can't given an empty list to `sum`")
	local res = vecs[1]
	for i=2,#vecs do
		assert(vecs[i]:len() == res:len(), "all vecs given to `sum` should have the same length")
		res = res + vecs[i]
	end
	return res
end
-- get centroid of all vecs in list `vecs` (requires a non-empty list of vecs of the same length)
function vec_class:centroid(vecs)
	local res = self:sum(vecs)
	return res / #vecs
end


local vec_instance = {}  -- for instance methods
-- get a copy of this vec
function vec_instance:copy()
	local res = {}
	for _,v in self:iter() do
		table.insert(res, v)
	end
	return vec_class(res)
end
-- map unary `fn` over all elements
function vec_instance:map(fn)
	return make_unary_func(vec_class, fn)(self)
end
-- map binary `fn` over all pairs of elements (up to length of shortest input)
function vec_instance:bimap(other, fn)
	return make_binary_func(vec_class, fn)(self, other)
end
-- fold all elements together with the binary-to-one `fn`
function vec_instance:fold(fn)
	assert(self:len() > 0, "can't fold an empty vec")
	local res = self[1]
	for i=2,self:len() do
		res = fn(res, self[i])
	end
	return res
end
-- get sum of all elements
function vec_instance:sum()
	return self:fold(function(x, y) return x + y end)
end
-- get squared distance between `self` & `other`
function vec_instance:dist_squared(other)
	return ((other - self) ^ 2):sum()
end
-- get distance between `self` & `other`
function vec_instance:dist(other)
	return math.sqrt(self:dist_squared(other))
end
-- dot product
function vec_instance:dot(other)
	return (self * other):sum()
end
-- number of elements
function vec_instance:len()  -- ...because apparently __len is lua 5.2+
	return #self.data
end
-- get iterator like `ipairs` over elements
function vec_instance:iter()  -- ...because __ipairs is lua 5.2+
	return ipairs(self.data)
end
-- get whether all elements compare to true
function vec_instance:all()
	for _,v in self:iter() do
		if not v then
			return false
		end
	end
	return true
end
-- get whether any element compares to true
function vec_instance:any()
	for _,v in self:iter() do
		if v then
			return true
		end
	end
	return false
end


-- NOTE: need to define this globally (rather than in the `__call` constructor) because
-- whether some metamethods are invoked (eg. `__eq`) depends on both operands having the
-- *same* metamethod.
local vec_metatable = {
	__newindex = function(self, key, value)
		local num_idx = to_numeric_index(key)
		if num_idx ~= nil then
			self.data[num_idx] = value
			return
		end

		-- falling back to `rawset` here, but falling back to `vec_instance[]` in
		-- `__index` means that you can *get* values from anywhere including
		-- `vec_instance`, but you can only *set* your own properties (cause otherwise
		-- you could do myvec.sum = 10 and change it for all instances.
		rawset(self, key, value)
	end,
	__index = function(self, key)
		local num_idx = to_numeric_index(key)
		if num_idx ~= nil then
			return self.data[num_idx]
		end

		return vec_instance[key]
	end,
	__tostring = function(self)
		local str = "vec["
		local sep = ""
		for i,v in self:iter() do
			str = str..sep..tostring(v)
			if i > 0 then
				sep = ", "
			end
		end
		return str.."]"
	end,
	__concat = function(self, other)
		local res = self:copy()
		for _,v in other:iter() do
			table.insert(res.data, v)
		end
		return res
	end,
	-- (there are more of these to overload in later lua versions)
	__unm = make_unary_func(vec_class, function(_, val) return -val end),
	__add = make_binary_func(vec_class, function(_, lhs, rhs) return lhs + rhs end),
	__sub = make_binary_func(vec_class, function(_, lhs, rhs) return lhs - rhs end),
	__mul = make_binary_func(vec_class, function(_, lhs, rhs) return lhs * rhs end),
	__div = make_binary_func(vec_class, function(_, lhs, rhs) return lhs / rhs end),
	__mod = make_binary_func(vec_class, function(_, lhs, rhs) return lhs % rhs end),
	__pow = make_binary_func(vec_class, function(_, lhs, rhs) return lhs ^ rhs end),
	__lt = make_reduction(
		make_binary_func(vec_class, function(_, lhs, rhs) return lhs < rhs end),
		vec_instance.all
	),
	__le = make_reduction(
		make_binary_func(vec_class, function(_, lhs, rhs) return lhs <= rhs end),
		vec_instance.all
	),
	__eq = make_reduction(
		make_binary_func(vec_class, function(_, lhs, rhs) return lhs == rhs end),
		vec_instance.all
	),
}

vec = setmetatable(vec_class, {
	__call = function(cls, ...)  -- constructor
		local data = {...}
		if #data == 1 and type(data[1]) == 'table' then
			data = data[1]
		end
		local inst = {
			-- underlying data as a list
			data = data,
			-- the class `vec`
			class = cls,
		}
		return setmetatable(inst, vec_metatable)
	end
})
