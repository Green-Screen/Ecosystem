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

--[=[
	@class Ecosystem
	The main controller class, this object acts as the leader and template for all subclasse [Species]() and retains its control during runtime.
]=]

--[=[
	@within Ecosystem
	@external SecuredClass https://green-screen.github.io/SecureClasses/api/SecuredMetatable#WrappedMetatable
	@type Ecosystem SecuredClass <Ecosystem>
	The `Ecosystem` object is wrapped inside of the `SecuredClass` this provides protections such as proper read-only properties + more
]=]

--[=[
	@within Ecosystem
	@type FunctionState (CurrentSpecies: Species, StateFrom: string?) -> string

	:::caution Return
	A feature function **MUST** return a valid `StateID` string for the next state to run or **Stop** to stop close the current running thread
	:::
]=]

--[=[
	@within Ecosystem
	@prop EcosystemID string
	@readonly
	The identifier string that is passes in the `NewEcosystem` contstructor
]=]

--[=[
	@within Ecosystem
	@prop Frozen Boolean
	@readonly
	A boolean that represents if the Ecosystem template is done being constructed and is ready to have Specie subclasses created from it.
]=]

--[=[
	@within Ecosystem
	@prop ClassName string
	@readonly
	The class of the object `Ecosystem`
]=]

--[=[
	@within Ecosystem
	@prop _States { [string]: FunctionState }
	@readonly
	@private
	The `States` template container
]=]

--[=[
	@within Ecosystem
	@prop _InternalProperties { [string]: any? }
	@readonly
	@private
	The `Properties` template container __Local to the Species object__
]=]

--[=[
	@within Ecosystem
	@prop _FunctionEnvVars { [string]: any? }
	@readonly
	@private
	The `Enviorment` container __Global to the Ecosystem object__
]=]

--[=[
	@within Ecosystem
	@prop _SpeciesBinded { [string]: Species }
	@readonly
	@private
	A dictionary of all the species binded to the ecosystem __index is the speciesID__
]=]

--[=[
	@within Ecosystem
	@prop EnviormentUpdate Tram<EnviormentVariableIndex:string, NewData:any, OldData:any)>
	@readonly
	@tag Signal
	A `tram` signal class that fires whenever a enviorment __Global__ variable is changed in the order of `(EnviormentVariableIndex:string, NewData:any, OldData:any)`
]=]

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

--[=[
	@class Species
	The runtime class of Ecosystem. A specie clones properties from Ecosystem and runs them individually with the ability to share data among other species classes through the `Ecosystem` controller
]=]

--[=[
	@within Species
	@type Species SecuredClass <Species>
	The `Ecosystem` object is wrapped inside of the `SecuredClass` this provides protections such as proper read-only properties + more
]=]

--[=[
	@within Species
	@prop SpeciesID string
	@readonly
	The UUID that is assigned when the `Species` object is created 
]=]

--[=[
	@within Species
	@prop AttachedEcosystemID string
	@readonly
	The identifier string that is passes in the `NewSpecies` constructor that matches the `Ecosystem` that you want to bind it to.
]=]

--[=[
	@within Species
	@prop ClassName string
	@readonly
	The class of the object `Species`
]=]

--[=[
	@within Species
	@prop CurrentState string
	@readonly
	The current running state ID `nil` if non is running
]=]

--[=[
	@within Species
	@prop ObjectBinded Instance?
	@readonly
	A optional paramater that allows you to link a instance to the species object
]=]

--[=[
	@within Species
	@prop _States { [string]: FunctionState }
	@readonly
	@private
	The `States` container that points to the `_States` dictionary of the Ecosystem controller
]=]

--[=[
	@within Species
	@prop _InternalProperties { [string]: any? }
	@readonly
	@private
	The `Properties` container that points to the `_InternalProperties` dictionary of the Ecosystem controller __Local to the Species object__
]=]

--[=[
	@within Species
	@prop _FunctionEnvVars { [string]: any? }
	@readonly
	@private
	The `Enviorment` container that points to the `_FunctionEnvVars` dictionary of the Ecosystem controller __Global to the Ecosystem object__
]=]

--[=[
	@within Species
	@prop _HandlingThread thread
	@readonly
	@private
	The thread that runs the different states stored in `_States`
]=]

--[=[
	@within Species
	@prop StateChanged Tram<StateFrom:string, StateTo:string)>
	@readonly
	@tag Signal
	A `tram` signal class that fires whenever a State is changed in the order of `(StateFrom:string, StateTo:string)`
]=]

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

