require "maths"
require "optimise"


-- get sum of squares of distances from each point in `points` to the ideal line `line`
-- (origin & direction)
function line_distance_squared(points, line)
	local normal = orthogonal(line.direction)

	local distances = {}
	for _,point in ipairs(points) do
		table.insert(distances, (point - line.origin):dot(normal))
	end
	return sum_of_squares(distances)
end

-- get the 2D vector that points from the origin to the given angle
function vec_from_angle(a)
	return vec(math.cos(a), math.sin(a))
end

-- turn a list of inputs into an { origin, direction } ideal infinite line structure
function vars_to_line(vars)
	return {
		origin = vec(vars[1], vars[2]),
		direction = vec_from_angle(vars[3]),
	}
end

-- create a cost function for trying to optimise the given path to an ideal line
function make_line_cost(points)
	return function(vars)
		return line_distance_squared(points, vars_to_line(vars))
	end
end

-- turn an infinite { origin, direction } into a drawable, finite { start_point, end_point }
function line_to_shape(points, line)
	local distances = {}
	for _,point in ipairs(points) do
		table.insert(distances, (point - line.origin):dot(line.direction))
	end

	return {
		start = line.origin + (line.direction * min(distances)),
		finish = line.origin + (line.direction * max(distances))
	}
end

-- try to fit `points` (a list of `vec`s) to a line segment; returns {`cost`, `shape`}
function try_line_fit(points)
	local centroid = vec:centroid(points)
	local initial = { centroid.x, centroid.y, 0 }
	local conf = { max_iterations = 1000 }

	local result = multivar_optimise(initial, make_line_cost(points), conf)

	print('result:')
	print('\tvars: '..tostring(vec(result.vars)))
	print('\tcost: '..tostring(result.cost))
	print('\titerations: '..tostring(result.iterations))

	return {
		cost = result.cost,
		shape = line_to_shape(points, vars_to_line(result.vars)),
		kind = "line"
	}
end
