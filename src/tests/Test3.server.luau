local Players = game:GetService("Players")
local Ecosystem = require("../")
local TramService = require("../Dependencies/TramService")

local Object1 = script.Parent.Parent.Parent.TestObjects.StateTest
local Object2 = script.Parent.Parent.Parent.TestObjects.StateTest2

local Center = Vector3.new(853.5, 9.5, 407)

local function GetRandomPositionFromCenter()
	return Vector3.new(
		math.random(Center.X - 500, Center.X + 500),
		Center.Y,
		math.random(Center.Z - 500, Center.Z + 500)
	)
end

local NPCController = Ecosystem.NewEcosystem("HugNPC")
NPCController:AddCustomProperty("Target")
NPCController:SetFunctionEnviorment("SwitchStates", true)

NPCController:AddStateAndFeature("Wander", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
	warn("Chase")
	while task.wait(0.1) do
		CurrentSpecies.ObjectBinded.Humanoid:MoveTo(GetRandomPositionFromCenter())
		if CurrentSpecies:GetEnviorment("SwitchStates") == "Hug" then
			return "HugNearestNPC"
		end
	end
end)

NPCController:AddStateAndFeature("HugNearestNPC", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
	warn("Hug")
	local Target: Model = CurrentSpecies:GetProperty("Target")
	while task.wait() do
		CurrentSpecies.ObjectBinded.Humanoid:MoveTo(Target.HumanoidRootPart.Position)
		if CurrentSpecies:GetEnviorment("SwitchStates") == "Wander" then
			return "Wander"
		end
	end
end)

NPCController:AddStateAndFeature("Stun", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
	while task.wait() do
		print("Stunned")
	end
end)

NPCController:Freeze()

print(NPCController)

local Sp1 = Ecosystem.NewSpecies("HugNPC", Object1)
local Sp2 = Ecosystem.NewSpecies("HugNPC", Object2)

print(Sp1, Sp2)

Sp1:SetProperty("Target", Object2)
Sp2:SetProperty("Target", Object1)

local On = "Hug"
local function Swap()
	if On == "Hug" then
		On = "Wander"
	else
		On = "Hug"
	end
	return On
end

TramService.NewTram("Sig"):Connect(function()
	NPCController:UpdateEnvVar("SwitchStates", Swap())
	print("Signaled")
end)

Sp1:Start("Wander")
Sp2:Start("Wander")

Sp1.StateChanged:Connect(function(a0: string, a1: string): ...any?
	print("StateFrom:", a0, "\nNewState:", a1)
end)

NPCController.EnvUpdate:Connect(function(a0: string, a1, a2): ...any?
	print("EnvUpdated:", a0, "\nNewData:", a1, "\nOldData:", a2)
end)

task.wait(5)

NPCController:ForceAllStates("Stun")
NPCController:UpdateEnvVar("SwitchStates", Swap())
