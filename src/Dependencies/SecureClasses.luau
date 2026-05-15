-- SecureClasses V 2.1.3
-- @Patriots8800

--!strict

-- Documentation: https://green-screen.github.io/SecureClasses

----------------------------------------------------------------------------------------------

-- 							[[ Dependencies ]]
local EasyType = require("./EasyType")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------------------

-- 							[[ Service Header ]]P

-- Secure Classes is a Metatable and Userdata wrapper object ment to bring security and ease of use to all objects
local SERVICE_NAME = "[SecureClasses]:"

-- Enable debug mode only available in studio. This will allow you to print your classes to easily debug them.
local EnableDebugClasses = false

----------------------------------------------------------------------------------------------

-- 							[[ Private functions (helpers) ]]

local UnderscoreASCII = string.byte("_") -- = 95

local DebugEnabled = EnableDebugClasses and RunService:IsStudio()

local MetamethodStatuses = {
	["__index"] = false, -- Not writtable
	["__newindex"] = false, -- Not writtable
	["__call"] = true,
	["__concat"] = true,
	["__unm"] = true,
	["__iter"] = true,
	["__add"] = true,
	["__sub"] = true,
	["__mul"] = true,
	["__div"] = true,
	["__idiv"] = true,
	["__mod"] = true,
	["__pow"] = true,
	["__tostring"] = true, -- Has a default but is writtable
	["__len"] = true,
	["__eq"] = true,
	["__lt"] = true,
	["__le"] = true,
	["__mode"] = true,
	["__metatable"] = false, -- Not writtable
	["__destroy"] = true, -- Custom
	["__typeKey"] = true, -- Custom
}

local function GetLeadingUnderscores(str: string): number
	if EasyType(str) ~= "string" then
		return 0
	end
	local Counter = 0
	for _, v: number in ipairs({ str:byte(1, 4) }) do
		if v == UnderscoreASCII then
			Counter += 1
		else
			break
		end
	end
	return Counter
end

local function SortIntoCorrectTable<T, MT, MM>(T: T & MT & MM): (T, MT, MM)
	local Table: { [any]: any }, Metatable: { [any]: any }, Metamethods = {}, {}, {}
	for K, V in T :: { [any]: any } do
		local UnderscoreCT = GetLeadingUnderscores(K)

		-- Private variable
		-- Cannot be read or written to
		if UnderscoreCT == 1 then
			Metatable[K] = V
			continue
		end
		-- Forced public variable
		-- Can be read or written too through normal indexing
		if UnderscoreCT == 3 then
			Table[K] = V
			continue
		end
		-- Metamethod variable
		-- Must be a valid metamethod
		if UnderscoreCT == 2 then
			if not MetamethodStatuses[K] then
				error(string.format("%s Metamethod [ %s ] is forbidden or undefined", SERVICE_NAME, K :: string))
			else
				Metamethods[K] = V
			end
		end
		-- Default Variable
		if UnderscoreCT == 0 or UnderscoreCT > 2 then
			Metatable[K] = V
		end
	end
	return Table, Metatable, Metamethods
end

-- Auto clean table of basic roblox instances and objects.
-- To properly clean complex custom objects assign __destroy a function to be called at the beginning of the destroy cycle.

local function SmartClose(self: { [any]: any }, Nuke: boolean)
	--warn(self)
	for i, v in self do
		local vType = EasyType(v)
		local iType = EasyType(i)

		if vType == "RBXScriptConnection" then
			(v :: RBXScriptConnection):Disconnect()
		elseif vType == "thread" then
			task.cancel(v :: thread)
		elseif vType == "table" then
			SmartClose(v, Nuke)
		elseif vType == "Instance" and Nuke then
			(v :: Instance):Destroy()
		end

		if iType == "table" then
			SmartClose(i, Nuke)
		elseif iType == "thread" then
			task.cancel(i :: thread)
		elseif iType == "RBXScriptConnection" then
			(i :: RBXScriptConnection):Disconnect()
		elseif iType == "Instance" and Nuke then
			(i :: Instance):Destroy()
		end

		self[i] = nil
	end

	if EasyType(getmetatable(self) == "table") then
		setmetatable(self, nil)
	end

	return nil
