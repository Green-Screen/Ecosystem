-- Ecosystem V 2.0
-- @Patriots8800

--!strict

----------------------------------------------------------------------------------------------

-- 							[[ Dependencies ]]

local EasyType = require("@self/Dependencies/EasyType")
local SmartTable = require("@self/Dependencies/SmartTable")
local TramService = require("@self/Dependencies/TramService")
----------------------------------------------------------------------------------------------

-- 							[[ Types ]]

type FunctionState = (CurrentSpecies: Species, StateFrom: string) -> string

export type Ecosystem = {
	read EcosystemID: string,
	read States: { [string]: FunctionState },
	read InternalProperties: { [string]: any? },
	read Frozen: boolean,
	--read FunctionEnvVars: { [string]: any? },

	read AddStateAndFeature: (self: Ecosystem, State: string, Feature: FunctionState) -> (),
	read AddCustomProperty: (self: Ecosystem, PropertyIndex: string, InitialValue: any?) -> (),
	read SetFunctionEnviorment: (self: Ecosystem, PropertyIndex: string, InitialValue: any) -> (),

	read Freeze: (self: Ecosystem) -> (),

	read UpdateEnvVar: (self: Ecosystem, EnvVar: string, Data: any?) -> (),
	read GetEnviorment: ((self: Ecosystem, EnvVar: nil) -> { [string]: any })
		& ((self: Ecosystem, EnvVar: string) -> any),
	read ForceAllStates: (self: Ecosystem, StateID: string) -> (),

	-- EnvVar NewData, OldData
	read EnvUpdate: TramService.ModuleEvent<string, any, any>,
}

export type Species = {
	read AttachedEcosystemID: string,
	read SpeciesID: string,
	read States: { [string]: FunctionState },
	read InternalProperties: { [string]: any? },
	read HandelingThread: thread,
	read CurrentState: string,
	read ObjectBinded: Instance,

	read Start: (self: Species, StateID: string) -> (),
	read Stop: (self: Species) -> (),

	read ForceState: (self: Species, StateID: string) -> (),

	read GetEnviorment: ((self: Species, EnvVar: nil) -> { [string]: any }) & ((self: IS, EnvVar: string) -> any),
	read SetProperty: (self: Species, Property: string, Value: any) -> (),
	read GetProperty: (self: Species, Property: string) -> any,

	-- StateFrom, StateTo
	read StateChanged: TramService.ModuleEvent<string, string>,
}

type IE = setmetatable<
	{
		EcosystemID: string,
		States: { [string]: FunctionState },
		InternalProperties: { [string]: any? },

		SpeciesBinded: { [string]: InternalSpecies },
		FunctionEnvVars: { [string]: any? },
		Frozen: boolean,
	},
	{
		__index: IE,
		ClassName: string,

		AddStateAndFeature: (
			self: Ecosystem,
			State: string,
			Feature: (CurrentSpecies: Species, StateFrom: string) -> string
		) -> (),
		AddCustomProperty: (self: IE, PropertyIndex: string, InitialValue: any?) -> (),
		SetFunctionEnviorment: (self: IE, PropertyIndex: string, InitialValue: any) -> (),

		Freeze: (self: IE) -> (),

		UpdateEnvVar: (self: IE, EnvVar: string, Data: any?) -> (),

		ForceAllStates: (self: IE, StateID: string) -> (),
	}
>

type IS = setmetatable<
	{
		AttachedEcosystemID: string,
		SpeciesID: string,

		States: { [string]: FunctionState },
		InternalProperties: { [string]: any? },
		FunctionEnvVars: { [string]: any? },

		HandelingThread: thread,
		CurrentState: string,

		ObjectBinded: Instance?,

		-- EnvVar NewData, OldData
		EnvUpdate: TramService.Tram<string, any, any>,

		-- StateFrom, StateTo
		StateChanged: TramService.Tram<string, string>,

		--self.EnvUpdate = TramService.NewTram(nil,nil,nil,true)
		--self.StateChanged = TramService.NewTram(nil,nil,nil,true)
	},
	{
		__index: IS,
		ClassName: string,

		Start: (self: IS, StateID: string) -> (),
		Stop: (self: IS) -> (),
		ForceState: (self: IS, StateID: string) -> (),

		GetEnviorment: ((self: IS, EnvVar: nil) -> { [string]: any }) & ((self: IS, EnvVar: string) -> any),
		SetProperty: (self: IS, Property: string, Value: any) -> (),
		GetProperty: (self: IS, Property: string) -> any,
	}
>

type InternalEcosystem = IE & getmetatable<IE>
type InternalSpecies = IS & getmetatable<IS>

----------------------------------------------------------------------------------------------

-- 							[[ Service Header ]]

-- A FSM built for mass AI and instance control
local SERVICE_NAME = "[Ecosystem]:"

----------------------------------------------------------------------------------------------

-- 							[[ Private functions (helpers) ]]

local EcosystemCache: { [string]: InternalEcosystem & getmetatable<InternalEcosystem> } = {}

