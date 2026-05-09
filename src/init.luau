-- Ecosystem V 2.4.0
-- @Patriots8800

--!strict

----------------------------------------------------------------------------------------------

-- 							[[ Dependencies ]]

local EasyType = require("./Ecosystem/Dependencies/EasyType")
local SecureClasses = require("./Ecosystem/Dependencies/SecureClasses")
local SmartTable = require("./Ecosystem/Dependencies/SmartTable")
local TramService = require("./Ecosystem/Dependencies/TramService")
----------------------------------------------------------------------------------------------
-- 							[[ Types ]]

type FunctionState = (CurrentSpecies: Species, StateFrom: string?) -> string

type IEcosystem = {
	__index: IEcosystem,

	EcosystemID: string,
	_States: { [string]: FunctionState },
	_InternalProperties: { [string]: any? },

	_SpeciesBinded: { [string]: ISpecies },
	_FunctionEnvVars: { [string]: any? },
	Frozen: boolean,
	ClassName: string,

	-- EnvVar NewData, OldData
	EnviormentUpdate: TramService.Tram<string, any, any>,

	AddStateAndFeature: (
		self: IEcosystem,
		State: string,
		Feature: (CurrentSpecies: ISpecies, StateFrom: string) -> string
	) -> (),
	AddCustomProperty: (self: IEcosystem, PropertyIndex: string, InitialValue: any?) -> (),
	SetFunctionEnviorment: (self: IEcosystem, PropertyIndex: string, InitialValue: any) -> (),

	Freeze: (self: IEcosystem) -> (),

	UpdateFunctionEnviorment: (self: IEcosystem, EnvVar: string, Data: any?) -> (),

	ForceAllStates: (self: IEcosystem, StateID: string) -> (),
}

type ISpecies = {
	__index: ISpecies,

	AttachedEcosystemID: string,
	SpeciesID: string,

	_States: { [string]: FunctionState },
	_InternalProperties: { [string]: any },
	_FunctionEnvVars: { [string]: any },

	_HandlingThread: thread,
	CurrentState: string,

	ObjectBinded: Instance?,

	-- StateFrom, StateTo
	StateChanged: TramService.Tram<string, string>,

	--self.EnvUpdate = TramService.NewTram(nil,nil,nil,true)
	--self.StateChanged = TramService.NewTram(nil,nil,nil,true)

	ClassName: string,

	Start: (self: ISpecies, StateID: string) -> (),
	Stop: (self: ISpecies) -> (),
	ForceState: (self: ISpecies, StateID: string) -> (),

	GetEnviorment: ((self: ISpecies, EnvVar: nil) -> { [string]: any }) & ((self: ISpecies, EnvVar: string) -> any),
	SetProperty: (self: ISpecies, Property: string, Value: any) -> (),
	GetProperty: (self: ISpecies, Property: string) -> any,
}

export type Ecosystem = SecureClasses.WrappedMetatable<{
	-- [[Properties]]

	ClassName: string,

	EcosystemID: string,
	Frozen: boolean,

	-- [[Signals]]

	-- EnvVar NewData, OldData
	EnviormentUpdate: TramService.Tram<string, any, any>,

	-- [[Methods]]

	AddStateAndFeature: (self: Ecosystem, State: string, Feature: FunctionState) -> (),
	AddCustomProperty: (self: Ecosystem, PropertyIndex: string, InitialValue: any?) -> (),
	SetFunctionEnviorment: (self: Ecosystem, PropertyIndex: string, InitialValue: any) -> (),

	Freeze: (self: Ecosystem) -> (),

	UpdateFunctionEnviorment: (self: Ecosystem, EnvVar: string, Data: any) -> (),

	ForceAllStates: (self: Ecosystem, StateID: string) -> (),
}>

export type Species = SecureClasses.WrappedMetatable<{
	-- [[Properties]]

	ClassName: string,

	AttachedEcosystemID: string,
	SpeciesID: string,
	CurrentState: string,
	ObjectBinded: Instance?,

	-- [[Signals]]

	-- StateFrom, StateTo
	StateChanged: TramService.Tram<string?, string>,

	--self.EnvUpdate = TramService.NewTram(nil,nil,nil,true)
	--self.StateChanged = TramService.NewTram(nil,nil,nil,true)

	-- [[Methods]]

	Start: (self: Species, StateID: string) -> (),
	Stop: (self: Species) -> (),
	ForceState: (self: Species, StateID: string) -> (),

	GetEnviorment: ((self: Species, EnvVar: nil) -> { [string]: any }) & ((self: Species, EnvVar: string) -> any),
	SetProperty: (self: Species, Property: string, Value: any) -> (),
	GetProperty: (self: Species, Property: string) -> any,
}>

