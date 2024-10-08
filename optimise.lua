require "maths"
require "utils"


-- nelder-mead
-- `initial`: initial guess (list of numbers)
-- `cost_fn`: cost function (list of numbers -> number)
-- `conf`: config table
function multivar_optimise(initial, cost_fn, conf)
	local cfg = update({
		max_iterations = 10000,    -- maximum number of iterations
		tolerance = 50,            -- cost below which to stop early
		stability_threshold = 25,  -- number of iterations without cost change above which to stop early

		coef_reflect = 1.0,
		coef_expand = 2.0,
		coef_contract = 0.5,
		coef_shrink = 0.5,
	}, conf)

	-- list of (#initial + 1) vertices around `initial`
	local simplex = Simplex.around(initial, nil, cost_fn)

	local iterations = 0
	local since_last_change = 0

	-- points that get made most loops; make once here to try and save on constructions
	local reflected = Vert(#simplex.verts[1].point)
	local expanded = Vert(#simplex.verts[1].point)
	local contracted = Vert(#simplex.verts[1].point)

	-- fairly literal translation of https://en.wikipedia.org/wiki/Nelder%E2%80%93Mead_method#One_possible_variation_of_the_NM_algorithm
	while iterations <= cfg.max_iterations and
	      simplex.verts[1].cost >= cfg.tolerance and
	      since_last_change < cfg.stability_threshold do
		local old_cost = simplex.verts[1].cost
		local centroid = simplex:centroid()

		local worst_vert = last(simplex.verts)

		-- local reflected = reflection(centroid, worst_vert, cfg.coef_reflect, cost_fn)
		update_reflection(centroid, worst_vert, cfg.coef_reflect, cost_fn, reflected)
		if reflected.cost < simplex.verts[#simplex.verts - 1].cost and
		   reflected.cost >= simplex.verts[1].cost then
			simplex.verts[#simplex.verts] = reflected:copy()
			simplex:sort()
		elseif reflected.cost < simplex.verts[1].cost then
			-- local expanded = expansion(centroid, reflected, cfg.coef_expand, cost_fn)
			update_expansion(centroid, reflected, cfg.coef_expand, cost_fn, expanded)
			if expanded.cost < reflected.cost then
				simplex.verts[#simplex.verts] = expanded:copy()
				simplex:sort()
			else
				simplex.verts[#simplex.verts] = reflected:copy()
				simplex:sort()
			end
		elseif reflected.cost < worst_vert.cost then
			-- local contracted = contraction(centroid, reflected, cfg.coef_contract, cost_fn)
			update_contraction(centroid, reflected, cfg.coef_contract, cost_fn, contracted)
			if contracted.cost < reflected.cost then
				simplex.verts[#simplex.verts] = contracted:copy()
				simplex:sort()
			else
				shrink_inplace(simplex, cfg.coef_shrink, cost_fn)
			end
		else
			-- local contracted = contraction(centroid, worst_vert, cfg.coef_contract, cost_fn)
			update_contraction(centroid, worst_vert, cfg.coef_contract, cost_fn, contracted)
			if contracted.cost < worst_vert.cost then
				simplex.verts[#simplex.verts] = contracted:copy()
				simplex:sort()
			else
				shrink_inplace(simplex, cfg.coef_shrink, cost_fn)
			end
		end

		iterations = iterations + 1
		if simplex.verts[1].cost == old_cost then
			since_last_change = since_last_change + 1
		else
			since_last_change = 0
		end
	end

	return {
		vars = simplex.verts[1].point,
		cost = simplex.verts[1].cost,
		iterations = iterations,
	}
end

Vert = class({}, function(self, dim_or_point, cost)
	if type(dim_or_point) == 'table' then
		-- given a point directly
		self.point = dim_or_point
	else
		-- just given a number of dimensions; fill with zeros
		self.point = vec:full(dim_or_point, 0).data
	end
	self.cost = cost or 0
end)
function Vert:copy()
	return Vert(vec(self.point):copy().data, self.cost)
end

Simplex = class({}, function(self, dim)
	self.verts = {}
	for i=1,dim+1 do
		table.insert(self.verts, Vert(dim))
	end
end)

function Simplex:update_costs(cost_fn)
	for _,vert in ipairs(self.verts) do
		vert.cost = cost_fn(vert.point)
	end
	self:sort()
end

function Simplex:sort()
	table.sort(self.verts, function(a, b) return a.cost < b.cost end)
end

-- NOTE: doesn't include the final ('worst') vertex, cause that's what's needed in the
-- calculation
function Simplex:centroid()
	local res = vec:full(#self.verts[1].point, 0)
	for i=1,#self.verts - 1 do
		res = res + vec(self.verts[i].point)
	end
	return res / (#self.verts - 1)
end

-- TODO #enhancement: try something more intuitive than this; not clear why it's done
-- like this
function Simplex.around(point, sizes, cost_fn)
	if sizes == nil then
		sizes = {}
		for _,val in ipairs(point) do
			table.insert(sizes, (0.05 * math.abs(val)) + 0.00025)
		end
	end

	local res = Simplex(#point)
	for i=1,#res.verts do
		for j=1,#point do
			res.verts[i].point[j] = point[j] + ternary(i - 1 == j, sizes[j], 0.0)
		end
	end

	res:update_costs(cost_fn)
	return res
end

-- NOTE: centroid is a `vec`, & `worst_vert` is a `Vert`
function reflection(centroid, worst_vert, coef, cost_fn)
	local point = centroid:map(function(i, cv)
		return cv + coef * (cv - worst_vert.point[i])
	end)
	return Vert(point.data, cost_fn(point.data))
end

function expansion(centroid, reflected, coef, cost_fn)
	return reflection(centroid, reflected, -coef, cost_fn)
end

contraction = expansion

function shrink(simplex, coef, cost_fn)
	local best = vec(simplex.verts[1].point)
	for i=2,#simplex.verts do
		simplex.verts[i] = contraction(vec(simplex.verts[1].point), simplex.verts[i], coef, cost_fn)
	end
	simplex:sort()
end

function update_reflection(centroid, worst_vert, coef, cost_fn, out)
	for i=1,#out.point do
		out.point[i] = centroid[i] + coef * (centroid[i] - worst_vert.point[i])
	end
	out.cost = cost_fn(out.point)
	return out
end

function update_expansion(centroid, reflected, coef, cost_fn, out)
	return update_reflection(centroid, reflected, -coef, cost_fn, out)
end

update_contraction = update_expansion

function shrink_inplace(simplex, coef, cost_fn)
	local best = vec(simplex.verts[1].point)
	for i=2,#simplex.verts do
		update_contraction(best, simplex.verts[i], coef, cost_fn, simplex.verts[i])
	end
	simplex:sort()
end
