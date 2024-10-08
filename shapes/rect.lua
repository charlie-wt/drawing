require "maths"
require "optimise"
require "utils"


function classify(x, min, max)
	if x < min then
		return -1
	elseif x > max then
		return 1
	else
		return 0
	end
end

function simple_rect_distance(point, size)
	local side_x = classify(point.x, 0, size.x)
	local side_y = classify(point.y, 0, size.y)

	if side_x == -1 then
		if     side_y == -1 then return point:dist()
		elseif side_y ==  0 then return -point.x
		else                     return point:dist(vec(0, size.y))
		end
	elseif side_x == 0 then
		if     side_y == -1 then return -point.y
		elseif side_y ==  0 then return math.min(point.x, point.y, size.x - point.x, size.y - point.y)
		else                     return point.y - size.y
		end
	else
		if     side_y == -1 then return point:dist(vec(size.x, 0))
		elseif side_y ==  0 then return point.x - size.x
		else                     return point:dist(size)
		end
	end
end

function transformed_rect_distances_squared(points, rect)
	return sum_of_squares(foreach(points, function(i,  point)
		return simple_rect_distance(rotated(point - rect.pos, -rect.angle), rect.size)
	end))
end

function vars_to_rect(vars)
	return {
		pos = vec(vars[1], vars[2]),
		size = vec(vars[3], vars[4]),
		angle = vars[5],
	}
end

function make_rect_cost(points)
	return function(vars)
		return transformed_rect_distances_squared(points, vars_to_rect(vars))
	end
end

function rect_matches(points, rect)
	if rect.size.x < 6 or rect.size.y < 6 then
		return false
	end

	local perim = rect.size:sum() * 2
	local ratio = vec:path_len(points) / perim
	return math.abs(ratio - 1) < 0.15
end

function rect_to_shape(rect)
	return foreach({
		vec(0, 0),
		vec(rect.size.x, 0),
		vec(rect.size.x, rect.size.y),
		vec(0, rect.size.y),
		vec(0, 0),
	}, function(_, p) return rotated(p, rect.angle) + rect.pos end)
end

function try_rect_fit(points)
	local min_point, max_point = vec:bounding_box(points)
	local size = max_point - min_point
	local initial = {
		min_point.x, min_point.y,
		size.x, size.y,
		0,
	}
	local conf = { max_iterations = 1000 }

	local result = multivar_optimise(initial, make_rect_cost(points), conf)
	print('result:')
	print('\tvars: '..tostring(vec(result.vars)))
	print('\tcost: '..tostring(result.cost))
	print('\titerations: '..tostring(result.iterations))
	local rect = vars_to_rect(result.vars)

	if not rect_matches(points, rect) then
		return nil
	end

	return {
		cost = result.cost,
		shape = rect_to_shape(rect),
		kind = "rect",
	}
end