-- Returns if the thread is not running
local function IsThreadRunning(T: thread)
	if T then
		return coroutine.status(T) ~= "dead"
	end
	return false
end
----------------------------------------------------------------------------------------------
--					 		[[ Species MetaData (MetaTable) ]]

local SpeciesMetaData = {}
SpeciesMetaData.__index = SpeciesMetaData
SpeciesMetaData.ClassName = "Species"

-- Stats the state loop
function SpeciesMetaData:Start(StateID: string)
	local StartingFunction = self.States[StateID]
	assert(self.States[StateID], string.format("%s attempt to get unknown state %s", SERVICE_NAME, StateID))
	assert(
		not IsThreadRunning(self.HandelingThread),
		string.format(
			"%s attempt to start already running Species ID %s under ecosystem %s",
			SERVICE_NAME,
			self.SpeciesID,
			self.AttachedEcosystemID
		)
	)

	self.CurrentState = StateID
	self.HandelingThread = task.spawn(function()
		while true do
			local OldState = self.CurrentState
			local NextState: string = StartingFunction(self :: Species, OldState)

			self.CurrentState = NextState

			StartingFunction = self.States[NextState]
			-- Broadcast update
			self.StateChanged:Fire(OldState, NextState)
		end
	end)
end

-- Stops the state loop
function SpeciesMetaData:Stop()
	assert(
		self.HandelingThread,
		string.format("%s Attempt to stop Species that is not running with ID: %s", SERVICE_NAME, self.SpeciesID)
	)
	task.cancel(self.HandelingThread)
end

-- Forces the state loop to stop and restart on the new state
function SpeciesMetaData:ForceState(StateID: string)
	assert(self.States[StateID], string.format("%s attempt to get unknown state %s", SERVICE_NAME, StateID))

	if IsThreadRunning(self.HandelingThread) then
		local CurrentState = self.CurrentState
		self:Stop()
		self:Start(StateID)
		self.StateChanged:Fire(CurrentState, StateID)
	else
		self:Start(StateID)
	end
end

-- Gets the enviorment or a specific variable
function SpeciesMetaData:GetEnviorment(EnvVar: string?)
	if EnvVar then
		assert(
			self.FunctionEnvVars[EnvVar],
			string.format(
				"%s Attempt to index Enviorment variable %s: Enviorment is not declared",
				SERVICE_NAME,
				EnvVar
			)
		)
		return if self.FunctionEnvVars[EnvVar] == "nil" then nil else self.FunctionEnvVars[EnvVar]
	else
		return self.FunctionEnvVars
	end
end

-- Sets a private property of the species
function SpeciesMetaData:SetProperty(Property: string, Value: any)
	assert(
		self.InternalProperties[Property],
		string.format("%s Attempt to Assign nil property doesnt exist Species ID: %s", SERVICE_NAME, self.SpeciesID)
	)

	self.InternalProperties[Property] = Value or "nil"
end

-- Gets the Private property table or the specific property
function SpeciesMetaData:GetProperty(Property: string): any
	assert(
		self.InternalProperties[Property],
		string.format("%s Attempt to Assign nil property doesnt exist Species ID: %s", SERVICE_NAME, self.SpeciesID)
	)
	return self.InternalProperties[Property]
end

----------------------------------------------------------------------------------------------

--					 		[[ Ecosystem MetaData (MetaTable) ]]

local EcosystemMetaData = {}
EcosystemMetaData.__index = EcosystemMetaData
EcosystemMetaData.ClassName = "Ecosystem"

-- used to initialize a state and a function to bind it to
function EcosystemMetaData:AddStateAndFeature(State: string, Feature: () -> string)
	assert(EasyType(State) == "string", string.format("%s %s's State must be a string", SERVICE_NAME, self.EcosystemID))
	assert(
		EasyType(Feature) == "function",
		string.format("%s %s's Feature must be a function", SERVICE_NAME, self.EcosystemID)
	)
	assert(not self.Frozen, string.format("%s %s is primed and read only", SERVICE_NAME, self.EcosystemID))

	self.States[State] = Feature
end

-- initializes a private property that will be cloned to the species
function EcosystemMetaData:AddCustomProperty(PropertyIndex: string, InitialValue: any?)
	assert(
		EasyType(PropertyIndex) == "string",
		string.format("%s %s's PropertyIndex must be a string", SERVICE_NAME, self.EcosystemID)
	)
	assert(not self.Frozen, string.format("%s %s is primed and read only", SERVICE_NAME, self.EcosystemID))

	self.InternalProperties[PropertyIndex] = InitialValue or "init"
end

-- initialize an enviorment variables that is global to the controller and its species
function EcosystemMetaData:SetFunctionEnviorment(PropertyIndex: string, InitialValue: any?)
	assert(
		EasyType(PropertyIndex) == "string",
		string.format("%s %s's PropertyIndex must be a string", SERVICE_NAME, self.EcosystemID)
	)
	--[[assert(
		InitialValue ~= nil,
		string.format("%s %s's InitialValue cannot be initalized as nil", SERVICE_NAME, self.EcosystemID)
	)]]
	assert(not self.Frozen, string.format("%s %s is primed and read only", SERVICE_NAME, self.EcosystemID))

	self.FunctionEnvVars[PropertyIndex] = InitialValue or "init"
