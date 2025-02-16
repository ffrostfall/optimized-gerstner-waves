local HALF_PI = math.pi / 2

--[[
	This is the function which gets in parallel for each wave.
		
	As in src/worker/runner.client.luau, it gets "glued" to the "invoke" bindablefunction under the actor.
]]
return function(points: { vector }, direction: vector, amplitude: number, frequency: number, t: number): { vector }
	-- Pre-computing the normalized vector of the wave direction. We use this in the displacement vector for each point.
	local normalized_direction = vector.normalize(direction)

	local solved_offsets: { vector } = {}

	local frequency_t = frequency * t

	task.desynchronize()

	for _, undisturbed_point in points do
		-- This segment is just directly solving the equations from the paper.
		local displacement_factor = vector.dot(direction, undisturbed_point) - frequency_t
		local displacement_factor_sin = math.sin(displacement_factor)

		-- cos(θ) == sin(θ - π/2)
		local displacement_vector = normalized_direction * amplitude * (displacement_factor_sin - HALF_PI)

		local solved_offset =
			vector.create(displacement_vector.X, amplitude * displacement_factor_sin, displacement_vector.Z)

		table.insert(solved_offsets, solved_offset)
	end

	return solved_offsets
end
