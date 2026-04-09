--!strict
local Ecosystem = require("../")
local TestEcosystem = Ecosystem.NewEcosystem("Test")

-- Will error as duplicate ID's are found
--Ecosystem.NewEcosystem("Test")

TestEcosystem:AddStateAndFeature("idle", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
	-- Do static lines up here stuff that only needs to be assigned once at the start of a state

	while true do
		warn("Run", StateFrom)
		warn(CurrentSpecies.CurrentState)
		-- All main loop logic should happen inside
		--task.wait(5)
		task.wait()

		if math.random(1, 2) == 1 then
			print("1")
			return "Next State 1" -- Returns the next State string
		else
			--print("2")
			return "Next State 1" -- ill add better type annotations
		end
	end
end)

TestEcosystem:AddStateAndFeature("Next State 1", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
	print("stop")
	-- Should close and cause the thread to be garbage collected
	--CurrentSpecies:Stop()
	return "Stop"
end)

-- A property that is linked to the SPECIES
TestEcosystem:AddCustomProperty("CurrentTarget", "Non") -- Local

-- A property that is linked to the ECOSYSTEM
TestEcosystem:SetFunctionEnviorment("Walkspeed", 20) -- Global
TestEcosystem:SetFunctionEnviorment("Math", math.huge)

--[[TestEcosystem.__EnvUpdate:Connect(function(...)
	warn(...)
end)]]

-- false
print(TestEcosystem.Frozen)

-- Will error because ecosystem is not primed
--TestEcosystem:UpdateEnvVar("Walkspeed", 100)
-- Freezes current ecosystem
TestEcosystem:Freeze()

-- true
print(TestEcosystem.Frozen)

-- Will error as ecosystem is now frozen
--TestEcosystem:SetFunctionEnviorment("Range", 150)

-- Updates
TestEcosystem:UpdateEnvVar("Walkspeed", nil)
TestEcosystem:UpdateEnvVar("Walkspeed", 300)

-- Gets single var
print(TestEcosystem:GetEnviorment("Walkspeed"))
-- Gets all vars
print(TestEcosystem:GetEnviorment(), TestEcosystem)

Ecosystem.NewEcosystem("Test2")

-- Creates a species sub type
local TestSpecies = Ecosystem.NewSpecies("Test")

-- Will error as Prime hasnt been called yet
--Ecosystem.NewSpecies("Test2")

-- Gets data assigned
print(TestSpecies, getmetatable(TestSpecies))

TestSpecies.StateChanged:Connect(function(a0: string, a1: string)
	print("Event:", a0, a1)
end)

-- Starts running cycle
TestSpecies:Start("idle")

-- Errors as start has been called already
--TestSpecies:Start("idle")

-- Stops the running thread and closes all current calls
--TestSpecies:Stop()

--task.wait(1)

-- Handeling thread is disabled the frame after called
task.wait()
print(TestSpecies.HandelingThread)

task.wait(1)

-- Restarts the Species after it closed itself
TestSpecies:Start("idle")