end

-- Turns the ecosystem into read only and cannot assign any new properties, enviorment variables and states/functions
function EcosystemMetaData:Freeze()
	assert(
		not self.Frozen,
		string.format("%s attempt to freeze Ecosystem %s that is already frozen", SERVICE_NAME, self.EcosystemID)
	)
	--WriteToClonedMT(self, "Frozen", true)
	self.Frozen = true
end

-- Updates a enviorment variable during runtime
function EcosystemMetaData:UpdateEnvVar(EnvVar: string, Data: any?)
	assert(
		(self :: InternalEcosystem).FunctionEnvVars[EnvVar],
		string.format("%s Attempt to index Enviorment variable %s: Enviorment is not declared", SERVICE_NAME, EnvVar)
	)
	assert(self.Frozen, string.format("%s Ecosystem must be primed to update environment variables", SERVICE_NAME))

	local OldData = self.FunctionEnvVars[EnvVar]
	self.FunctionEnvVars[EnvVar] = Data or "nil"
	--self.__EnvUpdate:Fire(EnviormentUpdateKey, Data, if OldData == "nil" then nil else OldData)

	self.EnvUpdate:Fire(EnvVar, Data, if OldData == "nil" then nil else OldData)
end

-- Gets the enviorment or a specific variable
function EcosystemMetaData:GetEnviorment(EnvVar: string?)
	if EnvVar then
		assert(
			self.FunctionEnvVars[EnvVar],
			string.format(
				"%s Attempt to index Enviorment variable %s: Enviorment is not declared",
				SERVICE_NAME,
				EnvVar
			)
		)
		return if self.FunctionEnvVars[EnvVar] == "nil" then nil else self.FunctionEnvVars[EnvVar]
	else
		return self.FunctionEnvVars
	end
end

-- Forces all species connected to the controller to all piviot to a new state
function EcosystemMetaData:ForceAllStates(StateID: string)
	assert(self.States[StateID], string.format("%s attempt to get unknown state %s", SERVICE_NAME, StateID))

	for ID: string, Specie: InternalSpecies in (self :: InternalEcosystem).SpeciesBinded do
		Specie:ForceState(StateID)
	end
end

----------------------------------------------------------------------------------------------
--					 		[[ Public service (constructor) ]]

local Ecosystem = {}

-- Constructs a Ecosystem. (Controller class)
function Ecosystem.NewEcosystem(Identifyer: string): Ecosystem
	assert(
		not EcosystemCache[Identifyer],
		string.format("%s Attempt to register '%s' Id is already taken", SERVICE_NAME, Identifyer)
	)
	assert(
		EasyType(Identifyer) == "string",
		string.format("%s Identifyer must be a string got %s", SERVICE_NAME, Identifyer)
	)

	local self = {}

	self.EcosystemID = Identifyer

	self.States = {} -- function storage
	self.InternalProperties = {} -- local

	self.SpeciesBinded = {}
	self.FunctionEnvVars = {} -- global
	self.Frozen = false -- Cannot be undone

	self.EnvUpdate = TramService.NewTram(nil, nil, nil, true)

	setmetatable(self, EcosystemMetaData)

	EcosystemCache[Identifyer] = self :: any
	return self :: Ecosystem
end

-- Constructs a Specie. (A runtime class)
function Ecosystem.NewSpecies(Identifyer: string, ObjectToBind: Instance?)
	assert(
		EcosystemCache[Identifyer],
		string.format("%s Attempt to get Ecosystem %s: got nil", SERVICE_NAME, Identifyer)
	)
	assert(
		EasyType(Identifyer) == "string",
		string.format("%s Identifyer must be a string got %s", SERVICE_NAME, Identifyer)
	)

	local Parent: InternalEcosystem = EcosystemCache[Identifyer]

	assert(
		Parent.Frozen,
		string.format(
			"%s Attempt to generate species from Ecosystem %s where [Primed] is False",
			SERVICE_NAME,
			Identifyer
		)
	)

	local self = {}

	self.AttachedEcosystemID = Identifyer
	self.SpeciesID = SmartTable.Helper.GenerateUUID()

	self.States = Parent.States
	self.InternalProperties = table.clone(Parent.InternalProperties)

	self.CurrentState = "none"
	self.ObjectBinded = ObjectToBind

	self.FunctionEnvVars = Parent.FunctionEnvVars

	self.StateChanged = TramService.NewTram(nil, nil, nil, true)

	setmetatable(self, SpeciesMetaData)

	Parent.SpeciesBinded[self.SpeciesID] = self :: any
	return self :: Species
end

return Ecosystem

----------------------------------------------------------------------------------------------
