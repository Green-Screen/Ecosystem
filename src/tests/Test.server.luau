--!strict
local Ecosystem = require("../")

local TestEcosystem = Ecosystem.NewEcosystem("Test")

-- Will error as duplicate ID's are found
--Ecosystem.NewEcosystem("Test")

TestEcosystem:AddStateAndFeature("idle", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
	-- Do static lines up here stuff that only needs to be assigned once at the start of a state

	while true do
		-- All main loop logic should happen inside
		task.wait()

		if math.random(1, 2) == 1 then
			return "Next State 1" -- Returns the next State string
		else
			return "Next State 2" -- ill add better type annotations
		end
	end
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
print(TestEcosystem:IsPrimed())

-- Will error because ecosystem is not primed
--TestEcosystem:UpdateEnvVar("Walkspeed", 100)

-- Freezes current ecosystem
TestEcosystem:Prime()

-- true
print(TestEcosystem:IsPrimed())

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
Ecosystem.NewSpecies("Test")

-- Will error as Prime hasnt been called yet
Ecosystem.NewSpecies("Test2")
