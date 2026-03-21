local DeviceIdService = game:GetService("DeviceIdService")
local Players = game:GetService("Players")

-- Production state test
local Ecosystem = require("../")

local TestController = Ecosystem.NewEcosystem("RoamingChasingNPC")

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

TestController:AddCustomProperty("Host")
TestController:SetFunctionEnviorment("ActivationDistance", 100)
TestController:SetFunctionEnviorment("ChaseSpeed", 23)
TestController:SetFunctionEnviorment("RoamSpeed", 16)

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

TestController:AddStateAndFeature("Lock", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
	while task.wait() do
		print("Stunned")
	end
end)

TestController:Freeze()

print(TestController.Frozen)

local TestHost = script.Parent.Parent.Parent.TestObjects.StateTest
local SpeciesTest = Ecosystem.NewSpecies("RoamingChasingNPC", TestHost)

SpeciesTest:Start("Roam")

task.wait(10)
TestController:UpdateEnvVar("ChaseSpeed", 80)
warn("Updated")

SpeciesTest:ForceState("Lock")

task.wait(3)

SpeciesTest:Stop()

SpeciesTest:Start("Lock")

task.wait(1)

-- Will error as it tries to update using the Start function
--SpeciesTest:Start("Lock")

-- Use FroceState if you want to update a state manually

SpeciesTest:ForceState("Roam")