----------------------------------------------------------------------------------------------

-- 							[[ Service Header ]]

-- A FSM built for mass AI and instance control
local SERVICE_NAME = "[Ecosystem]:"

----------------------------------------------------------------------------------------------

-- 							[[ Private functions (helpers) ]]

local EcosystemMetatableKey = `Ecosystem_MT_Key:{SmartTable.Helper.GenerateUUID()}`
local SpeciesMetatableKey = `Species_MT_Key:{SmartTable.Helper.GenerateUUID()}`

local EcosystemCache: { [string]: IEcosystem } = {}

-- Returns if the thread is not running
local function IsThreadRunning(T: thread)
	if EasyType(T) == "thread" then
		return coroutine.status(T) ~= "dead"
	end
	return false
end

-- Function to allow nil assigning without deleting a tables index firing __newindex
local function ParseKeywords(V: any): any?
	if V == "nil" then
		return nil
	elseif V == nil then
		return "nil"
	elseif V == "false" then
		return false
	elseif V == false then
		return "false"
	else
		return V
	end
end
----------------------------------------------------------------------------------------------
--					 		[[ Species MetaData (MetaTable) ]]

local SpeciesMetaData = {}
SpeciesMetaData.ClassName = "Species"
SpeciesMetaData.__typeKey = SpeciesMetatableKey
SpeciesMetaData.__destroy = function(self: ISpecies, Nuke: boolean)
	-- Finish implementing __destroy for both classes
	self.StateChanged:DestroyLocal()
	self.StateChanged = nil :: never

	(EcosystemCache[self.AttachedEcosystemID] :: any)[EcosystemMetatableKey]._SpeciesBinded[self.SpeciesID] = nil
end

-- Starts the state loop
function SpeciesMetaData:Start(StateID: string)
	local SpMT: ISpecies = self[SpeciesMetatableKey]

	local StartingFunction = SpMT._States[StateID]
	assert(StartingFunction, string.format("%s attempt to get unknown state %s", SERVICE_NAME, StateID))
	assert(
		not IsThreadRunning(SpMT._HandlingThread),
		string.format(
			"%s attempt to start already running Species ID %s under ecosystem %s",
			SERVICE_NAME,
			SpMT.SpeciesID,
			SpMT.AttachedEcosystemID
		)
	)

	SpMT.CurrentState = StateID
	local OldState: string? = nil

	SpMT._HandlingThread = task.spawn(function()
		while true do
			local NextState: string = StartingFunction(self, OldState)
			if NextState == "Stop" then
				self:Stop()
			end

			OldState = SpMT.CurrentState

			SpMT.CurrentState = NextState
			StartingFunction = SpMT._States[NextState]
			-- Broadcast update
			SpMT.StateChanged:Fire(OldState :: string, NextState)
		end
	end)
end

-- Stops the state loop
function SpeciesMetaData:Stop()
	local SpMT: ISpecies = self[SpeciesMetatableKey]

	assert(
		IsThreadRunning(SpMT._HandlingThread),
		string.format("%s Attempt to stop Species that is not running with ID: %s", SERVICE_NAME, SpMT.SpeciesID)
	)
	if SpMT._HandlingThread == coroutine.running() then
		-- Deletes the reference allowing the thread to be garbage collected while yielding
		SpMT._HandlingThread = "Null" :: never
		return coroutine.yield()
	else
		task.cancel(SpMT._HandlingThread)
		SpMT._HandlingThread = "Null" :: never
	end
end

-- Forces the state loop to stop and restart on the new state
function SpeciesMetaData:ForceState(StateID: string)
	local SpMT: ISpecies = self[SpeciesMetatableKey]

	assert(SpMT._States[StateID], string.format("%s attempt to get unknown state %s", SERVICE_NAME, StateID))

	if IsThreadRunning(SpMT._HandlingThread) then
		local CurrentState = SpMT.CurrentState;
		(self :: ISpecies):Stop();
		(self :: ISpecies):Start(StateID)
		SpMT.StateChanged:Fire(CurrentState, StateID)
	else
		(self :: ISpecies):Start(StateID)
	end
end

