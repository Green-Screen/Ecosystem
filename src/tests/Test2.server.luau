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
TestController:SetFunctionEnviorment("ActivationDistance", 50)
TestController:SetFunctionEnviorment("ChaseSpeed", 23)

TestController:AddStateAndFeature("Roam", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
	local Humanoid: Humanoid = CurrentSpecies.ObjectBinded.Humanoid
	Humanoid.WalkSpeed = 16

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
	Humanoid.WalkSpeed = CurrentSpecies:GetEnviorment("ChaseSpeed")
	local ClosestPlr:Player = CurrentSpecies:GetProperty("Host")

	while task.wait() do
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

TestController:Freeze()

print(TestController.Frozen)

local TestHost = script.Parent.Parent.Parent.TestObjects.StateTest
local SpeciesTest = Ecosystem.NewSpecies("RoamingChasingNPC", TestHost)

SpeciesTest:Start("Roam")