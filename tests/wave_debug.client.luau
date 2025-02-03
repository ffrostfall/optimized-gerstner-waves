local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ocean = require(ReplicatedStorage.ocean)

local debug_point_template = Instance.new("Part")
debug_point_template.Size = vector.one / 5
debug_point_template.Anchored = true
debug_point_template.CanCollide = false
debug_point_template.Transparency = 0
debug_point_template.BrickColor = BrickColor.new("Bright red")

local plane = ocean.create_plane(30, 30)
local plane_parts: { [vector]: Part } = {}

local waves = {
	ocean.create_wave(vector.create(0.2, 0, 0), 0.5),
	ocean.create_wave(vector.create(0, 0, 1), 0.5),
	ocean.create_wave(vector.create(0.5, 0, 0.5), 0.4),
}

for _, undisturbed_point in plane do
	local part = debug_point_template:Clone()
	part.Parent = workspace

	plane_parts[undisturbed_point] = part
end

local function update_wave_points()
	local solved_plane = ocean.solve_plane_async(plane, waves, os.clock())

	debug.profilebegin("updating the part points")
	local parts: { BasePart } = {}
	local coordinate_frames: { CFrame } = {}

	for undisturbed_point, offset in solved_plane do
		local part = plane_parts[undisturbed_point]
		local real_point_position = vector.create(undisturbed_point.X, 0, undisturbed_point.Y)
		local solved_offset = undisturbed_point + offset

		-- take the 2D vector and convert it to a 3D vector
		table.insert(coordinate_frames, CFrame.new(real_point_position + solved_offset))
		table.insert(parts, part)
	end

	workspace:BulkMoveTo(parts, coordinate_frames, Enum.BulkMoveMode.FireCFrameChanged)
	debug.profileend()
end

RunService.PreRender:Connect(update_wave_points)