-- Gets the enviorment or a specific variable
function SpeciesMetaData:GetEnviorment(EnvVar: string?): any
	local SpMT: ISpecies = self[SpeciesMetatableKey]

	if EnvVar then
		assert(
			SpMT._FunctionEnvVars[EnvVar],
			string.format(
				"%s Attempt to index Enviorment variable %s: Enviorment is not declared",
				SERVICE_NAME,
				EnvVar
			)
		)
		return ParseKeywords(SpMT._FunctionEnvVars[EnvVar])
	else
		return SpMT._FunctionEnvVars
	end
end

-- Sets a private property of the species
function SpeciesMetaData:SetProperty(Property: string, Value: any)
	local SpMT: ISpecies = self[SpeciesMetatableKey]

	assert(
		SpMT._InternalProperties[Property],
		string.format("%s Attempt to Assign nil property doesnt exist Species ID: %s", SERVICE_NAME, SpMT.SpeciesID)
	)

	SpMT._InternalProperties[Property] = ParseKeywords(Value)
end

-- Gets the Private property table or the specific property
function SpeciesMetaData:GetProperty(Property: string): any
	local SpMT: ISpecies = self[SpeciesMetatableKey]

	assert(
		SpMT._InternalProperties[Property],
		string.format("%s Attempt to Assign nil property doesnt exist Species ID: %s", SERVICE_NAME, SpMT.SpeciesID)
	)
	return ParseKeywords(SpMT._InternalProperties[Property])
end

----------------------------------------------------------------------------------------------

--					 		[[ Ecosystem MetaData (MetaTable) ]]

local EcosystemMetaData = {}
EcosystemMetaData.ClassName = "Ecosystem"
EcosystemMetaData.__typeKey = EcosystemMetatableKey
EcosystemMetaData.__destroy = function(self: IEcosystem, Nuke: boolean)
	-- Finish implementing __destroy for both classes

end

-- used to initialize a state and a function to bind it to
function EcosystemMetaData:AddStateAndFeature(State: string, Feature: FunctionState)
	local EcMT: IEcosystem = self[EcosystemMetatableKey]

	assert(EasyType(State) == "string", string.format("%s %s's State must be a string", SERVICE_NAME, EcMT.EcosystemID))
	assert(
		EasyType(Feature) == "function",
		string.format("%s %s's Feature must be a function", SERVICE_NAME, EcMT.EcosystemID)
	)
	assert(not EcMT.Frozen, string.format("%s %s is primed and read only", SERVICE_NAME, EcMT.EcosystemID))

	if State == "Stop" then
		error(string.format("%s Invalid State name: %s", SERVICE_NAME, State))
	end

	EcMT._States[State] = Feature
end

-- initializes a private property that will be cloned to the species
function EcosystemMetaData:AddCustomProperty(PropertyIndex: string, InitialValue: any?)
	local EcMT: IEcosystem = self[EcosystemMetatableKey]

	assert(
		EasyType(PropertyIndex) == "string",
		string.format("%s %s's PropertyIndex must be a string", SERVICE_NAME, EcMT.EcosystemID)
	)
	assert(not EcMT.Frozen, string.format("%s %s is primed and read only", SERVICE_NAME, EcMT.EcosystemID))

	EcMT._InternalProperties[PropertyIndex] = ParseKeywords(InitialValue)
end

-- initialize an enviorment variables that is global to the controller and its species
function EcosystemMetaData:SetFunctionEnviorment(PropertyIndex: string, InitialValue: any?)
	local EcMT: IEcosystem = self[EcosystemMetatableKey]
	assert(
		EasyType(PropertyIndex) == "string",
		string.format("%s %s's PropertyIndex must be a string", SERVICE_NAME, EcMT.EcosystemID)
	)
	assert(not EcMT.Frozen, string.format("%s %s is primed and read only", SERVICE_NAME, EcMT.EcosystemID))

	EcMT._FunctionEnvVars[PropertyIndex] = ParseKeywords(InitialValue)
end

-- Turns the ecosystem into read only and cannot assign any new properties, enviorment variables and states/functions
function EcosystemMetaData:Freeze()
	local EcMT: IEcosystem = self[EcosystemMetatableKey]

	assert(
		not EcMT.Frozen,
		string.format("%s attempt to freeze Ecosystem %s that is already frozen", SERVICE_NAME, EcMT.EcosystemID)
	)

	EcMT.Frozen = true
end

