require "vec"


function sum_of_squares(list)
	local total = 0
	for _, item in ipairs(list) do
		total = total + item ^ 2
	end
	return total
end

-- get a vec orthogonal to the given (2d) vec
function orthogonal(v)
	assert(v:len() == 2, "orthogonal only implemented for 2d")
	return vec(-v.y, v.x)
end

-- rotate a (2d) vec
function rotated(v, a)
	assert(v:len() == 2, "rotated only implemented for 2d")
	return vec(v.x * math.cos(a) - v.y * math.sin(a),
	           v.x * math.sin(a) + v.y * math.cos(a))
end
