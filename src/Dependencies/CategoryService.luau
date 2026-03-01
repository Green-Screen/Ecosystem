-- Category Service V 2.5
-- @Patriots8800

--!strict

----------------------------------------------------------------------------------------------

--					 		[[ Dependencies ]]

local EasyType = require("./EasyType")
local TramService = require("./TramService")

----------------------------------------------------------------------------------------------

--					 		[[ Types ]]

-- Supported types wont autofill in roblox studio for wtv reason, use vsc and lsp to get correct intellisense
-- This list should match the 'AllowedTypes' table
type SupportedTypes = "thread" | "RBXScriptConnection" | "Instance" | "Tween" | "Category" | "Tram"

export type Category = {
	--Public category type
	read TasksOnThread: { [string]: { [number]: any } },
	read ThreadLock: thread,

	read Insert: (self: Category, ...any) -> (),
	read GetSubCategoryContents: (self: Category, SubCategory: SupportedTypes) -> { any? },
	read Clean: (self: Category, ...SupportedTypes) -> (),
	read CleanAll: (self: Category) -> (),
	read FreeCurrentThread: (self: Category) -> nil,

	--									The subcategory that got inserted into
	read Insertion: TramService.ModuleEvent<string>,
}

type InternalCategory = {
	read __index: InternalCategory,
	read ClassName: string,

	--Internal category type
	write TasksOnThread: { [string]: { [number]: any } },
	write ThreadLock: thread,

	write Insert: (self: Category, ...any) -> (),
	write GetSubCategoryContents: (self: Category, SubCategory: SupportedTypes) -> { any? },
	write Clean: (self: Category, ...SupportedTypes) -> (),
	write CleanAll: (self: Category) -> (),
	write FreeCurrentThread: (self: Category) -> nil,

	write Insertion: TramService.Tram<string>,
} & Category

----------------------------------------------------------------------------------------------

--					 		[[ Service Header ]]
-- A thread based memory manger similar to Collection service

local SERVICE_NAME = "[CategoryService]:"

----------------------------------------------------------------------------------------------

--					 		[[ Private functions (helpers) ]]

local ActiveThreadCategories: { [thread]: InternalCategory} = {}

-- A constant
-- Add custom objects here
local AllowedObjects = {
	["RBXScriptConnection"] = {
		["MethodOrCall"] = "Method",
		["FunctionName"] = "Disconnect",
	},
	["thread"] = {
		["MethodOrCall"] = "Call",
		["FunctionName"] = "cancel",
		["Library"] = task,
	},
	["Instance"] = {
		["MethodOrCall"] = "Method",
		["FunctionName"] = "Destroy",
	},
	["Tween"] = {
		["MethodOrCall"] = "Method",
		["FunctionName"] = "Cancel",
	},

	["Category"] = {
		["MethodOrCall"] = "Method",
		["FunctionName"] = "Destroy",
	},
	["Tram"] = {
		["MethodOrCall"] = "Method",
		["FunctionName"] = "DestroyLocal",
	},
}

-- function to verify
local function CheckIfObjectIsAllowed(object: string): boolean
	return (AllowedObjects[object] ~= nil)
end

-- object must be in allowed objects and returns the string
local function GetObjectString(object: any): string
	local Type = EasyType(object)

	if Type == "string" then
		return object
	elseif Type == "Instance" and CheckIfObjectIsAllowed(EasyType(object, true)) then
		return EasyType(object, true)
	end
	return Type
end

-- Checks if a datatype is allowed
local function IsObjectAllowed(object: any): boolean
	local Type = EasyType(object)

	if Type == "string" then
		return CheckIfObjectIsAllowed(object)
	else
		return CheckIfObjectIsAllowed(Type)
	end
end

local function IsThreadLocked(thread: thread): boolean
	return (ActiveThreadCategories[thread] ~= nil)
end

local function BuildTaskTree(): {}
	local self = {}
	for Object, _ in AllowedObjects do
		self[Object] = {}
	end
	return self
