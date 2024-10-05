require "maths"
require "utils"


-- nelder-mead
-- `initial`: initial guess (list of numbers)
-- `cost_fn`: cost function (list of numbers -> number)
-- `conf`: config table
function multivar_optimise(initial, cost_fn, conf)
	-- TODO #enhancement: be able to accept a list of `initial`s, to repeat the process
	-- & pick the best result
	local cfg = update({
		max_iterations = 10000,
		tolerance = 0.001,

		coef_reflect = 1.0,
		coef_expand = 2.0,
		coef_contract = 0.5,
		coef_shrink = 0.5,
	}, conf)

	-- list of (#initial + 1) vertices around `initial`
	local simplex = Simplex.around(initial, nil, cost_fn)

	local iterations = 0

	-- fairly literal translation of https://en.wikipedia.org/wiki/Nelder%E2%80%93Mead_method#One_possible_variation_of_the_NM_algorithm
	while iterations <= cfg.max_iterations and simplex.verts[1].cost >= cfg.tolerance do
		-- TODO #speed: may be faster to have persistent `centroid`, `reflected` etc.
		--              objects & modify them, rather than recreating every iteration
		local centroid = simplex:centroid()

		local worst_vert = last(simplex.verts)

		local reflected = reflection(centroid, worst_vert, cfg.coef_reflect, cost_fn)
		if reflected.cost < simplex.verts[#simplex.verts - 1].cost and
		   reflected.cost >= simplex.verts[1].cost then
			simplex.verts[#simplex.verts] = reflected
			simplex:sort()
		elseif reflected.cost < simplex.verts[1].cost then
			local expanded = expansion(centroid, reflected, cfg.coef_expand, cost_fn)
			if expanded.cost < reflected.cost then
				simplex.verts[#simplex.verts] = expanded
				simplex:sort()
			else
				simplex.verts[#simplex.verts] = reflected
				simplex:sort()
			end
		elseif reflected.cost < worst_vert.cost then
			local contracted = contraction(centroid, reflected, cfg.coef_contract, cost_fn)
			if contracted.cost < reflected.cost then
				simplex.verts[#simplex.verts] = contracted
				simplex:sort()
			else
				shrink(simplex, cfg.coef_shrink, cost_fn)
			end
		else
			local contracted = contraction(centroid, worst_vert, cfg.coef_contract, cost_fn)
			if contracted.cost < worst_vert.cost then
				simplex.verts[#simplex.verts] = contracted
				simplex:sort()
			else
				shrink(simplex, cfg.coef_shrink, cost_fn)
			end
		end

		iterations = iterations + 1
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
	for i=2,#simplex.verts do
		simplex.verts[i] = contraction(vec(simplex.verts[1].point), simplex.verts[i], coef, cost_fn)
	end
	simplex:sort()
end