-- Destroy function of the species class
SpeciesMetaData.__destroy = function(self: ISpecies, Nuke: boolean, EcosystemDestroy:boolean?)
	-- Removes the tram object
	self.StateChanged:DestroyLocal()

	-- Deletes pointer
	self.StateChanged = nil :: never

	-- Allows the gc to collect the pointer BUT NOT clear the memory
	self._FunctionEnvVars = nil :: never
	self._States = nil :: never
	self._InternalProperties = nil :: never

	-- Removes species from ecosystem [Binded] cache
	if EcosystemDestroy then
		EcosystemCache[self.AttachedEcosystemID]._SpeciesBinded[self.SpeciesID] = nil
	else
		((EcosystemCache[self.AttachedEcosystemID] :: any)[EcosystemMetatableKey] :: IEcosystem)._SpeciesBinded[self.SpeciesID] = nil
	end

end

--[=[
	@within Species
	@method Start

	@param StateID string -- must be a valid State that was assigned in the ecosystem template

	Starts the FSM runtime for the species called on passing the first StateID as the initial state to run.

	### Example:
	```lua
	local NPCController = Ecosystem.NewEcosystem("JumpingNPC")

	NPCController:AddStateAndFeature("Jump10Times", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
		local Count = 0
		local CurrentObjectHumanoid:Humanoid = CurrentSpecies.ObjectBinded.Humanoid

		while task.wait(0.1) do
			if not CurrentObjectHumanoid.Jump then
				CurrentObjectHumanoid.Jump = true
				Count += 1
			end
			if Count >= 10 then
				return "NextState" -- The next StateID that should run
			end
		end
	end)

	-- Freezes the controller making it read-only
	NPCController:Freeze()

	-- Creates a Species Class from the Ecosystem template
	local JumpingNPC = Ecosystem.NewSpecies("JumpingNPC", NPCInstance)

	-- Begins cycle
	JumpingNPC:Start("Jump10Times")

	```
]=]


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

--[=[
	@within Species
	@method Stop

	Stops the current Species runtime instantly by closing the thread

	### Example:
	```lua
	local NPCController = Ecosystem.NewEcosystem("JumpingNPC")
	local HasJumped10Times = false

	NPCController:AddStateAndFeature("Jump10Times", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
		local Count = 0
		local CurrentObjectHumanoid:Humanoid = CurrentSpecies.ObjectBinded.Humanoid

		while task.wait(0.1) do
			if not CurrentObjectHumanoid.Jump then
				CurrentObjectHumanoid.Jump = true
				Count += 1
			end
			if Count >= 10 then
				HasJumped10Times = true
			end
		end
	end)

	-- Freezes the controller making it read-only
	NPCController:Freeze()

	-- Creates a Species Class from the Ecosystem template
	local JumpingNPC = Ecosystem.NewSpecies("JumpingNPC", NPCInstance)

	-- Begins cycle
	JumpingNPC:Start("Jump10Times")

	while task.wait() do
		if HasJumped10Times then
			-- Stops the running species instantly
			JumpingNPC:Stop()
			break
		end
	end

	```

	## Or alternatively:

	```lua
	local NPCController = Ecosystem.NewEcosystem("JumpingNPC")

	NPCController:AddStateAndFeature("Jump10Times", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
		local Count = 0
		local CurrentObjectHumanoid:Humanoid = CurrentSpecies.ObjectBinded.Humanoid

		while task.wait(0.1) do
			if not CurrentObjectHumanoid.Jump then
				CurrentObjectHumanoid.Jump = true
				Count += 1
			end
			if Count >= 10 then
				-- Returning "Stop" will cause the running thread to yield and gc
				-- This method DOES NOT guarantee instant results as it is 
				-- dependent on the current cycle of the GC
				return "Stop"
			end
		end
	end)

	-- Freezes the controller making it read-only
	NPCController:Freeze()

	-- Creates a Species Class from the Ecosystem template
	local JumpingNPC = Ecosystem.NewSpecies("JumpingNPC", NPCInstance)

	-- Begins cycle
	JumpingNPC:Start("Jump10Times")

	```
]=]

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

