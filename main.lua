-- https://www.jmeiners.com/why-train-when-you-can-optimize/

require "maths"
require "record"
require "shapes"


config = {
	record_paths = false,
	replay_paths_from_file = "testpath",

	path_joint_distance = 10,

	-- background colour
	bg_col = { 1, 1, 1, 1 },
	path_col = { 0, 0, 0, 1 },
	shape_col = { 1, 0, 0, 1 },
}

state = {
	-- {x=x, y=y}
	mouse = vec(0, 0),

	-- list of lists of {x=x, y=y}
	paths = {},

	-- {"line" = { list of lines }, "circle" = { list of circles } ... }
	shapes = {},

	-- currently drawing a path?
	is_drawing = false,

	-- if we've specified a config.replay_paths_from_file, then this will be the list of
	-- paths from that file. (note: does not get reset by reset())
	paths_to_replay = {},
	-- how far through the paths to replay are we?
	replay_idx = 1,

	reset = function(self)
		self.paths = {}
		self.shapes = {}
		self.is_drawing = false

		-- note: don't reset paths_to_replay, just the index.
		self.replay_idx = 1
	end,
}

shape_painter = {}
function shape_painter.line(shape)
	love.graphics.line(shape.start.x, shape.start.y,
	                   shape.finish.x, shape.finish.y)
end
function shape_painter.circle(shape)
	love.graphics.circle("line", shape.origin.x, shape.origin.y, shape.radius)
end
function shape_painter.rect(shape)
	for i=1,#shape-1 do
		love.graphics.line(shape[i].x,   shape[i].y,
		                   shape[i+1].x, shape[i+1].y)
	end
end

function add_shape(optimisation_result)
	if optimisation_result == nil then
		return
	end

	if state.shapes[optimisation_result.kind] == nil then
		state.shapes[optimisation_result.kind] = {}
	end

	table.insert(state.shapes[optimisation_result.kind], optimisation_result.shape)
end

function love.load()
	math.randomseed(os.time())
	state.paths_to_replay = read_paths(config.replay_paths_from_file)
	state:reset()
end

function draw_paths()
	love.graphics.setColor(config.path_col)
	for _, path in ipairs(state.paths) do
		for i=1,#path-1 do
			love.graphics.line(path[i].x,   path[i].y,
			                   path[i+1].x, path[i+1].y)
		end
	end

	if state.is_drawing then
		assert(#state.paths > 0)
		local final_path = last(state.paths)
		assert(#final_path > 0)
		local final_point = last(final_path)

		love.graphics.line(final_point.x, final_point.y,
		                   state.mouse.x, state.mouse.y)
	end
end

function draw_shapes()
	love.graphics.setColor(config.shape_col)
	for kind, shapes in pairs(state.shapes) do
		for _, shape in ipairs(shapes) do
			shape_painter[kind](shape)
		end
	end
end

function love.draw()
	love.graphics.clear(config.bg_col)

	draw_shapes()
	draw_paths()
end

function love.mousemoved(x, y, dx, dy, istouch)
	state.mouse = vec(x, y)
	if state.is_drawing then
		assert(#state.paths > 0)

		local curr_path = last(state.paths)

		local should_make_new_point = true
		if #curr_path > 0 and
		   last(curr_path):dist(state.mouse) < config.path_joint_distance then
			should_make_new_point = false
		end

		if should_make_new_point then
			table.insert(curr_path, state.mouse)
		end
	end
end

function love.mousepressed(x, y, button)
	state.is_drawing = true
	table.insert(state.paths, {state.mouse})
end

function love.mousereleased(x, y, button)
	state.is_drawing = false
	path_finished()
end

function love.keyreleased(key, scancode, isrepeat)
	if key == 'r' then
		state:reset()
	elseif key == 'space' then
		-- replay a path, if applicable
		if state.replay_idx <= #state.paths_to_replay then
			table.insert(state.paths, state.paths_to_replay[state.replay_idx])
			path_finished()
			state.replay_idx = state.replay_idx + 1
		end
	end
end

function path_finished()
	-- add_shape(profile(try_shape_fit(last(state.paths))))
	add_shape(profile(try_shape_fit, 10, last(state.paths)))
	if config.record_paths then
		print_path(last(state.paths))
	end
end