require "shapes.circle"
require "shapes.line"


function try_shape_fit(path)
	-- TODO #finish
	local candidate_fns = {
		try_circle_fit,
		try_line_fit,
	}

	local best = nil

	for _,fn in ipairs(candidate_fns) do
		local res = fn(path)
		if best == nil or res.cost < best.cost then
			best = res
		end
	end

	return best
end
