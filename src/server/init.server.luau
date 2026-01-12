--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ECS = require(ReplicatedStorage.Shared.ECS)


local a = ECS.Component() :: ECS.Component
local b = ECS.Component() :: ECS.Component
ECS.FreeComponent(a)
local c = ECS.Component() :: ECS.Component

local t = ECS.Entity() :: ECS.Entity

ECS.Add(t,c)

print(ECS.ReadComponentId(c))