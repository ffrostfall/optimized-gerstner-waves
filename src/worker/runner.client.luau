-- Just a glue file
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local compute = require(ReplicatedStorage.ocean.compute)

local bindable = script.Parent.invoke

bindable.OnInvoke = compute
