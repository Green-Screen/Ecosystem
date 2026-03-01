-- Ecosystem V 3.0
-- @Patriots8800

--!strict

----------------------------------------------------------------------------------------------

-- 							[[ Dependencies ]]

local EasyType = require("@self/Dependencies/EasyType")
local SmartTable = require("@self/Dependencies/SmartTable")

----------------------------------------------------------------------------------------------

-- 							[[ Types ]]

export type Ecosystem = {
	read EcosystemID: string,
	read States: { [string]: () -> () },
	read InternalProperties: { [string]: any? },
	--read FunctionEnvVars: { [string]: any? },

	read AddStateAndFeature: (
		self: Ecosystem,
		State: string,
		Feature: (CurrentSpecies: Species, StateFrom: string) -> string
	) -> (),
	read AddCustomProperty: (self: Ecosystem, PropertyIndex: string, InitialValue: any?) -> (),
	read SetFunctionEnviorment: (self: Ecosystem, PropertyIndex: string, InitialValue: any) -> (),

	read Prime: (self: Ecosystem) -> (),
	read IsPrimed: (self: Ecosystem) -> boolean,
}

export type Species = {}

type InternalEcosystem = setmetatable<
	{
		write EcosystemID: string,
		write States: { [string]: () -> () },
		write InternalProperties: { [string]: any? },
	},
	{
		read __index: InternalEcosystem,
		read ClassName: string,

		write FunctionEnvVars: { [string]: any? },
		write Frozen: boolean,

		write AddStateAndFeature: (
			self: Ecosystem,
			State: string,
			Feature: (CurrentSpecies: Species, StateFrom: string) -> string
		) -> (),
		write AddCustomProperty: (self: InternalEcosystem, PropertyIndex: string, InitialValue: any?) -> (),
		write SetFunctionEnviorment: (self: InternalEcosystem, PropertyIndex: string, InitialValue: any) -> (),

		write Prime: (self: InternalEcosystem) -> (),
		write IsPrimed: (self: InternalEcosystem) -> boolean,
	}
>

type InternalSpecies = {
	read __index: InternalSpecies,
	read ClassName: string,
} & Species

----------------------------------------------------------------------------------------------

-- 							[[ Service Header ]]

-- A FSM built for mass AI control
local SERVICE_NAME = "[Ecosystem]:"

----------------------------------------------------------------------------------------------

-- 							[[ Private functions (helpers) ]]

local EcosystemCache = {}

----------------------------------------------------------------------------------------------
--					 		[[ Species MetaData (MetaTable) ]]

local SpeciesMetaData = {}
SpeciesMetaData.__index = SpeciesMetaData
SpeciesMetaData.ClassName = "Species"

----------------------------------------------------------------------------------------------

--					 		[[ Ecosystem MetaData (MetaTable) ]]

local EcosystemMetaData = {}
EcosystemMetaData.__index = EcosystemMetaData
EcosystemMetaData.ClassName = "Ecosystem"

EcosystemMetaData.FunctionEnvVars = {} -- global
EcosystemMetaData.Frozen = false -- Cannot be undone

function EcosystemMetaData:AddStateAndFeature(State: string, Feature: () -> string)
	assert(EasyType(State) == "string", string.format("%s %s's State must be a string", SERVICE_NAME, self.EcosystemID))
	assert(
		EasyType(Feature) == "function",
		string.format("%s %s's Feature must be a function", SERVICE_NAME, self.EcosystemID)
	)
	assert(not self.Frozen, string.format("%s %s is primed and read only", SERVICE_NAME, self.EcosystemID))

	self.States[State] = Feature
end

function EcosystemMetaData:AddCustomProperty(PropertyIndex: string, InitialValue: any?)
	assert(
		EasyType(PropertyIndex) == "string",
		string.format("%s %s's PropertyIndex must be a string", SERVICE_NAME, self.EcosystemID)
	)
	assert(not self.Frozen, string.format("%s %s is primed and read only", SERVICE_NAME, self.EcosystemID))

	self.InternalProperties[PropertyIndex] = InitialValue
end

function EcosystemMetaData:SetFunctionEnviorment(PropertyIndex: string, InitialValue: any)
	assert(
		EasyType(PropertyIndex) == "string",
		string.format("%s %s's PropertyIndex must be a string", SERVICE_NAME, self.EcosystemID)
	)
	assert(
		InitialValue ~= nil,
		string.format("%s %s's InitialValue cannot be initalized as nil", SERVICE_NAME, self.EcosystemID)
	)
	assert(not self.Frozen, string.format("%s %s is primed and read only", SERVICE_NAME, self.EcosystemID))

	self.FunctionEnvVars[PropertyIndex] = InitialValue
end

-- Turns the ecosystem into read only and cannot assign any new properties, enviorment varibles and states/functions
function EcosystemMetaData:Prime()
	assert(
		not self.Frozen,
		string.format("%s attempt to freeze Ecosystem %s that is already frozen", SERVICE_NAME, self.EcosystemID)
	)
	--WriteToClonedMT(self, "Frozen", true)
	getmetatable(self :: InternalEcosystem)["Frozen"] = true
end

function EcosystemMetaData:IsPrimed()
	return self.Frozen
end

----------------------------------------------------------------------------------------------
--					 		[[ Public service (constructor) ]]

local Ecosystem = {}

function Ecosystem.NewEcosystem(Identifyer: string): Ecosystem
	assert(
		not EcosystemCache[Identifyer],
		string.format("%s Attempt to register '%s' Id is already taken", SERVICE_NAME, Identifyer)
	)

	local self = {}

	self.EcosystemID = Identifyer

	self.States = {} -- function storage
	self.InternalProperties = {} -- local

	local T = table.clone(EcosystemMetaData)
	T.__index = T
	setmetatable(self, T)

	EcosystemCache[Identifyer] = self
	return self :: Ecosystem
end

return Ecosystem

----------------------------------------------------------------------------------------------