end
-- ... = What should be cleaned if all then all
local function DoClean(self: InternalCategory, WhatShouldBeCleaned: { [number]: string })
	for _, SubCategory: string in WhatShouldBeCleaned do
		assert(
			CheckIfObjectIsAllowed(SubCategory),
			string.format("%s Attempt to index %s in Task map got nil", SERVICE_NAME, SubCategory)
		)

		for _, Object: any in self.TasksOnThread[SubCategory] do
			local SubSettings = AllowedObjects[SubCategory]
			local CloseMethod: "Method" | "Call" = SubSettings.MethodOrCall

			if CloseMethod == "Method" then
				xpcall(Object[SubSettings.FunctionName], function(Err: string)
					warn(
						string.format(
							"%s Error occured when trying to clean Subcategory %s as a method on %s\nReason: %s\nRemoving link from category to be Garbage collected",
							SERVICE_NAME,
							SubCategory,
							tostring(self.ThreadLock),
							Err
						)
					)
				end, Object)
			else
				xpcall(SubSettings.Library[SubSettings.FunctionName], function(Err: string)
					warn(
						string.format(
							"%s Error occured when trying to clean Subcategory %s as a function call on %s\nReason: %s\nRemoving link from category to be Garbage collected",
							SERVICE_NAME,
							SubCategory,
							tostring(self.ThreadLock),
							Err
						)
					)
				end, Object)
			end
		end
		-- Clear table of sub-category
		self.TasksOnThread[SubCategory] = {}
	end
end

-- Destroys the object
local function Destroy(self: InternalCategory): nil
	ActiveThreadCategories[self.ThreadLock] = nil
	(self.Insertion :: TramService.Tram<any>):DestroyLocal()

	setmetatable(self, nil)
	self = nil :: never
	return self :: never
end

----------------------------------------------------------------------------------------------

--					 		[[ MetaData (MetaTable) ]]

local CategoryServiceMetaData = {}

CategoryServiceMetaData.__index = CategoryServiceMetaData
CategoryServiceMetaData.ClassName = "Category"

-- Insert function
function CategoryServiceMetaData:Insert(...: any)
	local PackedObjects = { ... }

	for _, object: any in PackedObjects do
		if IsObjectAllowed(object) then
			local SubCategory: string = GetObjectString(object)
			table.insert(self.TasksOnThread[SubCategory], object)
			self.Insertion:Fire(SubCategory)
		else
			warn(
				string.format(
					"%s Attempt to add %s to category on: [[%s]].\nObject is not registered in AllowedObjects.\n skipping",
					SERVICE_NAME,
					EasyType(object),
					tostring(self.ThreadLock)
				)
			)
		end
	end
end

-- Returns the subcategory and its sub contents
function CategoryServiceMetaData:GetSubCategoryContents(SubCategory: SupportedTypes): { [number]: any }
	return self.TasksOnThread[SubCategory]
end

-- Cleans the given subcategories
function CategoryServiceMetaData:Clean(...: SupportedTypes)
	DoClean(self, { ... })
end

-- Cleans all categories but leaves the object still linked to the thread
function CategoryServiceMetaData:CleanAll()
	local All = {}
	for Object: string, _ in AllowedObjects :: { [string]: any } do
		table.insert(All, Object)
	end
	DoClean(self, All)
end

-- Cleans then removes object from thread

--			[	You can only close a category on the same thread it is binded too	]
function CategoryServiceMetaData:FreeCurrentThread(): nil
	--[[assert(
		self.ThreadLock == coroutine.running(),
		string.format(
			"%s Attempt to free thread %s from %s. (Threads must be freed by the same thread they are assigned to)",
			SERVICE_NAME,
			tostring(self.ThreadLock),
			tostring(coroutine.running())
		)
	)]]
	self:CleanAll()
	return Destroy(self :: InternalCategory)
end

----------------------------------------------------------------------------------------------

--					 		[[ Public Service (mostly constructors) ]]

local CategoryService = {}

-- Creates a new empty category assigned to the current thread
-- You can call GetCategoryOnCurrentThread if you need to retreive or create a linked copy of the category object on the current thread
function CategoryService.NewCategory(): Category
	assert(
		not IsThreadLocked(coroutine.running()),
		string.format(
			"\n%s Attempt to assign: [[%s]] while it is already assigned to a category.\n(There can only be 1 category per thread)",
			SERVICE_NAME,
			tostring(coroutine.running())
		)
	)

	local self = setmetatable({}, CategoryServiceMetaData) :: any
	self.TasksOnThread = BuildTaskTree()
	self.ThreadLock = coroutine.running()

	self.Insertion  = TramService.NewTram(nil, nil, nil, true)

	ActiveThreadCategories[coroutine.running()] = self
	return self
end

-- Returns the category linked to the current thread
function CategoryService:GetCategoryOnCurrentThread(): Category?
	return ActiveThreadCategories[coroutine.running()]
end

-- Closes the category on the current thread
function CategoryService:CloseCategoryOnCurrentThread(): ()
	local CurrentCategory: Category? = self:GetCategoryOnCurrentThread()
	if CurrentCategory then
		CurrentCategory:FreeCurrentThread()
	end
end

return CategoryService
