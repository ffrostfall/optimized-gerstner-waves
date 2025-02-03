--[[
	This is the function which gets in parallel for each wave.
		
	As in src/worker/runner.client.luau, it gets "glued" to the "invoke" bindablefunction under the actor.
]]
return function(
	points: { vector },
	direction: vector,
	amplitude: number,
	frequency: number,
	t: number
): ({ vector }, { vector })
	-- Pre-computing the normalized vector of the wave direction. We use this in the displacement vector for each point.
	local normalized_direction = vector.normalize(direction)

	-- Work-around because you cannot send vectors as keys between actors.
	local solved_points: { vector } = {}
	local solved_offsets: { vector } = {}

	task.desynchronize()

	for _, undisturbed_point in points do
		-- This segment is just directly solving the equations from the paper.
		local displacement_factor = vector.dot(direction, undisturbed_point) - (frequency * t)
		local displacement_vector = normalized_direction * amplitude * math.sin(displacement_factor)

		local solved_offset =
			vector.create(displacement_vector.X, amplitude * math.sin(displacement_factor), displacement_vector.Z)

		-- This is apart of our workaround for sending vectors as keys between actors.
		table.insert(solved_points, undisturbed_point)
		table.insert(solved_offsets, solved_offset)
	end

	task.synchronize()

	return solved_points, solved_offsets
end
