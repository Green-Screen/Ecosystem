--!strict

local Ecosystem = require("../")

local Object1 = script.Parent.Parent.Parent.TestObjects.StateTest2

--local Target = (workspace:WaitForChild("Patriots8800") :: any ).HumanoidRootPart :: BasePart
local Target = script.Parent.Parent.Parent.TestObjects.Get

local Center = Vector3.new(853.5, 9.5, 407)

local function GetRandomPositionFromCenter()
	return Vector3.new(
		math.random(Center.X - 500, Center.X + 500),
		Center.Y,
		math.random(Center.Z - 500, Center.Z + 500)
	)
end

local NPCController = Ecosystem.NewEcosystem("Wanderer")

NPCController:SetFunctionEnviorment("Trigger", false)

NPCController:AddStateAndFeature("Walk", function(CurrentSpecies: Ecosystem.Species, StateFrom: string?): string
	local Humanoid = (CurrentSpecies.ObjectBinded :: any).Humanoid :: Humanoid
	Humanoid.WalkSpeed = 20

	--NPCController:UpdateFunctionEnviorment("Trigger", false)

	while task.wait(0.5) do
		Humanoid:MoveTo(GetRandomPositionFromCenter())
	end
	return "Stop"
end)

NPCController:AddStateAndFeature("Chase", function(CurrentSpecies: Ecosystem.Species, StateFrom: string?): string
	local Humanoid = (CurrentSpecies.ObjectBinded :: any).Humanoid :: Humanoid
	Humanoid.WalkSpeed = 30

	--NPCController:UpdateFunctionEnviorment("Trigger", false)

	while task.wait() do
		Humanoid:MoveTo(Target.Position)
	end
	return "Stop"
end)

NPCController:Freeze()

local function SetNWO(M:Instance)
	for _, v in M:GetDescendants() do
		if v:IsA("BasePart") then
			v:SetNetworkOwner(nil)
		end
	end
end

for i = 1, 100 do
	local TmpOBJ = Object1:Clone()

	local S = Ecosystem.NewSpecies("Wanderer", TmpOBJ)
	TmpOBJ.Parent = Object1.Parent
	TmpOBJ.Name = "T"

	SetNWO(TmpOBJ)

	S:Start("Walk")

	S.StateChanged:Connect(function(a0: string?, a1: string): ...any? 
		print(`Oldstate: {a0}, NewState: {a1}`)
	end)
end

local current = "Walk"
local function Swap()
	if current == "Walk" then
		current = "Chase"
	else
		current = "Walk"
	end
	print(`Swaped to: {current}`)
	return current
end


task.spawn(function()
	while true do
		NPCController:ForceAllStates(Swap())
		task.wait(2)
		NPCController:ForceAllStates(Swap())
		task.wait(5)
	end
end)

local function Len(T)
	local Count = 0
	for _, __ in T do
		Count += 1
	end
	return Count
end

Target:GetPropertyChangedSignal("BrickColor"):Connect(function() 
	if Target.BrickColor == BrickColor.Green() then
		local Con = Ecosystem:GetSpeciesFromBindedInstance(script.Parent.Parent.Parent.TestObjects["ME"] :: Instance) :: Ecosystem.Species

	print(`Controller for {Con.AttachedEcosystemID} With ID {Con.SpeciesID} running current state {Con.CurrentState} With object {Con.ObjectBinded}\n\n NOW STOPPING`)
	
	--Con:Stop()

	Con:Destroy()

	print(Con, getmetatable(Con))
	print(NPCController, getmetatable(NPCController))

	else
		NPCController:Destroy()
	end
end)



--[[local Con = Ecosystem:GetSpeciesFromBindedInstance(script.Parent.Parent.Parent.TestObjects["T"] :: Instance) :: Ecosystem.Species

print(`Controller for {Con.AttachedEcosystemID} With ID {Con.SpeciesID} running current state {Con.CurrentState} With object {Con.ObjectBinded}\n\n NOW STOPPING`)

task.wait(1)

Con:Stop()

Con:Destroy(true)

print(Con, getmetatable(Con))
]]