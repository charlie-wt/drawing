require "vec"


function sum_of_squares(list)
	local total = 0
	for _, item in ipairs(list) do
		total = total + item ^ 2
	end
	return total
end

function orthogonal(v)
	return vec(-v.y, v.x)
end
