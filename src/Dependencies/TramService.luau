-- Tram service V 2.2
-- @Patriots8800

--!strict

----------------------------------------------------------------------------------------------
-- 							[[ Dependencies ]]

local SmartTable = require("./SmartTable")

----------------------------------------------------------------------------------------------
-- 							[[ Types ]]

-- Main type

export type Tram<P...> = {
	read FunctionsBinded: { [string]: any },
	read YeildingThreads: { [string]: thread },
	read TraversableID: string | "NonTranversable",
	read Callback: boolean?,
	read Timeout: number,
	read BindID: string,
	read IsModuleEvent: boolean?,
	read Destroyed: boolean,

	read Connect: (self: Tram<P...>, (P...) -> ...any?) -> (),
	read Fire: (self: Tram<P...>, P...) -> (),
	read Wait: (self: Tram<P...>) -> P...,
	read Disconnect: (self: Tram<P...>) -> (),
	read DisconnectAll: (self: Tram<P...>) -> (),

	read DestroyLocal: (self: Tram<P...>) -> nil,
	read DestroyGlobal: (self: Tram<P...>) -> nil,
}

type InternalTram<P...> = {
	read __index: InternalTram<P...>,
	read ClassName: string,

	write FunctionsBinded: { [string]: any },
	write YeildingThreads: { [string]: thread },
	write TraversableID: string | "NonTranversable",
	write Callback: boolean?,
	write Timeout: number,
	write BindID: string,
	write IsModuleEvent: boolean?,
	write Destroyed: boolean,

	write Fire: (self: Tram<P...>, P...) -> (),
	write Wait: (self: Tram<P...>) -> P...,
	write Disconnect: (self: Tram<P...>) -> (),
	write Connect: (self: Tram<P...>, (P...) -> ...any?) -> (),
	write DisconnectAll: (self: Tram<P...>) -> (),

	write DestroyLocal: (self: Tram<P...>) -> nil,
	write DestroyGlobal: (self: Tram<P...>) -> nil,
} & Tram<any>

-- 					[[Specialized tram types]]

-- ALL tram types are a Tram type but the different types are for editing the auto complete for certain uses.
-- Ie. Modules using this as events, certain events, Only fire or only receive.

-- The only difference is for autocomplete/intellisense everything is a tram type

---------------------------------------

export type TramConnectOnly<P...> = {

	read Connect: (self: TramConnectOnly<P...>, (P...) -> ...any?) -> (),
	read Wait: (self: TramConnectOnly<P...>) -> P...,

	read DestroyLocal: (self: TramConnectOnly<P...>) -> nil,
	read DestroyGlobal: (self: TramConnectOnly<P...>) -> nil,
}

export type TramDisconnectOnly<P...> = {

	read Disconnect: (self: TramDisconnectOnly<P...>) -> (),
	read DisconnectAll: (self: TramDisconnectOnly<P...>) -> (),

	read DestroyLocal: (self: TramDisconnectOnly<P...>) -> nil,
	read DestroyGlobal: (self: TramDisconnectOnly<P...>) -> nil,
}

export type ModuleEvent<P...> = {

	read Connect: (self: ModuleEvent<P...>, (P...) -> ...any?) -> (),
	read Wait: (self: ModuleEvent<P...>) -> P...,

	read Disconnect: (self: ModuleEvent<P...>) -> (),
	read DisconnectAll: (self: ModuleEvent<P...>) -> (),

	read DestroyLocal: (self: ModuleEvent<P...>) -> nil,
	read DestroyGlobal: (self: ModuleEvent<P...>) -> nil,
}

export type OnlySignaling<P...> = {

	read Fire: (self: OnlySignaling<P...>, P...) -> (),

	read DestroyLocal: (self: OnlySignaling<P...>) -> nil,
	read DestroyGlobal: (self: OnlySignaling<P...>) -> nil,
}

----------------------------------------------------------------------------------------------

-- 							[[ Service ]]

local SERVICE_NAME = "[TramService]:"

----------------------------------------------------------------------------------------------

-- 							[[ Private functions (helpers) ]]

-- 							[[ Thread caching ]]

local ThreadCache: { thread } = {}

-- Runs the yielded function then resets it
local function Run(FN, Thread, ...)
	FN(...)

	table.insert(ThreadCache, Thread)
	Run(coroutine.yield())
end

-- Creates a thread then yields it and allows you to "inject a function into it"
local function PrimeThread(): thread
	local function Prime()
		return Run(coroutine.yield())
	end

	return task.spawn(Prime)
end

