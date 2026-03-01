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

-- false
print(TestEcosystem:IsPrimed())

-- Freezes current ecosystem
TestEcosystem:Prime()

-- true
print(TestEcosystem:IsPrimed())

-- Will error as ecosystem is now frozen
TestEcosystem:SetFunctionEnviorment("Range", 150)