end

local function ConcatTables(T1: { any }, T2: { any }, DestroyT2:boolean?)
	for k, v in T2 do
		T1[k] = v
		if DestroyT2 then
			T2[k] = nil
		end
	end
	return T1
end

----------------------------------------------------------------------------------------------
--					 		[[ MetaData (MetaTable) ]]

-- Assigns the metamethods to the metatable
-- __index, __newindex, and __metatable are protected and cannot be written to or read
-- __tostring has a default value of 'Flag' but IS allowed to be changed and written to,

-- Flag is the string this will be printed when you try to call GetMetatable() or print with the default __tostring method.

local function CreateSecureClass<T, MT, MM>(T: T, MT: MT, MM: MetaMethods<T & MT>, Flag: string)
	-- The base class is stored inside of SecureMetamethods
	--ConcatTables(SecureMetamethods, MM::any)

	-- True if the class has not been destroyed yet.
	-- Once destroyed trying to index will return nil
	(MT::any).Operatable = true

	MT = setmetatable(MT, {
		__newindex = function()
			return error(string.format("%s Metadata table cannot be assigned new keys", SERVICE_NAME), 10)
		end,
	})

	local function NestedClose(...)
		setmetatable(MT, nil)

		if (MM :: any).__destroy then
			(MM :: any).__newindex = nil
			-- Allows table to be written to
			ConcatTables(T, MT :: any, true);
			-- Moves Metatable into Table "__metadata"
			(MM.__destroy :: any)(...)
			-- Runs user assigned destroy on T & MT "__metadata"
		end
		SmartClose(MM :: any, true)
		-- Recursivly clears MM & T

		return SmartClose(...) :: any
		-- Clears T recursivly
	end

	(MM :: any)["__index"] = function(self: { [any]: any }, index: any)
		local uCT = GetLeadingUnderscores(index)
		if uCT == 1 then
			return warn(string.format("%s %s is a private property", SERVICE_NAME, index)) :: any
		elseif index == "Destroy" then
			return NestedClose
		elseif index == MM.__typeKey then
			return MT
		end

		return (MT :: any)[index]
	end

	(MM :: any)["__newindex"] = function(self: { [any]: any }, index: any, Value: any)
		return error(string.format("%s Secured table is read only", SERVICE_NAME), 10)
	end

	if not MM.__tostring then
		MM["__tostring"] = function()
			return Flag
		end
	end

	(MM :: any)["__metatable"] = Flag

	if not MM.__typeKey then
		MM["__typeKey"] = Flag
	end

	-- Creates protected metadata holder

	(MM :: any)["__metadata"] = MT

	if DebugEnabled then
		(MM :: any).__metatable = nil
		MM.__tostring = nil
	end

	return setmetatable(T, MM)
end

----------------------------------------------------------------------------------------------

-- 							[[ Types ]]