-- Runs the function pased on the cashed thread
local function RunCachedThread(FN: () -> (), ...)
	local Thread: thread

	if ThreadCache[1] then
		Thread = ThreadCache[math.min(1, #ThreadCache)]
		ThreadCache[#ThreadCache] = nil
	else
		Thread = PrimeThread()
	end

	if coroutine.status(Thread) ~= "suspended" then
		warn(string.format("%s, Junk thread found removing from cache", SERVICE_NAME))
		return RunCachedThread(FN)
	end

	task.spawn(Thread, FN, Thread, ...)
end

-- Adds a timeout to remote function
local function Timeout(Time: number, FN, ...): (boolean, ...any)
	local Returned, Return, RunThread
	local Start = os.clock()

	Time = math.clamp(Time, 0, 20)
	RunThread = task.spawn(function(...)
		Return = FN(...)
		Returned = true
	end, ...)

	repeat
		task.wait()
	until Returned or os.clock() - Start > Time

	task.cancel(RunThread)

	if not Returned then
		warn("Function callback time exhausted limit of " .. Time .. " seconds.")
	end
	return not Returned, Return
end

----------------------------------------------------------------------------------------------
--					 		[[ Cache manager ]

local TramCache: { [string?]: InternalTram<any> } = {}

local function PublishUpdate(Tram: InternalTram<any>)
	if Tram.TraversableID ~= "NonTraversable" then
		TramCache[Tram.TraversableID] = table.clone(Tram)
	end
end

local function GetUpdate(Tram: InternalTram<any>)
	if Tram.TraversableID == "NonTraversable" then
		return Tram
	end
	local Cache = TramCache[Tram.TraversableID]
	if not Cache then
		return Tram :: any
	end
	if Tram.Destroyed or Cache.Destroyed then
		warn(
			string.format(
				"%s Attempt to interact with %s Bind ID: %s\nThis object has been destroyed and locked",
				SERVICE_NAME,
				(Tram.TraversableID or Cache.TraversableID or "NO TRACEBACK"),
				(Tram.BindID or Cache.BindID or "NO TRACEBACK")
			)
		)
		return nil :: never
	end

	Tram.Timeout = Cache.Timeout
	Tram.FunctionsBinded = Cache.FunctionsBinded
	Tram.YeildingThreads = Cache.YeildingThreads
	Tram.Callback = Cache.Callback

	return Tram :: any
end

----------------------------------------------------------------------------------------------
--					 		[[ MetaData (MetaTable) ]]

local Tram = {}

Tram.ClassName = "Tram"
Tram.__index = Tram

-- Connect a function to the tram
function Tram:Connect(fn): ()
	assert(type(fn) == "function", string.format("%s Attempt to index %s with function", SERVICE_NAME, typeof(fn)))

	self = GetUpdate(self)
	if self == nil then
		return
	end

	if self.Callback then
		self.FunctionsBinded = fn
	else
		self.FunctionsBinded[self.BindID] = fn
	end

	PublishUpdate(self)
end

-- Handles the data sent in a optimized threaded capacity
function Tram:Fire(...): ()
	self = GetUpdate(self)
	if self == nil then
		return
	end
	--[[if not TraversableEvent then
		return error(
			string.format(
				"%s Attempt to get traversable  station for [%s] ID has no reciprocal",
				SERVICE_NAME,
				tostring(self.TraversableID)
			),
			100
		)
	end]]

	if self.Callback then
		if not self.FunctionsBinded and not self.IsModuleEvent then
			return warn(
				string.format("%s Attempt to fire [%s], No function binded", SERVICE_NAME, tostring(self.TraversableID))
			)
		end
		return Timeout(self.Timeout, self.FunctionsBinded :: any, ...) :: any
	else
		for ID, Thread in self.YeildingThreads do
			self.YeildingThreads[ID] = nil
			task.spawn(Thread, ...)
		end

		if not next(self.FunctionsBinded) and not self.IsModuleEvent then
			return warn(
				string.format("%s Attempt to fire [%s], No function binded", SERVICE_NAME, tostring(self.TraversableID))
			)
		end

		for _, Func in self.FunctionsBinded do
			RunCachedThread(Func, ...)
		end

		PublishUpdate(self)
	end
end

-- Yields the main thread until :Fire() is called and resumes it
function Tram:Wait(): ()
	self = GetUpdate(self)
	if self == nil then
		return
	end

	assert(
		not self.Callback,
		string.format("%s Attempt to yield callback function, cannot yield callbacks", SERVICE_NAME)
	)
	assert(
		self.YeildingThreads[self.BindID] == nil,
		string.format("%s Attempt to yield thread that is already yielding", SERVICE_NAME)
	)

	self.YeildingThreads[self.BindID] = coroutine.running()
	PublishUpdate(self)

	return coroutine.yield()
end

-- Disconnects a function from the tram
function Tram:Disconnect(): ()
	self = GetUpdate(self)
	if self == nil then
		return
	end

	if not self.IsModuleEvent then
		assert(
			not next(self.YeildingThreads),
			string.format("%s Attempt to disconnect tram while a station is yielding", SERVICE_NAME)
		)
	end

	if self.Callback then
		self.FunctionsBinded = nil :: any
	else
		self.FunctionsBinded[self.BindID] = nil
	end

	PublishUpdate(self)
end

-- Disconnects all function connected to the TraversableID
function Tram:DisconnectAll(): ()
	self = GetUpdate(self)
	if self == nil then
		return
	end

	if self.Callback then
		self.FunctionsBinded = nil :: any
	else
		table.clear(self.FunctionsBinded)
	end

	PublishUpdate(self)
end

-- Destroys the tram passed in self
function Tram:DestroyLocal(): nil
	self = GetUpdate(self)
	if self == nil then
		return nil
	end

	assert(
		not self.YeildingThreads[self.BindID],
		string.format(
			"%s Attempt to destroy %s with BindID: %s\nwhile tram is currently yielding",
			SERVICE_NAME,
			self.TraversableID,
			self.BindID
		)
	)

	self:Disconnect()
	self.Destroyed = true
	return nil
end

-- Disables all trams with the same TraversableID
function Tram:DestroyGlobal(): nil
	self = GetUpdate(self)
	if self == nil then
		return nil
	end

	if self.TraversableID == "NonTraversable" then
		return self:DestroyLocal()
	end

	for ID: string, thread: thread in self.YeildingThreads do
		error(
			string.format(
				"%s Attempt to destroy %s with BindID: %s\nwhile tram is currently yielding",
				SERVICE_NAME,
				self.TraversableID,
				self.BindID
			),
			100
		)
	end
	self:DisconnectAll()

	self.Destroyed = true
	PublishUpdate(self)
	return nil
end

----------------------------------------------------------------------------------------------
--					 		[[ Public service (constructor) ]]

local TramService = {}

-- TraversableID needed to make the event accessable outside of the main script container
function TramService.NewTram<P...>(
	TraversableID: string?,
	Function: boolean?, -- Params
	Timeout: number?,
	IsModuleEvent: boolean?
): Tram<P...>
	assert(
		not TraversableID or type(TraversableID) == "string",
		string.format("%s Attempt to index string or nil with %s", SERVICE_NAME, typeof(TraversableID))
	)
	local self = {}

	self.Callback = Function or false
	self.IsModuleEvent = IsModuleEvent
	self.TraversableID = TraversableID or "NonTraversable"
	self.FunctionsBinded = if Function then nil else {}
	self.Timeout = Timeout or 5
	self.YeildingThreads = {}
	self.BindID = SmartTable.Helper.GenerateUUID()
	self.Destroyed = false

	return setmetatable(self, Tram) :: any
end

-- Checks if a tram is already cached and retrives a copy of the current data
function TramService:GetCachedTram(TranversableID: string): Tram<any>?
	local CachedTram: InternalTram<any> = TramCache[TranversableID]
	if CachedTram and not CachedTram.Destroyed then
		return GetUpdate(CachedTram)
	end
	return nil
end

return TramService

----------------------------------------------------------------------------------------------

--[[

																	How to use.
	Tram service is a replacement for bindable events, they provide all the same functionallites + new performance upgrades
	
	To create a Tram require the module and call the "NewTram" function, If you want your Trams to be Tranversable between scripts
	Be sure to add a TranversableID as it is required for these, if no id is provided the event will be locked to the script the module
	was required in.
	
	Bindable Functions are supported with a built in timeout, A bindable event timeout will return a tupe (DidExpire:Boolean, Results:...Any?)
	The boolean with determin if the timeout was exhausted,  true if yes and false if no, and the rest is the returned product.
	Be Careful with calling wait in the same frame as this can cause it to be skipped and then miss being resumed making it forever yield
	
	
														Ill make a documentation soon ;D



			-- NewTram: {

				TraversableID : (string?) -> A id used to connect trams across scripts.
											Default is "NonTraversable"
											(Must be the same in order to communicate across scripts).
											Left nill will lock the event to the scope and memory container of the script.
											To share you must manually share the object. This is good for embeding into other modules also mixed with the specialized type annotations
			
				Function: (boolean?) -> Determins if the event should be treated as a bindable function

				Timeout: (number?) -> 	Sets the function timeout
										Default is 5 seconds
										Only applied if Function = True
				
				IsModuleEvent : (boolean?) -> Disables console logs (Asserts and errors will still be broadcasted)
											This is used if you dont want to be spammed with warning logs if the
											object is being used dynamically instead of statically always assigned.
											This ["WILL"] make it harder to debug if something isn't working.
			
			
				} -> Returns a tram object

]]