-- Updates a enviorment variable during runtime
function EcosystemMetaData:UpdateFunctionEnviorment(EnvVar: string, Data: any?)
	local EcMT: IEcosystem = self[EcosystemMetatableKey]

	assert(
		EcMT._FunctionEnvVars[EnvVar],
		string.format("%s Attempt to index Enviorment variable %s: Enviorment is not declared", SERVICE_NAME, EnvVar)
	)
	assert(self.Frozen, string.format("%s Ecosystem must be primed to update environment variables", SERVICE_NAME))

	local OldData = EcMT._FunctionEnvVars[EnvVar]
	EcMT._FunctionEnvVars[EnvVar] = Data or "nil"
	--self.__EnvUpdate:Fire(EnviormentUpdateKey, Data, if OldData == "nil" then nil else OldData)

	EcMT.EnviormentUpdate:Fire(EnvVar, Data, ParseKeywords(OldData))
end

-- Gets the enviorment or a specific variable
function EcosystemMetaData:GetEnviorment(EnvVar: string?)
	local EcMT: IEcosystem = self[EcosystemMetatableKey]

	if EnvVar then
		assert(
			EcMT._FunctionEnvVars[EnvVar],
			string.format(
				"%s Attempt to index Enviorment variable %s: Enviorment is not declared",
				SERVICE_NAME,
				EnvVar
			)
		)

		return ParseKeywords(EcMT._FunctionEnvVars[EnvVar])
	else
		return EcMT._FunctionEnvVars
	end
end

-- Forces all species connected to the controller to all piviot to a new state
function EcosystemMetaData:ForceAllStates(StateID: string)
	local EcMT: IEcosystem = self[EcosystemMetatableKey]

	assert(EcMT._States[StateID], string.format("%s attempt to get unknown state %s", SERVICE_NAME, StateID))

	for ID: string, Specie: ISpecies in EcMT._SpeciesBinded do
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

	self._States = {} -- function storage
	self._InternalProperties = {} -- local

	self._SpeciesBinded = {}
	self._FunctionEnvVars = {} -- global
	self.Frozen = false -- Cannot be undone

	self.EnviormentUpdate = TramService.NewTram(nil, nil, nil, true)

	--setmetatable(self, EcosystemMetaData)

	local E = SecureClasses(self :: Ecosystem, EcosystemMetaData :: Ecosystem, EcosystemMetaData.ClassName) :: Ecosystem

	EcosystemCache[Identifyer] = E :: IEcosystem

	return E
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

	local EcMT: IEcosystem = (EcosystemCache[Identifyer] :: any)[EcosystemMetatableKey]

	assert(
		EcMT.Frozen,
		string.format(
			"%s Attempt to generate species from Ecosystem %s where [Primed] is False",
			SERVICE_NAME,
			Identifyer
		)
	)

	local self = {}

	self.AttachedEcosystemID = Identifyer
	self.SpeciesID = SmartTable.Helper.GenerateUUID()

	self._States = EcMT._States
	self._InternalProperties = table.clone(EcMT._InternalProperties)

	self.CurrentState = "none"
	self.ObjectBinded = ObjectToBind

	self._FunctionEnvVars = EcMT._FunctionEnvVars

	self.StateChanged = TramService.NewTram(nil, nil, nil, true)

	self._HandlingThread = "Null"

	--setmetatable(self, SpeciesMetaData)

	local S = SecureClasses(self :: Species, SpeciesMetaData :: Species, SpeciesMetaData.ClassName) :: Species

	EcMT._SpeciesBinded[self.SpeciesID] = S :: ISpecies

	return S
end

----------------------------------------------------------------------------------------------

-- Passing the controller makes the search O(n) without its O(n^2)
function Ecosystem:GetSpeciesFromBindedInstance(I: Instance, Controller: Ecosystem?): Species?
	if Controller then
		local EcMT: IEcosystem = Controller[EcosystemMetatableKey]
		-- O(n)
		for ID: string, Specie: ISpecies in EcMT._SpeciesBinded do
			if I == Specie.ObjectBinded then
				return Specie :: Species
			end
		end
	else
		-- O(n^2)
		for _, Ecosystem: IEcosystem in EcosystemCache do
			for __, Specie: ISpecies in
				(Ecosystem :: any)[EcosystemMetatableKey]._SpeciesBinded :: { [string]: ISpecies }
			do
				if I == Specie.ObjectBinded then
					return Specie :: Species
				end
			end
		end
	end
	return nil
end

function Ecosystem:GetEcosystemFromSpecie(S: Species): Ecosystem?
	assert(EasyType(S) == "Species", "Expected Species")
	local Ecosystem = EcosystemCache[S.AttachedEcosystemID] :: Ecosystem
	return Ecosystem
end

return Ecosystem

----------------------------------------------------------------------------------------------