export type MetaMethods<T> = {
	--                             [Complex functions]
	--__index: ((self:T, index:(keyof<T> | any)) -> () | {[any]:any} )?, -- self[keyof<T>] Indexes the table attached (Not the actual Metatable)
	--__newindex: ((self:T, index:any, value:any) -> () | {[any]:any})?, -- self[keyof<T>] = V Adds new value (locked for read only)
	__call: ((self: T, ...any) -> any)?, -- self() function call
	__concat: (<V>(self: T, value: V) -> T & V)?, -- self..value Concatenation (combine)
	__unm: ((self: T) -> T)?, -- -self Unary  (inverse)
	__iter: typeof(next)?, -- Generalized iteration for K, V in self do --task-- end (Type of next as default)

	--                             [Calculations]

	__add: ((self: T, value: number) -> number)?, -- self+value Addition (Adds a number)
	__sub: ((self: T, value: number) -> number)?, -- self-value Subtraction (Subtracts a number)
	__mul: ((self: T, value: number) -> number)?, -- self*value Multiplication (Multiples a number)
	__div: ((self: T, value: number) -> number)?, -- self/value Division (Divides a number)
	__idiv: ((self: T, value: number) -> number)?, -- self//value Floor division (Floor divides a number)
	__mod: ((self: T, value: number) -> number)?, -- self%value Modulus (Modulo's by a number)
	__pow: ((self: T, value: number) -> number)?, -- self^value Exponentiation (Exponentiates a number)
	__tostring: ((self: T) -> string)?, -- tostring(self) -> printable string ()
	__len: ((self: T) -> number)?, -- #self Array length (length)

	--                          [Comparisons]

	-- Comparisons must be compared with the same basic type and if 1 calls __eq then the other must also call __eq (table, userdata are NOT compareable)
	__eq: ((self: T, value: any) -> boolean)?, -- self==value Equality operator (compares a value to be equal)

	-- Note <, > and <=, >= will both be triggered by their respective metamethods (no __gt or ge metamethod as it is redundent)
	__lt: ((self: T, value: any) -> boolean)?, -- self<value Less than operator (compares a value to be less than)
	__le: ((self: T, value: any) -> boolean)?, -- self<=value Less than or equal operator (compares a value to be less than or equal)

	--                          [constants]
	__mode: ("K" | "V" | "KV")?, -- Sets the garbage collection rule of the table
	--__metatable:string -- Locks metatable (Not editable)

	--                          [Custom]
	__destroy: ((self: T, OptionalBooleanArgument: boolean?) -> ())?, -- custom function to be assigned when 'Destroy is called'
	__typeKey: string?, -- The index needed to access the metatable,
	--__privateRead: ((self:T, index:any) -> ())?, -- custom function that is ran when you try and index `__typeKey` -- Runs when __index is called on `__typeKey`
	--__privateWrite: ((self:T, index:any, value:any?) -> ())?, -- custom function that is ran when you try and write to the metatable attached to `__typeKey` -- Runs when __newindex is called on `__typeKey`
}

export type WrappedMetatable<T> = T & {
	Destroy: (self: WrappedMetatable<T>, Nuke: boolean?) -> nil,
	Operatable: true | nil, 
}

-- Shits just broken
type function RemovePrivate(T: type)
	for i: type, v: { read: type?, write: type? } in T:properties() do
		local index = i:value()
		print("Removed", index)

		local Counter = 0
		for _, vv: number in ipairs({ (index :: string):byte(1, 4) }) do
			if vv == 95 then
				Counter += 1
			else
				break
			end
		end

		if Counter < 3 then
			print("Removed", index)
			T:setproperty(i, nil)
		end
	end
	return T
end

----------------------------------------------------------------------------------------------

--					 		[[ Public service (constructor) ]]

-- T is the Table
-- MT is the metatable
-- Metatables are not allowed to have metamethods included when being created from NewMetatable or NewUserdata

return function<T, MT, MM>(T: T, MT: MT, Flag: string, MM: MetaMethods<T & MT>?): WrappedMetatable<T>
	assert(EasyType(Flag) == "string", string.format("%s Flag must be a string got %s", SERVICE_NAME, Flag))
	local Transfer = T
	ConcatTables(Transfer, MT :: any or {})
	ConcatTables(Transfer, MM :: any or {})
	local Table: T, Metatable: MT, Metamethods: MM = SortIntoCorrectTable(Transfer)

	return CreateSecureClass(Table, Metatable, Metamethods, Flag) :: any
end

----------------------------------------------------------------------------------------------

--					 		                                    [[ Notes: ]]
--[[
            Due to the beta and testing nature of the luau type solver sometimes type intellisense will not be available due
            to the complex type casting and packing that happens throughout this class.
    

--]]

----------------------------------------------------------------------------------------------

--					 		                                    [[ Documentation: ]]

