export type Plane = { vector }

-- Our solved plane will take our "undisturbed points" (the key) and the offset (the value).
export type SolvedPlane = { [vector]: vector }

export type Wave = {
	actor: Actor & { invoke: BindableFunction },

	direction: vector,
	amplitude: number,
	frequency: number,

	unique_id: string,
}

local worker_template = script.worker
local worker_pool = script.pool

local function generate_unique_id(): string
	-- it doesn't really matter, because we are at most having like, 10 waves.
	return tostring(math.random(0, 2 ^ 16))
end

local ocean = {
	gravity_factor = 9.81,
}

--[[
	Create an array of vectors based off a width and height. This will be our plane.
]]
function ocean.create_plane(width: number, height: number): Plane
	local arr: { vector } = table.create(width * height, vector.zero)

	for x = 1, width do
		for y = 1, height do
			-- (x - 1) * width + y will give us the unique index for the vector.
			-- We're using table.create (to avoid needing growth) so table.insert doesn't work here
			arr[((x - 1) * width) + y] = vector.create(x, 0, y)
		end
	end

	return arr
end

function ocean.create_wave(direction: vector, amplitude: number, gravity: number?): Wave
	if vector.magnitude(direction) * amplitude >= 0.98 then
		-- Any wave with a magnitude of 1 or higher will "loop in" on itself, giving weird results.
		-- We have an epsilon of 0.02 because extremely sharp waves seem to still cause weird visuals?
		warn("(wave direction * amplitude) exceed 0.98, will loop in on itself")
	end

	-- Frequency is based off the magnitude of the wave vector & gravity, as specified in the paper.
	local frequency = math.sqrt(gravity or ocean.gravity_factor * vector.magnitude(direction))

	local wave_worker = worker_template:Clone()
	wave_worker.Parent = worker_pool :: any -- thanks luaulsp for not supporting changing .Parent lol

	local wave: Wave = {
		-- weird type issue here, Actor could not be converted into Actor
		actor = wave_worker :: any,

		direction = direction,
		amplitude = amplitude,
		frequency = frequency,

		unique_id = generate_unique_id(),
	}

	return wave
end

--[[
	It's async because we're yielding until all waves are complete
]]
function ocean.solve_plane_async(plane: Plane, waves: { Wave }, t: number): { [vector]: vector }
	local running_thread = coroutine.running()

	-- [unique wave id]: SolvedPlane | false (not arrived yet)
	local completed_wave_offsets: { [string]: { vector } | false } = {}
	local all_wave_ids: { string } = {}

	for _, wave in waves do
		completed_wave_offsets[wave.unique_id] = false
		table.insert(all_wave_ids, wave.unique_id)

		-- We need to spawn this in a different thread because it is going to yield
		-- It's actually worse to split this function off because it uses two upvalues.
		-- If it were split up, we'd need to do weird table reference stuff.
		task.spawn(function()
			local points = wave.actor.invoke:Invoke(plane, wave.direction, wave.amplitude, wave.frequency, t)

			-- Mark the wave as complete.
			completed_wave_offsets[wave.unique_id] = points

			-- Resumption logic:
			-- If all waves are complete, we can resume the main thread.
			local all_waves_complete = true
			for _, wave_id in all_wave_ids do
				if completed_wave_offsets[wave_id] == false then
					all_waves_complete = false
					break
				end
			end

			if all_waves_complete then
				task.spawn(running_thread)
			end
		end)
	end

	-- The thread will be resumed when all waves are complete.
	-- We can't use anything relating to task.wait because it is guaranteed to wait for the next frame.
	-- coroutine.yield can be used for yielding within the frame.
	coroutine.yield()

	local solved_plane: SolvedPlane = {}

	-- Pre-populate the plane, so we can add the offsets up.
	for _, undisturbed_point in plane do
		solved_plane[undisturbed_point] = vector.zero
	end

	for _, solved_wave in completed_wave_offsets do
		-- Asserts are better than typecasts
		assert(typeof(solved_wave) ~= "boolean", "luau, or wave did not complete?")

		-- Workaround because you can't send vectors as keys between actors.
		for plane_index, offset in solved_wave do
			solved_plane[plane[plane_index]] += offset
		end
	end

	return solved_plane
end

return ocean
