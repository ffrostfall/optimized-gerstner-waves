local STDIO_FORWARD = { stdio = "forward" :: "forward" }

local process = require("@lune/process")
local task = require("@lune/task")

-- Spawn a Rojo sourcemap watch process for Luau LSP, because it usually is pretty buggy.\
task.spawn(function()
	process.spawn(
		"rojo",
		{ "sourcemap", "--output", "sourcemap.json", "--include-non-scripts", "--watch" },
		STDIO_FORWARD
	)
end)

task.spawn(function()
	process.spawn("rojo", { "serve" }, STDIO_FORWARD)
end)

-- Scheduler spinning to work around the lune scheduler bug
while true do
	task.wait(1)
end
