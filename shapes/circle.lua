require "maths"
require "optimise"
require "utils"


function circle_distance_squared(points, circle)
	return sum_of_squares(foreach(points, function(_,  point)
		-- distance to radius
		return math.abs((circle.origin - point):dist() - circle.radius)
	end))
end

-- turn a list of inputs into an abstract circle structure
-- TODO #cleanup: could just make this a `Circle` class constructor (& same for other shapes)
function vars_to_circle(vars)
	return {
		origin = vec(vars[1], vars[2]),
		radius = vars[3],
	}
end

-- cost function
function make_circle_cost(points)
	return function(vars)
		return circle_distance_squared(points, vars_to_circle(vars))
	end
end

-- some heuristics to avoid matching slightly curved lines as small sections of big
-- circles
function circle_matches(points, circle)
	local circumference = 2 * math.pi * circle.radius
	if circumference < 10 then return false end

	local ratio = vec:path_len(points) / circumference
	return math.abs(ratio - 1) < 0.15
end

-- TODO #enhancement: seems too picky (think cost remains fairly high?)
function try_circle_fit(points)
	local centroid = vec:centroid(points)
	local min_point, max_point = vec:bounding_box(points)
	local initial = { centroid.x, centroid.y,
	                  math.max(max_point.x - min_point.x, max_point.y - min_point.y) }
	local conf = { max_iterations = 1000 }

	local result = multivar_optimise(initial, make_circle_cost(points), conf)
	-- print('result:')
	-- print('\tvars: '..tostring(vec(result.vars)))
	-- print('\tcost: '..tostring(result.cost))
	-- print('\titerations: '..tostring(result.iterations))
	local circle = vars_to_circle(result.vars)

	if not circle_matches(points, circle) then
		return nil
	end

	return {
		cost = result.cost,
		shape = circle,
		kind = "circle",
	}
end
