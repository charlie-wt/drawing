----------------------------------------------------------------------------------------
-- NOTE: OLD, PREFER maths.lua/vec.lua
----------------------------------------------------------------------------------------

function vec(x, y)
	-- TODO #enhancement: metatable operator overloads for elemwise
	return {
		x = x,
		y = y,
	}
end

function as_list(v)
	return {v.x, v.y}
end

function dist_squared(v1, v2)
	return (v2.x - v1.x) ^ 2 + (v2.y - v1.y) ^ 2
end

function dist(v1, v2)
	return math.sqrt(dist_squared(v1, v2))
end

function orthogonal(v)
	return vec(-v.y, v.x)
end

function broadcast(val)
	if type(val) == "number" then
		return vec(val, val)
	end
	return val
end

function add(v1, v2)
	v1 = broadcast(v1)
	v2 = broadcast(v2)
	return vec(v1.x + v2.x, v1.y + v2.y)
end

function sub(v1, v2)
	v1 = broadcast(v1)
	v2 = broadcast(v2)
	return vec(v1.x - v2.x, v1.y - v2.y)
end

function mul(v1, v2)
	v1 = broadcast(v1)
	v2 = broadcast(v2)
	return vec(v1.x * v2.x, v1.y * v2.y)
end

function div(v1, v2)
	v1 = broadcast(v1)
	v2 = broadcast(v2)
	return vec(v1.x / v2.x, v1.y / v2.y)
end

function dot(v1, v2)
	v1 = broadcast(v1)
	v2 = broadcast(v2)
	return v1.x * v2.x + v1.y * v2.y
end

function sum_of_squares(list)
	local total = 0
	for _, item in ipairs(list) do
		total = total + item ^ 2
	end
	return total
end

function centroid(points)
	assert(#points > 0)

	local res = vec(0, 0)

	for _,point in ipairs(points) do
		res = add(res, point)
	end

	return div(res, #points)
end
