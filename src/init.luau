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

	read UpdateEnvVar: (self: Ecosystem, EnvVar: string, Data: any?) -> (),
	read GetEnviorment: ((self: Ecosystem, EnvVar: nil) -> { [string]: any })
		& ((self: Ecosystem, EnvVar: string) -> any),
}

export type Species = {}

type IE = setmetatable<
	{
		EcosystemID: string,
		States: { [string]: () -> () },
		InternalProperties: { [string]: any? },
	},
	{
		__index: IE,
		ClassName: string,

		FunctionEnvVars: { [string]: any? },
		Frozen: boolean,
		__EnvUpdate: TramService.ModuleEvent<"Enviorment" | "Signal", string, string?>,

		AddStateAndFeature: (
			self: Ecosystem,
			State: string,
			Feature: (CurrentSpecies: Species, StateFrom: string) -> string
		) -> (),
		AddCustomProperty: (self: IE, PropertyIndex: string, InitialValue: any?) -> (),
		SetFunctionEnviorment: (self: IE, PropertyIndex: string, InitialValue: any) -> (),

		Prime: (self: IE) -> (),
		IsPrimed: (self: IE) -> boolean,

		UpdateEnvVar: (self: IE, EnvVar: string, Data: any?) -> (),
	}
>

type IS =
	setmetatable<{}, {
		__index: IS,
		ClassName: string,
	}>
	& Species

type InternalEcosystem = IE & getmetatable<IE>
type InternalSpecies = IS & getmetatable<IS>

----------------------------------------------------------------------------------------------

-- 							[[ Service Header ]]

-- A FSM built for mass AI control
local SERVICE_NAME = "[Ecosystem]:"

----------------------------------------------------------------------------------------------

-- 							[[ Private functions (helpers) ]]

local EcosystemCache: { [string]: InternalEcosystem & getmetatable<InternalEcosystem> } = {}
local EnviormentUpdateKey = "Enviorment"
local BroadcastUpdateKey = "Signal"

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

	self.FunctionEnvVars[PropertyIndex] = InitialValue or "Init"
end

-- Turns the ecosystem into read only and cannot assign any new properties, enviorment varibles and states/functions
function EcosystemMetaData:Prime()
	assert(
		not self.Frozen,
		string.format("%s attempt to freeze Ecosystem %s that is already frozen", SERVICE_NAME, self.EcosystemID)
	)
	--WriteToClonedMT(self, "Frozen", true)
	getmetatable(self :: InternalEcosystem)["Frozen"] = true

	EcosystemCache[self.EcosystemID] = self
end

function EcosystemMetaData:IsPrimed()
	return self.Frozen
end

function EcosystemMetaData:UpdateEnvVar(EnvVar: string, Data: any?)
	assert(
		self.FunctionEnvVars[EnvVar],
		string.format("%s Attempt to index Enviorment variable %s: Enviorment is not declared", SERVICE_NAME, EnvVar)
	)
	assert(self:IsPrimed(), string.format("%s Ecosystem must be primed to update environment variables", SERVICE_NAME))
	local OldData = self.FunctionEnvVars[EnvVar]
	self.FunctionEnvVars[EnvVar] = Data or "nil"
	self.__EnvUpdate:Fire(EnviormentUpdateKey, Data, if OldData == "nil" then nil else OldData)
end

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
		return self.FunctionEnvVars[EnvVar]
	else
		return self.FunctionEnvVars
	end
end

----------------------------------------------------------------------------------------------
--					 		[[ Public service (constructor) ]]

local Ecosystem = {}

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

	local T = table.clone(EcosystemMetaData)
	T.__EnvUpdate = TramService.NewTram(`__EnvUpdate_{Identifyer}`, nil, nil, true)
	T.__index = T
	setmetatable(self, T)

	EcosystemCache[Identifyer] = self :: any
	return self :: Ecosystem
end

function Ecosystem.NewSpecies(Identifyer: string)
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
end

return Ecosystem

----------------------------------------------------------------------------------------------
