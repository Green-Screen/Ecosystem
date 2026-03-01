local Trams = require(script.TramService)
local ST = require(script.SmartTable)

export type Species = {
	HandleingThread: thread,
	StateType: string,
	StateUUID: string, 
	CurrentState: string,
	ObjectToBind: Instance?,
	States: {[string]:()->()},
	CustomProperties: {[string]:any},

	StateChanged: Trams.ModuleEvent, -- Params (Identifyer, Newstate, UUID of state)

	Simulate:(StateID:string) -> (),
	EndSimulation: () -> (),
	UpdateCustomProperty : (self:Species, PropertyName:string, NewValue:any?) -> (),
	GetCustomProperty : (self:Species, PropertyName:string) -> any?,
}

export type EcosystemController = {
	StateType: string,
	States: {[string]:()->()},
	CustomProperties: {[string]:any},

	AddFeature: (self:EcosystemController, State:string, FeatureOptions: "CoreLoop", Feature:(StateObject:State, StateBefore:string) -> string ) -> (),
	AddStates: (self:EcosystemController, ...string) -> (),
	AddCustomProperties: (self:EcosystemController, ...string) -> (),
}

local HelperTree = ST.Helper

-- StateUUID is index
local CoreThreadCache:{[string]:thread} = {}

local MainStates:{[string]:EcosystemController} = {}
local SubStates:{[string]:Species} = {}

local State = {}
State.__index = State
State.ClassName = "State"

function State:Simulate(StateID:string)
	local NewStateFunction = self.States[StateID]
	assert(self.HandleingThread == "Dorment", "[StateManager]: ".. self.StateUUID .. " Simulation already running must be dorment to start")
	
	assert(NewStateFunction, "[StateManager]: No "..StateID.." for"..self.StateType.. " UUID:"..self.StateUUID)
	assert(NewStateFunction.CoreLoop, "[StateManager]: No Loop function binded for "..self.StateType.. " UUID:"..self.StateUUID)
	
	self.HandleingThread = task.defer(function()
		while true do
			local NextState:string = NewStateFunction.CoreLoop(self, self.CurrentState)
			NewStateFunction = self.States[NextState]

			assert(NewStateFunction, "[StateManager]: No "..NextState.." for"..self.StateType.. " UUID:"..self.StateUUID)
			assert(NewStateFunction.CoreLoop, "[StateManager]: No Loop function binded for "..self.StateType.. " UUID:"..self.StateUUID)
		end
	end)
	
end

function State:EndSimulation()
	assert(self.HandleingThread ~= "Dorment", "[StateManager]: Simulation already dorment")
	coroutine.close(self.HandleingThread)
	self.HandleingThread = "Dorment"
end

function State:UpdateCustomProperty(PropertyName:string, NewValue:any?)
	assert(self.CustomProperties[PropertyName], "[StateManager]: No "..PropertyName.." for ".. self.StateType.." UUID:"..self.StateUUID)
	self.CustomProperties[PropertyName] = NewValue
end

function State:GetCustomProperty(PropertyName:string)
	assert(self.CustomProperties[PropertyName], "[StateManager]: No "..PropertyName.." for ".. self.StateType.." UUID:"..self.StateUUID)
	return self.CustomProperties[PropertyName]
end



local StateController = {}

StateController.__index = StateController
StateController.ClassName = "StateController"

function StateController:AddFeature(State:string, FeatureOptions: "CoreLoop", Feature:() -> ())
	assert(self.States[State], "[StateManager]: No "..State.." for ".. self.StateType)
	--assert(self.States[State][FeatureOptions], "[StateManager]: No "..FeatureOptions.." for ".. self.StateType.." UUID:"..self.StateUUID)
	assert(typeof(Feature), "[StateManager]: "..typeof(Feature).. " Passed Function needed for ".. self.StateType)

	self.States[State][FeatureOptions] = Feature
end

function StateController:AddStates(...:string)
	for _, Name in {...} do
		self.States[Name] = {
			CoreLoop = "nil",
		}
	end
end

function StateController:AddCustomProperties(...:string)
	for _, Name in {...} do
		self.CustomProperties[Name] = "nil"
	end
end

local StateManager = {}

function StateManager.NewStateController(Identifyer:string) : EcosystemController
	local self = setmetatable({}, StateController)
	
	self.StateType = Identifyer
	self.States = {}
	self.CustomProperties = {}
	
	MainStates[self.StateType] = self
	
	return self
end

function StateManager.NewState(Identifyer:string, ObjectToBind:Instance?) : Species
	local Controller:StateController = MainStates[Identifyer]
	
	local self:State = setmetatable({}, State)
	
	self.CustomProperties = Controller.CustomProperties
	self.States = Controller.States
	self.ObjectToBind = ObjectToBind
	self.StateType = Controller.StateType
	self.StateUUID = HelperTree.GenerateUUID()
	self.CurrentState = "Non"
	self.HandleingThread = "Dorment"

	SubStates[self.StateUUID] = self

	self.StateChanged = Trams.NewTram()

	return self
end



return StateManager