--[=[
	@within Species
	@method ForceState

	@param StateID string -- must be a valid State that was assigned in the ecosystem template

	Forcefully changes the current running state even if a state is mid execution

	### Example:
	```lua
	local NPCController = Ecosystem.NewEcosystem("JumpingNPC")

	NPCController:AddStateAndFeature("Jump10Times", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
		-- implmentation the same as above
	end)

	NPCController:AddStateAndFeature("Wander", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
		-- implemtation is user definded
		-- Ex:
		-- Makes a NPC wander randomly in a 100x100 box around a fixed point
	end)

	-- Freezes the controller making it read-only
	NPCController:Freeze()

	-- Creates a Species Class from the Ecosystem template
	local JumpingNPC = Ecosystem.NewSpecies("JumpingNPC", NPCInstance)

	-- Begins cycle
	JumpingNPC:Start("Jump10Times")

	task.wait(2)

	-- Forces the wander state
	JumpingNPC:ForceState("Wander")
	```
	## Equal to:
	```lua
	local JumpingNPC = Ecosystem.NewSpecies("JumpingNPC", NPCInstance)

	JumpingNPC:Start("Jump10Times")

	task.wait(2)

	JumpingNPC:ForceState("Wander")

	-- Or Simplily

	JumpingNPC:Start("Jump10Times")

	task.wait(2)

	-- Stops the current state
	JumpingNPC:Stop()
	
	-- CAUTION: Adding a wait my be necessary due to task scheduler priorities
	JumpingNPC:Start("Wander")
	```
]=]

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

--[=[
	@within Species
	@method GetEnviorment

	@param EnvVar string -- The index of the enviorment variable

	@return any

	Returns the value of a enviorment variable with the given index
	
	### Example:
	```lua
	local NPCController = Ecosystem.NewEcosystem("JumpingNPC")
	NPCController:SetFunctionEnviorment("GlobalVariable", 10) -- Initial value of 10

	NPCController:AddStateAndFeature("Jump10Times", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
		print(CurrentSpecies:GetEnviorment("GlobalVariable")) -- 10
		print(CurrentSpecies:GetEnviorment("GlobalVariable2")) -- nil
		print(CurrentSpecies:GetEnviorment()) -- The dictionary of enviorment properties

		return "NextState" -- Next state
	end)

	```

	:::info Read-Only
	The `Species` object is **NOT** able to write to `EnviormentVariables` only read.
	:::
]=]

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

--[=[
	@within Species
	@method SetProperty

	@param Property string -- The index of the local property value
	@param Value any -- the value to be assigned

	Returns the value of a enviorment variable with the given index
	
	### Example:
	```lua
	local NPCController = Ecosystem.NewEcosystem("JumpingNPC")
	NPCController:SetFunctionEnviorment("GlobalVariable", 10) -- Initial value of 10

	NPCController:AddStateAndFeature("Jump10Times", function(CurrentSpecies: Ecosystem.Species, StateFrom: string): string
		print(CurrentSpecies:GetEnviorment("GlobalVariable")) -- 10
		print(CurrentSpecies:GetEnviorment("GlobalVariable2")) -- nil
		print(CurrentSpecies:GetEnviorment()) -- The dictionary of enviorment properties

		return "NextState" -- Next state
	end)

	```

	:::info Read-Only
	The `Species` object is **NOT** able to write to `EnviormentVariables` only read.
	:::
]=]

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
	-- Removes the tram
	self.EnviormentUpdate:DestroyLocal()

	-- Removes the cahced as they are complex objects
	for ID:string, Specie:ISpecies in self._SpeciesBinded do
		(Specie :: any):Destroy(Nuke, true)
	end

	-- Removes reference to help SmartClean
	self.EnviormentUpdate = nil :: never
	self._SpeciesBinded = nil :: never

	-- Removes cache reference
	EcosystemCache[self.EcosystemID] = nil
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

function EcosystemMetaData:GetCache()
	return self[EcosystemMetatableKey]._SpeciesBinded
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
	-- Clones so it doesnt write to the template table
	self._InternalProperties = table.clone(EcMT._InternalProperties)

	self.CurrentState = "none"
	self.ObjectBinded = ObjectToBind

	-- Does not clone allowing the table to be global among all species
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

-- Gets Ecosystem (controller class) from the species object
function Ecosystem:GetEcosystemFromSpecie(S: Species): Ecosystem?
	assert(EasyType(S) == "Species", "Expected Species")
	local Ecosystem = EcosystemCache[S.AttachedEcosystemID] :: Ecosystem
	return Ecosystem
end

return Ecosystem

----------------------------------------------------------------------------------------------
