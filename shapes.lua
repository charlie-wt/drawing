require "shapes.circle"
require "shapes.line"
require "shapes.rect"


function acceptable_tolerance(path)
	local per_point_tolerance = 6
	return #path * (per_point_tolerance ^ 2)
end

function try_shape_fit(path)
	local candidate_fns = {
		try_circle_fit,
		try_line_fit,
		try_rect_fit,
	}

	local best = nil

	-- TODO #speed: parallelise, dispatch to another job to not block the gui
	for _,fn in ipairs(candidate_fns) do
		local res = fn(path)
		if res ~= nil and (best == nil or res.cost < best.cost) then
			best = res
		end
	end

	if best == nil or best.cost > acceptable_tolerance(path) then
		-- print("not a shape")
		return nil
	end

	return best
end
