---
sidebar_position: 3
---

# WorkFlows

# [Documentation](/api/EcosystemGlobalServices)

## 1. Creating an Ecosystem object
----

```lua
-- Get Dependencies
local Players = game:GetService("Players")

-- Production state test
local Ecosystem = require("../")

-- Initializes an Ecosystem with the ID of "RoamingChasingNPC"
local TestController = Ecosystem.NewEcosystem("RoamingChasingNPC")

-- A function that will be used throughout the demonstration
local function GetClosestPlayer(Pos: Vector3): (Player, number)
	local ClosestPlr, ClosestDis = nil, math.huge
	for _, V: Player in Players:GetPlayers() do
		local char = V.Character
		if char then
			if (char.HumanoidRootPart.Position - Pos).magnitude < ClosestDis then
				ClosestDis = (char.HumanoidRootPart.Position - Pos).magnitude
				ClosestPlr = V
			end
		end
	end
	print(ClosestPlr, ClosestDis)
	return ClosestPlr, ClosestDis
end

```

### Creating the Ecosystem Template

```lua
--[[
    Arguably the most time intensive part.
    This is when you create your template icluding creating the State functions 
    and Gloabl and local properties
]]

-- Creates a custom `local` property with the index of "Host" and initial value of "nil"
TestController:AddCustomProperty("Host")

-- Creates a custom `global` properties with a index and initial value
TestController:SetFunctionEnviorment("ActivationDistance", 100)
TestController:SetFunctionEnviorment("ChaseSpeed", 23)
TestController:SetFunctionEnviorment("RoamSpeed", 16)


--[[
    Creates a new state with the ID of "Roam" and the function it should run.

    ALL state functions must return a valid state ID, "Stop", or call CurrentSpecies:Stop()

    It is recommended to use While loops instead of Run service loops becuase While 
    loops are thread controlled while RunService events are RBXScriptSignals and run on a seperate thread.
    This makes them hard to control and could create some logic errors if used.
]]
TestController:AddStateAndFeature("Roam", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
	local Humanoid: Humanoid = CurrentSpecies.ObjectBinded.Humanoid
	Humanoid.WalkSpeed = CurrentSpecies:GetEnviorment("RoamSpeed")

	while task.wait(0.1) do
		local ClosestPlr, Dis = GetClosestPlayer(CurrentSpecies.ObjectBinded.HumanoidRootPart.Position)
		if Dis < CurrentSpecies:GetEnviorment("ActivationDistance") then
			CurrentSpecies:SetProperty("Host", ClosestPlr)
			return "Chase"
		else
			Humanoid:MoveTo(Vector3.new(math.random(700, 750), 0, math.random(400, 450)))
		end
	end
	return "Roam"
end)

--[[
    Creates a new state with the ID of "Chase" and the function it should run.
]]
TestController:AddStateAndFeature("Chase", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
	local Humanoid: Humanoid = CurrentSpecies.ObjectBinded.Humanoid
	local ClosestPlr: Player = CurrentSpecies:GetProperty("Host")

	while task.wait() do
		Humanoid.WalkSpeed = CurrentSpecies:GetEnviorment("ChaseSpeed")
		local _, Dis = GetClosestPlayer(CurrentSpecies.ObjectBinded.HumanoidRootPart.Position)

		if Dis > CurrentSpecies:GetEnviorment("ActivationDistance") then
			return "Roam"
		else
			if Dis < 3 then
				ClosestPlr.Character.Humanoid.Health -= 10
			end
			Humanoid:MoveTo(ClosestPlr.Character.PrimaryPart.Position)
		end
	end
end)

--[[
    Creates a new state with the ID of "Lock" and the function it should run.

    This function is unable to return itself thus freezeing the Species,
    The only way to unlock them is by using the Species object its assigned to and call
    `Stop` or `ForceState` to change the state manually.

    You are also able to use the Ecosystem class to control a mass amount of species easily
]]
TestController:AddStateAndFeature("Lock", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
	while task.wait() do
		print("Stunned")
	end
end)

```

### Freezing

```lua
--[[
    The most important part of the Ecosystem object.
    You must call Freeze at the end to signify that the template is contructed.

    This will turn the object into a read-only state and will allow Species objects to be created
    and assigned to it's template.
]]

-- Freezes the controller to allow Specie object to be created.
TestController:Freeze()

```

## 2. Creating an Species
----


```lua
--[[
    Once a Ecosystem template/Controller is created
    AND FROZEN.
    You are able to create Specie (runtim) objects assigned to it.
]]

print(TestController.Frozen) -- true

-- Reference to a NPC model
local TestHost = script.Parent.Parent.Parent.TestObjects.StateTest

--[[
    Creates a specie object from the Ecosystem template of "RoamingChasingNPC"
    And links the NPC model to it
]]
local SpeciesTest = Ecosystem.NewSpecies("RoamingChasingNPC", TestHost)
```

### Running a Species object

```lua
-- The species object created above
local SpeciesTest = Ecosystem.NewSpecies("RoamingChasingNPC", TestHost)

-- Starts the runtime at the state "Roam"
SpeciesTest:Start("Roam")
```

## 3. Runtime
----

### Updating a Enviorment Variable

```lua
task.wait(10)

-- Updates the global enviorment variable "ChaseSpeed" to 80
TestController:UpdateEnviormentVariable("ChaseSpeed", 80)
-- This will also trigger the `EnviormentUpdate` signal to run

warn("Updated")
```

### Forcing a state at runtime

```lua
-- Forces the state `Lock` on the current species
SpeciesTest:ForceState("Lock")

task.wait(3)

-- Stops the species object from running
SpeciesTest:Stop()

-- Reruns lock
SpeciesTest:Start("Lock")

task.wait(1)

-- WILL ERROR as it tries to update using the Start function
SpeciesTest:Start("Lock")

-- Use FroceState if you want to update a state manually
SpeciesTest:ForceState("Roam")
```